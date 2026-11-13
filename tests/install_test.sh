#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Keep tool discovery and every default destination out of the developer's home.
SUITE_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/pbmk-skills-suite.XXXXXX")"
trap 'rm -rf "$SUITE_ROOT"' EXIT
mkdir -p "$SUITE_ROOT/bin" "$SUITE_ROOT/home"
for tool in node python3 rg; do
    ln -s "$(command -v "$tool")" "$SUITE_ROOT/bin/$tool"
done
export HOME="$SUITE_ROOT/home"
export PATH="$SUITE_ROOT/bin:/usr/bin:/bin"
export TMPDIR="$SUITE_ROOT/"
unset HERMES_HOME OPENCODE_DISABLE_EXTERNAL_SKILLS
EXPECTED_SKILLS=(
    setup-matt-pocock-skills
    ask-matt
    grill-with-docs
    triage
    to-spec
    to-tickets
    implement
    implement-spec
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
    pr
    retro
    wizard
    grill-me
    handoff
    teach
    to-questionnaire
    wait-what
    writing-for-agents
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
action="$3"
for arg in "${@:4}"; do
    if [[ "$arg" == "--skill" ]]; then
        reading_skills=true
    elif [[ "$arg" == --* ]]; then
        reading_skills=false
    elif [[ "$action" == "update" || "$action" == "remove" || "$reading_skills" == true ]]; then
        skills+=("$arg")
    fi
done

if [[ "$action" == "remove" ]]; then
    node - "$XDG_STATE_HOME/skills/.skill-lock.json" "$HOME/.agents/skills" "$CLAUDE_CONFIG_DIR/skills" "${skills[@]}" <<'NODE'
const fs = require('fs');
const [lockPath, agentsDir, claudeDir, ...names] = process.argv.slice(2);
const lock = JSON.parse(fs.readFileSync(lockPath, 'utf8'));
for (const name of names) {
  delete lock.skills[name];
  fs.rmSync(`${agentsDir}/${name}`, { recursive: true, force: true });
  fs.rmSync(`${claudeDir}/${name}`, { recursive: true, force: true });
}
fs.writeFileSync(lockPath, JSON.stringify(lock));
NODE
    exit 0
fi

if [[ "$action" == "update" ]]; then
    if [[ -n "${FAKE_NPX_UPDATE_ERROR:-}" ]]; then
        echo "Failed to check skills from mattpocock/skills"
    elif [[ -n "${FAKE_NPX_CHANGED_SKILL:-}" ]]; then
        printf 'updated\n' >>"$AGENT_SKILLS_DIR/$FAKE_NPX_CHANGED_SKILL/SKILL.md"
        echo "Found 1 global update(s)"
        echo "Updated $FAKE_NPX_CHANGED_SKILL"
    else
        echo "All global skills are up to date"
    fi
    exit 0
fi

for skill in "${skills[@]}"; do
    if [[ -L "$HOME/.agents/skills/$skill" ]]; then
        echo "fake npx refused a leftover symlink at $HOME/.agents/skills/$skill" >&2
        exit 41
    fi
    mkdir -p "$HOME/.agents/skills/$skill" "$CLAUDE_CONFIG_DIR/skills/$skill"
    printf -- '---\nname: %s\n---\n' "$skill" >"$HOME/.agents/skills/$skill/SKILL.md"
    printf -- '---\nname: %s\n---\n' "$skill" >"$CLAUDE_CONFIG_DIR/skills/$skill/SKILL.md"
done

mkdir -p "$XDG_STATE_HOME/skills"
node - "$XDG_STATE_HOME/skills/.skill-lock.json" "${skills[@]}" <<'NODE'
const fs = require('fs');
const lockPath = process.argv[2];
const lock = fs.existsSync(lockPath) ? JSON.parse(fs.readFileSync(lockPath, 'utf8')) : { version: 3, skills: {} };
for (const name of process.argv.slice(3)) {
  lock.skills[name] = {
    source: 'mattpocock/skills',
    skillFolderHash: 'hash',
    skillPath: `skills/engineering/${name}/SKILL.md`,
  };
}
fs.writeFileSync(lockPath, JSON.stringify(lock));
NODE
EOF
    chmod +x "$path"
}

test_root_installer_adds_selected_baseline() {
    local test_root fake_bin output status args skill arg skill_flag_count

    test_root="$(mktemp -d "${TMPDIR}pbmk-skills-install-test.XXXXXX")"
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
    [[ -f "$test_root/agents/skills/teach/SKILL.md" ]] || fail "teach was not installed for Codex"
    [[ -f "$test_root/claude/skills/teach/SKILL.md" ]] || fail "teach was not installed for Claude Code"

    echo "PASS: root installer adds all README-listed skills"
}

test_foreign_baseline_skill_is_preserved() {
    local test_root fake_bin output status

    test_root="$(mktemp -d "${TMPDIR}pbmk-skills-conflict-test.XXXXXX")"
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

test_foreign_lock_entry_is_preserved() {
    local test_root fake_bin output status

    test_root="$(mktemp -d "${TMPDIR}pbmk-skills-lock-conflict-test.XXXXXX")"
    trap 'rm -rf "$test_root"' RETURN
    fake_bin="$test_root/bin"
    mkdir -p "$fake_bin" "$test_root/state/skills"
    printf '{"skills":{"code-review":{"source":"someone-else/skills"}}}\n' >"$test_root/state/skills/.skill-lock.json"
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
        XDG_STATE_HOME="$test_root/state" \
        FAKE_NPX_CALLED="$test_root/npx.called" \
        "$REPO_ROOT/skills/general/pbmk-skill-install/scripts/install-mattpocock.sh" codex
    } 2>&1)"
    status=$?
    set -e

    [[ $status -ne 0 ]] || fail "installer replaced a foreign lock entry"
    [[ ! -e "$test_root/npx.called" ]] || fail "npx ran despite a foreign lock entry"
    assert_contains "$output" "foreign lock entry for code-review"
    echo "PASS: foreign lock entry is preserved"
}

test_external_failure_reports_partial_install() {
    local test_root fake_bin output status skill

    test_root="$(mktemp -d "${TMPDIR}pbmk-skills-failure-test.XXXXXX")"
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

    test_root="$(mktemp -d "${TMPDIR}pbmk-skills-validation-test.XXXXXX")"
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

    test_root="$(mktemp -d "${TMPDIR}pbmk-skills-migration-test.XXXXXX")"
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
    [[ "$(readlink "$test_root/agents/skills/code-review")" == "$HOME/.agents/skills/code-review" ]] || fail "retired agent link survived migration"
    [[ -f "$test_root/agents/skills/code-review/SKILL.md" ]] || fail "upstream replacement was not installed"

    echo "PASS: retired links are replaced before upstream installation"
}

test_repeated_install_skips_unchanged_upstream_skills() {
    local test_root fake_bin first_output second_output third_output status skill calls

    test_root="$(mktemp -d "${TMPDIR}pbmk-skills-repeat-test.XXXXXX")"
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
    [[ "$calls" == "2" ]] || fail "expected one add and one update check, got $calls"
    [[ "$(tail -n 1 "$test_root/npx.args")" == *"skills@latest update --global --yes"* ]] ||
        fail "repeat install did not check for updates"
    [[ "$(tail -n 1 "$test_root/npx.args")" != *" add "* ]] ||
        fail "repeat install reinstalled unchanged skills"
    for skill in "${EXPECTED_SKILLS[@]}"; do
        assert_contains "$(tail -n 1 "$test_root/npx.args")" "$skill"
    done
    assert_contains "$second_output" "All global skills are up to date"
    assert_contains "$second_output" "Validated ${#EXPECTED_SKILLS[@]} Matt Pocock skills"

    rm "$test_root/agents/skills/code-review/SKILL.md"
    third_output="$({
        PATH="$fake_bin:$PATH" \
        AGENT_SKILLS_DIR="$test_root/agents/skills" \
        CLAUDE_CONFIG_DIR="$test_root/claude" \
        OPENCODE_CONFIG_DIR="$test_root/opencode" \
        CODEX_HOME="$test_root/codex" \
        XDG_STATE_HOME="$test_root/state" \
        FAKE_NPX_LOG="$test_root/npx.args" \
        "$REPO_ROOT/install.sh"
    } 2>&1)" || fail "repair run failed: $third_output"
    [[ -f "$test_root/agents/skills/code-review/SKILL.md" ]] || fail "missing skill was not repaired"
    assert_contains "$third_output" "installing or repairing 1 skill(s)"
    [[ "$(tail -n 1 "$test_root/npx.args")" == *" add "* ]] || fail "repair did not run add"

    node - "$test_root/state/skills/.skill-lock.json" <<'NODE'
const fs = require('fs');
const file = process.argv[2];
const lock = JSON.parse(fs.readFileSync(file, 'utf8'));
lock.skills.wizard.ref = 'old-pinned-commit';
fs.writeFileSync(file, JSON.stringify(lock));
NODE
    third_output="$({
        PATH="$fake_bin:$PATH" \
        AGENT_SKILLS_DIR="$test_root/agents/skills" \
        CLAUDE_CONFIG_DIR="$test_root/claude" \
        OPENCODE_CONFIG_DIR="$test_root/opencode" \
        CODEX_HOME="$test_root/codex" \
        XDG_STATE_HOME="$test_root/state" \
        FAKE_NPX_LOG="$test_root/npx.args" \
        "$REPO_ROOT/install.sh"
    } 2>&1)" || fail "pinned-source migration failed: $third_output"
    assert_contains "$third_output" "installing or repairing 1 skill(s)"
    [[ "$(tail -n 1 "$test_root/npx.args")" == *"--skill wizard"* ]] ||
        fail "pinned skill was not refreshed from the current source"

    echo "PASS: repeated install skips unchanged upstream skills"
}

test_failed_update_check_is_reported() {
    local test_root fake_bin first_output second_output status skill

    test_root="$(mktemp -d "${TMPDIR}pbmk-skills-update-failure-test.XXXXXX")"
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
    } 2>&1)" || fail "setup install failed: $first_output"

    set +e
    second_output="$({
        PATH="$fake_bin:$PATH" \
        AGENT_SKILLS_DIR="$test_root/agents/skills" \
        CLAUDE_CONFIG_DIR="$test_root/claude" \
        OPENCODE_CONFIG_DIR="$test_root/opencode" \
        CODEX_HOME="$test_root/codex" \
        XDG_STATE_HOME="$test_root/state" \
        FAKE_NPX_LOG="$test_root/npx.args" \
        FAKE_NPX_UPDATE_ERROR=1 \
        "$REPO_ROOT/install.sh"
    } 2>&1)"
    status=$?
    set -e

    [[ $status -ne 0 ]] || fail "remote check failure was reported as success"
    assert_contains "$second_output" "update check was incomplete"
    echo "PASS: failed update check is reported"
}

test_retired_upstream_skill_is_removed_only_when_managed() {
    local test_root fake_bin output skill retired_name remove_calls

    test_root="$(mktemp -d "${TMPDIR}pbmk-skills-retired-test.XXXXXX")"
    trap 'rm -rf "$test_root"' RETURN
    fake_bin="$test_root/bin"
    retired_name="resolving-merge-conflicts"
    mkdir -p "$fake_bin"
    for skill in codex claude opencode; do
        printf '#!/usr/bin/env bash\nexit 0\n' >"$fake_bin/$skill"
        chmod +x "$fake_bin/$skill"
    done
    write_successful_npx_stub "$fake_bin/npx"

    output="$({
        PATH="$fake_bin:$PATH" \
        AGENT_SKILLS_DIR="$test_root/agents/skills" \
        CLAUDE_CONFIG_DIR="$test_root/claude" \
        XDG_STATE_HOME="$test_root/state" \
        FAKE_NPX_LOG="$test_root/npx.args" \
        "$REPO_ROOT/skills/general/pbmk-skill-install/scripts/install-mattpocock.sh" codex claude-code
    } 2>&1)" || fail "retired test setup failed: $output"

    node - "$test_root/state/skills/.skill-lock.json" "$retired_name" <<'NODE'
const fs = require('fs');
const file = process.argv[2];
const lock = JSON.parse(fs.readFileSync(file, 'utf8'));
lock.skills[process.argv[3]] = { source: 'mattpocock/skills' };
fs.writeFileSync(file, JSON.stringify(lock));
NODE
    mkdir -p "$HOME/.agents/skills/$retired_name" "$test_root/claude/skills/$retired_name"
    ln -s "$HOME/.agents/skills/$retired_name" "$test_root/agents/skills/$retired_name"

    output="$({
        PATH="$fake_bin:$PATH" \
        AGENT_SKILLS_DIR="$test_root/agents/skills" \
        CLAUDE_CONFIG_DIR="$test_root/claude" \
        XDG_STATE_HOME="$test_root/state" \
        FAKE_NPX_LOG="$test_root/npx.args" \
        "$REPO_ROOT/skills/general/pbmk-skill-install/scripts/install-mattpocock.sh" codex claude-code
    } 2>&1)" || fail "retired skill removal failed: $output"
    assert_contains "$output" "removing retired skill: $retired_name"
    [[ ! -e "$test_root/agents/skills/$retired_name" ]] || fail "retired managed skill remains installed"
    [[ "$(tail -n 1 "$test_root/npx.args")" == *"remove --global --yes $retired_name"* ]] ||
        fail "retired skill was not removed by name"

    node - "$test_root/state/skills/.skill-lock.json" "$retired_name" <<'NODE'
const fs = require('fs');
const file = process.argv[2];
const lock = JSON.parse(fs.readFileSync(file, 'utf8'));
lock.skills[process.argv[3]] = { source: 'someone-else/skills' };
fs.writeFileSync(file, JSON.stringify(lock));
NODE
    mkdir -p "$test_root/agents/skills/$retired_name"
    remove_calls="$(rg -c ' remove ' "$test_root/npx.args")"
    output="$({
        PATH="$fake_bin:$PATH" \
        AGENT_SKILLS_DIR="$test_root/agents/skills" \
        CLAUDE_CONFIG_DIR="$test_root/claude" \
        XDG_STATE_HOME="$test_root/state" \
        FAKE_NPX_LOG="$test_root/npx.args" \
        "$REPO_ROOT/skills/general/pbmk-skill-install/scripts/install-mattpocock.sh" codex claude-code
    } 2>&1)" || fail "foreign retired skill check failed: $output"
    [[ -d "$test_root/agents/skills/$retired_name" ]] || fail "foreign retired skill was removed"
    [[ "$(rg -c ' remove ' "$test_root/npx.args")" == "$remove_calls" ]] ||
        fail "foreign retired skill triggered removal"

    echo "PASS: retired upstream skill is removed only when managed"
}

test_relocation_adopts_documents_links() {
    local test_root fake_bin fake_home old_root output status tool

    test_root="$(mktemp -d "${TMPDIR}pbmk-skills-relocation-test.XXXXXX")"
    trap 'rm -rf "$test_root"' RETURN
    fake_bin="$test_root/bin"
    fake_home="$test_root/home"
    old_root="$fake_home/Documents/skills"
    mkdir -p "$fake_bin" "$fake_home/.agents/skills" "$fake_home/.claude/skills" \
        "$fake_home/.config/opencode/skills" "$fake_home/.codex/skills"

    ln -s "$old_root/skills/security/security-analysis" "$fake_home/.agents/skills/security-analysis"
    ln -s "$old_root/skills/security/security-analysis" "$fake_home/.claude/skills/security-analysis"
    ln -s "$old_root/skills/deprecated/retired-skill" "$fake_home/.agents/skills/retired-skill"
    ln -s "$old_root/skills/deprecated/retired-skill" "$fake_home/.config/opencode/skills/retired-skill"
    ln -s "$old_root/skills/deprecated/mattpocock-adaptations/code-review" "$fake_home/.codex/skills/code-review"
    ln -s "$test_root/foreign/untouched" "$fake_home/.agents/skills/foreign-skill"

    for tool in codex claude opencode; do
        printf '#!/usr/bin/env bash\nexit 0\n' >"$fake_bin/$tool"
        chmod +x "$fake_bin/$tool"
    done
    write_successful_npx_stub "$fake_bin/npx"

    set +e
    output="$({
        HOME="$fake_home" \
        PATH="$fake_bin:$PATH" \
        AGENT_SKILLS_DIR="$fake_home/.agents/skills" \
        CLAUDE_CONFIG_DIR="$fake_home/.claude" \
        OPENCODE_CONFIG_DIR="$fake_home/.config/opencode" \
        CODEX_HOME="$fake_home/.codex" \
        XDG_STATE_HOME="$test_root/state" \
        FAKE_NPX_LOG="$test_root/npx.args" \
        "$REPO_ROOT/install.sh"
    } 2>&1)"
    status=$?
    set -e

    [[ $status -eq 0 ]] || fail "relocation install failed: $output"
    [[ "$(readlink "$fake_home/.agents/skills/security-analysis")" == "$REPO_ROOT/skills/security/security-analysis" ]] ||
        fail "agent link still points to the Documents checkout"
    [[ "$(readlink "$fake_home/.claude/skills/security-analysis")" == "$REPO_ROOT/skills/security/security-analysis" ]] ||
        fail "Claude link still points to the Documents checkout"
    [[ ! -L "$fake_home/.agents/skills/retired-skill" ]] || fail "retired agent link survived"
    [[ ! -L "$fake_home/.config/opencode/skills/retired-skill" ]] || fail "legacy OpenCode link survived"
    [[ ! -L "$fake_home/.codex/skills/code-review" ]] || fail "legacy Codex link survived"
    [[ "$(readlink "$fake_home/.agents/skills/foreign-skill")" == "$test_root/foreign/untouched" ]] ||
        fail "foreign link was changed"
    assert_contains "$output" "Validated ${#EXPECTED_SKILLS[@]} Matt Pocock skills"

    echo "PASS: relocated installer adopts Documents links and preserves foreign links"
}

run_test() {
    local home
    home="$(mktemp -d "${TMPDIR}home.XXXXXX")"
    (export HOME="$home"; "$1")
    rm -rf "$home"
}

run_test test_root_installer_adds_selected_baseline
run_test test_foreign_baseline_skill_is_preserved
run_test test_foreign_lock_entry_is_preserved
run_test test_external_failure_reports_partial_install
run_test test_false_success_fails_post_install_validation
run_test test_retired_links_are_replaced_before_upstream_install
run_test test_repeated_install_skips_unchanged_upstream_skills
run_test test_failed_update_check_is_reported
run_test test_retired_upstream_skill_is_removed_only_when_managed
run_test test_relocation_adopts_documents_links
