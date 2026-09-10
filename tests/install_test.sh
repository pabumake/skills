#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXPECTED_SKILLS=(
    setup-matt-pocock-skills
    grill-with-docs
    triage
    to-spec
    to-tickets
    implement
    grilling
    domain-modeling
    tdd
    code-review
    codebase-design
    diagnosing-bugs
    prototype
    research
    improve-codebase-architecture
    wayfinder
    resolving-merge-conflicts
    wizard
)

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    [[ "$haystack" == *"$needle"* ]] || fail "expected command to contain: $needle"
}

write_successful_npx_stub() {
    local path="$1"

    cat >"$path" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$FAKE_NPX_LOG"

skills=()
reading_skills=false
upstream_ref=""
for arg in "$@"; do
    if [[ "$arg" == https://github.com/mattpocock/skills/tree/* ]]; then
        upstream_ref="${arg##*/}"
    elif [[ "$arg" == "--skill" ]]; then
        reading_skills=true
    elif [[ "$arg" == --* ]]; then
        reading_skills=false
    elif $reading_skills; then
        skills+=("$arg")
    fi
done

for skill in "${skills[@]}"; do
    if [[ -L "$AGENT_SKILLS_DIR/$skill" ]]; then
        echo "fake npx refused a leftover symlink at $AGENT_SKILLS_DIR/$skill" >&2
        exit 41
    fi
    mkdir -p "$AGENT_SKILLS_DIR/$skill" "$CLAUDE_CONFIG_DIR/skills/$skill"
    printf -- '---\nname: %s\n---\n' "$skill" >"$AGENT_SKILLS_DIR/$skill/SKILL.md"
    printf -- '---\nname: %s\n---\n' "$skill" >"$CLAUDE_CONFIG_DIR/skills/$skill/SKILL.md"
done

mkdir -p "$XDG_STATE_HOME/skills"
{
    printf '{\n  "version": 3,\n  "skills": {'
    separator=""
    for skill in "${skills[@]}"; do
        printf '%s\n    "%s": {"source": "mattpocock/skills", "ref": "%s"}' "$separator" "$skill" "$upstream_ref"
        separator=","
    done
    printf '\n  }\n}\n'
} >"$XDG_STATE_HOME/skills/.skill-lock.json"
EOF
    chmod +x "$path"
}

test_root_installer_invokes_pinned_baseline() {
    local test_root fake_bin output status args skill arg skill_flag_count

    test_root="$(mktemp -d /private/tmp/pbmk-skills-install-test.XXXXXX)"
    trap 'rm -rf "$test_root"' RETURN
    fake_bin="$test_root/bin"
    mkdir -p "$fake_bin"

    for skill in codex claude opencode; do
        printf '#!/usr/bin/env bash\nexit 0\n' >"$fake_bin/$skill"
        chmod +x "$fake_bin/$skill"
    done

    write_successful_npx_stub "$fake_bin/npx"

    set +e
    output="$({
        PATH="$fake_bin:$PATH" \
        AGENT_SKILLS_DIR="$test_root/agents/skills" \
        CLAUDE_CONFIG_DIR="$test_root/claude" \
        OPENCODE_CONFIG_DIR="$test_root/opencode" \
        CODEX_HOME="$test_root/codex" \
        XDG_STATE_HOME="$test_root/state" \
        FAKE_NPX_LOG="$test_root/npx.args" \
        "$REPO_ROOT/install.sh"
    } 2>&1)"
    status=$?
    set -e

    [[ $status -eq 0 ]] || fail "installer exited $status: $output"
    [[ -f "$test_root/npx.args" ]] || fail "root installer did not invoke npx"
    args="$(<"$test_root/npx.args")"

    assert_contains "$args" "--yes skills@latest add"
    assert_contains "$args" "https://github.com/mattpocock/skills"
    assert_contains "$args" "--skill"
    assert_contains "$args" "--agent codex claude-code opencode"
    assert_contains "$args" "--global --yes"
    [[ "$args" != *"--all"* ]] || fail "installer must not request the whole upstream repository"
    [[ "$args" != *"--skill="* ]] || fail "skill names must be separate arguments"

    skill_flag_count=0
    for arg in $args; do
        [[ "$arg" == "--skill" ]] && skill_flag_count=$((skill_flag_count + 1))
    done
    [[ $skill_flag_count -eq ${#EXPECTED_SKILLS[@]} ]] ||
        fail "expected one --skill flag per baseline entry, got $skill_flag_count"

    for skill in "${EXPECTED_SKILLS[@]}"; do
        assert_contains "$args" "$skill"
    done

    echo "PASS: root installer invokes the pinned baseline"
}

test_foreign_baseline_skill_is_preserved() {
    local test_root fake_bin output status

    test_root="$(mktemp -d /private/tmp/pbmk-skills-conflict-test.XXXXXX)"
    trap 'rm -rf "$test_root"' RETURN
    fake_bin="$test_root/bin"
    mkdir -p "$fake_bin" "$test_root/agents/skills/code-review"
    printf 'keep\n' >"$test_root/agents/skills/code-review/foreign.txt"

    cat >"$fake_bin/npx" <<'EOF'
#!/usr/bin/env bash
touch "$FAKE_NPX_CALLED"
exit 0
EOF
    chmod +x "$fake_bin/npx"

    set +e
    output="$({
        PATH="$fake_bin:$PATH" \
        AGENT_SKILLS_DIR="$test_root/agents/skills" \
        CLAUDE_CONFIG_DIR="$test_root/claude" \
        OPENCODE_CONFIG_DIR="$test_root/opencode" \
        XDG_STATE_HOME="$test_root/state" \
        FAKE_NPX_CALLED="$test_root/npx.called" \
        "$REPO_ROOT/skills/general/pbmk-skill-install/scripts/install-mattpocock.sh" codex
    } 2>&1)"
    status=$?
    set -e

    [[ $status -ne 0 ]] || fail "installer overwrote an untracked baseline skill"
    [[ ! -e "$test_root/npx.called" ]] || fail "npx ran despite a foreign skill conflict"
    [[ -f "$test_root/agents/skills/code-review/foreign.txt" ]] || fail "foreign skill content was removed"
    assert_contains "$output" "foreign conflict"

    echo "PASS: foreign baseline skill is preserved"
}

test_external_failure_reports_partial_install() {
    local test_root fake_bin output status skill

    test_root="$(mktemp -d /private/tmp/pbmk-skills-failure-test.XXXXXX)"
    trap 'rm -rf "$test_root"' RETURN
    fake_bin="$test_root/bin"
    mkdir -p "$fake_bin"

    for skill in codex claude opencode; do
        printf '#!/usr/bin/env bash\nexit 0\n' >"$fake_bin/$skill"
        chmod +x "$fake_bin/$skill"
    done
    printf '#!/usr/bin/env bash\nexit 23\n' >"$fake_bin/npx"
    chmod +x "$fake_bin/npx"

    set +e
    output="$({
        PATH="$fake_bin:$PATH" \
        AGENT_SKILLS_DIR="$test_root/agents/skills" \
        CLAUDE_CONFIG_DIR="$test_root/claude" \
        OPENCODE_CONFIG_DIR="$test_root/opencode" \
        CODEX_HOME="$test_root/codex" \
        XDG_STATE_HOME="$test_root/state" \
        "$REPO_ROOT/install.sh"
    } 2>&1)"
    status=$?
    set -e

    [[ $status -ne 0 ]] || fail "root installer hid the upstream failure"
    [[ -L "$test_root/agents/skills/pbmk-skill-install" ]] || fail "local installation did not complete before upstream failure"
    assert_contains "$output" "External baseline installation failed. Local skill changes remain applied."

    echo "PASS: upstream failure reports the partial local install"
}

test_false_success_fails_post_install_validation() {
    local test_root fake_bin output status

    test_root="$(mktemp -d /private/tmp/pbmk-skills-validation-test.XXXXXX)"
    trap 'rm -rf "$test_root"' RETURN
    fake_bin="$test_root/bin"
    mkdir -p "$fake_bin"
    printf '#!/usr/bin/env bash\nexit 0\n' >"$fake_bin/npx"
    chmod +x "$fake_bin/npx"

    set +e
    output="$({
        PATH="$fake_bin:$PATH" \
        AGENT_SKILLS_DIR="$test_root/agents/skills" \
        CLAUDE_CONFIG_DIR="$test_root/claude" \
        OPENCODE_CONFIG_DIR="$test_root/opencode" \
        XDG_STATE_HOME="$test_root/state" \
        "$REPO_ROOT/skills/general/pbmk-skill-install/scripts/install-mattpocock.sh" codex
    } 2>&1)"
    status=$?
    set -e

    [[ $status -ne 0 ]] || fail "installer trusted a zero exit without installed skills"
    assert_contains "$output" "external validation error"

    echo "PASS: false CLI success fails post-install validation"
}

test_retired_links_are_replaced_before_upstream_install() {
    local test_root fake_bin output status skill retired_skill

    test_root="$(mktemp -d /private/tmp/pbmk-skills-migration-test.XXXXXX)"
    trap 'rm -rf "$test_root"' RETURN
    fake_bin="$test_root/bin"
    retired_skill="$REPO_ROOT/skills/deprecated/mattpocock-adaptations/code-review"
    mkdir -p "$fake_bin" "$test_root/agents/skills" "$test_root/claude/skills"
    ln -s "$retired_skill" "$test_root/agents/skills/code-review"
    ln -s "$retired_skill" "$test_root/claude/skills/code-review"

    for skill in codex claude opencode; do
        printf '#!/usr/bin/env bash\nexit 0\n' >"$fake_bin/$skill"
        chmod +x "$fake_bin/$skill"
    done
    write_successful_npx_stub "$fake_bin/npx"

    set +e
    output="$({
        PATH="$fake_bin:$PATH" \
        AGENT_SKILLS_DIR="$test_root/agents/skills" \
        CLAUDE_CONFIG_DIR="$test_root/claude" \
        OPENCODE_CONFIG_DIR="$test_root/opencode" \
        CODEX_HOME="$test_root/codex" \
        XDG_STATE_HOME="$test_root/state" \
        FAKE_NPX_LOG="$test_root/npx.args" \
        "$REPO_ROOT/install.sh"
    } 2>&1)"
    status=$?
    set -e

    [[ $status -eq 0 ]] || fail "retired-link migration failed: $output"
    assert_contains "$output" "removed stale: Agent Skills/code-review"
    assert_contains "$output" "removed stale: Claude Code/code-review"
    [[ ! -L "$test_root/agents/skills/code-review" ]] || fail "retired agent link survived migration"
    [[ -f "$test_root/agents/skills/code-review/SKILL.md" ]] || fail "upstream replacement was not installed"

    echo "PASS: retired links are replaced before upstream installation"
}

test_repeated_install_accepts_managed_upstream_skills() {
    local test_root fake_bin first_output second_output status skill calls

    test_root="$(mktemp -d /private/tmp/pbmk-skills-repeat-test.XXXXXX)"
    trap 'rm -rf "$test_root"' RETURN
    fake_bin="$test_root/bin"
    mkdir -p "$fake_bin"

    for skill in codex claude opencode; do
        printf '#!/usr/bin/env bash\nexit 0\n' >"$fake_bin/$skill"
        chmod +x "$fake_bin/$skill"
    done
    write_successful_npx_stub "$fake_bin/npx"

    first_output="$({
        PATH="$fake_bin:$PATH" \
        AGENT_SKILLS_DIR="$test_root/agents/skills" \
        CLAUDE_CONFIG_DIR="$test_root/claude" \
        OPENCODE_CONFIG_DIR="$test_root/opencode" \
        CODEX_HOME="$test_root/codex" \
        XDG_STATE_HOME="$test_root/state" \
        FAKE_NPX_LOG="$test_root/npx.args" \
        "$REPO_ROOT/install.sh"
    } 2>&1)" || fail "first repeated-install run failed: $first_output"

    set +e
    second_output="$({
        PATH="$fake_bin:$PATH" \
        AGENT_SKILLS_DIR="$test_root/agents/skills" \
        CLAUDE_CONFIG_DIR="$test_root/claude" \
        OPENCODE_CONFIG_DIR="$test_root/opencode" \
        CODEX_HOME="$test_root/codex" \
        XDG_STATE_HOME="$test_root/state" \
        FAKE_NPX_LOG="$test_root/npx.args" \
        "$REPO_ROOT/install.sh"
    } 2>&1)"
    status=$?
    set -e

    [[ $status -eq 0 ]] || fail "second repeated-install run failed: $second_output"
    calls="$(wc -l <"$test_root/npx.args" | tr -d ' ')"
    [[ "$calls" == "2" ]] || fail "expected two upstream refreshes, got $calls"
    assert_contains "$second_output" "Validated 18 Matt Pocock skills"

    echo "PASS: repeated install accepts managed upstream skills"
}

test_root_installer_invokes_pinned_baseline
test_foreign_baseline_skill_is_preserved
test_external_failure_reports_partial_install
test_false_success_fails_post_install_validation
test_retired_links_are_replaced_before_upstream_install
test_repeated_install_accepts_managed_upstream_skills
