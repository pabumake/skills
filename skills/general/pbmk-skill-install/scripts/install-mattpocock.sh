#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

SKILLS_CLI_VERSION="latest"
UPSTREAM_URL="https://github.com/mattpocock/skills"
BASELINE_FILE="$SCRIPT_DIR/mattpocock-baseline.txt"
RETIRED_FILE="$SCRIPT_DIR/mattpocock-retired.txt"

BASELINE_SKILLS=()
while IFS= read -r skill_name; do
    [[ -z "$skill_name" || "$skill_name" == \#* ]] && continue
    if [[ ! "$skill_name" =~ ^[a-z0-9-]+$ ]]; then
        echo "external preflight error: invalid skill name in $BASELINE_FILE: $skill_name" >&2
        exit 1
    fi
    BASELINE_SKILLS+=("$skill_name")
done <"$BASELINE_FILE"

if [[ ${#BASELINE_SKILLS[@]} -eq 0 ]]; then
    echo "external preflight error: baseline allowlist is empty" >&2
    exit 1
fi

RETIRED_SKILLS=()
if [[ -f "$RETIRED_FILE" ]]; then
    while IFS= read -r skill_name; do
        [[ -z "$skill_name" || "$skill_name" == \#* ]] && continue
        if [[ ! "$skill_name" =~ ^[a-z0-9-]+$ ]]; then
            echo "external preflight error: invalid retired skill name in $RETIRED_FILE: $skill_name" >&2
            exit 1
        fi
        RETIRED_SKILLS+=("$skill_name")
    done <"$RETIRED_FILE"
fi

if [[ $# -eq 0 ]]; then
    echo "skipped: Matt Pocock baseline (no supported agent targets)"
    exit 0
fi

if ! command -v node >/dev/null 2>&1; then
    echo "external preflight error: Node.js 22.20 or newer is required" >&2
    exit 1
fi
if ! command -v npx >/dev/null 2>&1; then
    echo "external preflight error: npx is required" >&2
    exit 1
fi
if ! node -e 'const [major, minor] = process.versions.node.split(".").map(Number); process.exit(major > 22 || (major === 22 && minor >= 20) ? 0 : 1)'; then
    echo "external preflight error: Node.js 22.20 or newer is required" >&2
    exit 1
fi

AGENT_SKILLS_DIR="${AGENT_SKILLS_DIR:-$HOME/.agents/skills}"
# The upstream CLI always installs universal skills here; it does not honor
# AGENT_SKILLS_DIR or OPENCODE_CONFIG_DIR. Link our alternate destinations below.
CANONICAL_SKILLS_DIR="$HOME/.agents/skills"
CLAUDE_SKILLS_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
OPENCODE_BASE_DIR="${OPENCODE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode}"
OPENCODE_SKILLS_DIR="$OPENCODE_BASE_DIR/skills"

if [[ -n "${XDG_STATE_HOME:-}" ]]; then
    GLOBAL_SKILL_LOCK="$XDG_STATE_HOME/skills/.skill-lock.json"
else
    GLOBAL_SKILL_LOCK="$HOME/.agents/.skill-lock.json"
fi

managed_skills=()
updateable_skills=()
foreign_locked_skills=()
if [[ -f "$GLOBAL_SKILL_LOCK" ]]; then
    if ! managed_output="$(node - "$GLOBAL_SKILL_LOCK" <<'NODE'
const fs = require('fs');
const lock = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
for (const [name, entry] of Object.entries(lock.skills || {})) {
  if (entry && entry.source === 'mattpocock/skills') {
    console.log(`${entry.skillFolderHash && entry.skillPath && !entry.ref ? 'update' : 'add'} ${name}`);
  } else {
    console.log(`foreign ${name}`);
  }
}
NODE
    )"; then
        echo "external preflight error: could not read global skill lock $GLOBAL_SKILL_LOCK" >&2
        exit 1
    fi
    while read -r action managed_name; do
        [[ -z "${managed_name:-}" ]] && continue
        if [[ "$action" == "foreign" ]]; then
            foreign_locked_skills+=("$managed_name")
        else
            managed_skills+=("$managed_name")
            [[ "$action" == "update" ]] && updateable_skills+=("$managed_name")
        fi
    done <<<"$managed_output"
fi

is_managed_skill() {
    local requested="$1"
    local managed

    for managed in "${managed_skills[@]-}"; do
        [[ -n "$managed" && "$managed" == "$requested" ]] && return 0
    done
    return 1
}

is_updateable_skill() {
    local requested="$1"
    local updateable

    for updateable in "${updateable_skills[@]-}"; do
        [[ -n "$updateable" && "$updateable" == "$requested" ]] && return 0
    done
    return 1
}

is_truthy() {
    case "${1:-}" in
        1 | true | TRUE | True | yes | YES | Yes) return 0 ;;
        *) return 1 ;;
    esac
}

target_dirs=("$CANONICAL_SKILLS_DIR")
link_dirs=()
add_target_dir() {
    local requested="$1"
    local existing

    for existing in "${target_dirs[@]-}"; do
        [[ -n "$existing" && "$existing" == "$requested" ]] && return
    done
    target_dirs+=("$requested")
}

if [[ "$AGENT_SKILLS_DIR" != "$CANONICAL_SKILLS_DIR" ]]; then
    add_target_dir "$AGENT_SKILLS_DIR"
    link_dirs+=("$AGENT_SKILLS_DIR")
fi
for agent in "$@"; do
    case "$agent" in
        claude-code) add_target_dir "$CLAUDE_SKILLS_DIR" ;;
        opencode)
            if is_truthy "${OPENCODE_DISABLE_EXTERNAL_SKILLS:-}" || \
                [[ "$AGENT_SKILLS_DIR" != "$HOME/.agents/skills" ]]; then
                add_target_dir "$OPENCODE_SKILLS_DIR"
                link_dirs+=("$OPENCODE_SKILLS_DIR")
            fi
            ;;
    esac
done

# Alias destinations must be absent or already point to the canonical skill.
# A lock entry identifies the upstream skill, not an unrelated local copy.
for target_dir in "${link_dirs[@]-}"; do
    [[ -n "$target_dir" ]] || continue
    for skill_name in "${BASELINE_SKILLS[@]}"; do
        destination="$target_dir/$skill_name"
        if [[ -e "$destination" || -L "$destination" ]]; then
            if ! node - "$destination" "$CANONICAL_SKILLS_DIR/$skill_name" <<'NODE'
const fs = require('fs');
const path = require('path');
const [link, target] = process.argv.slice(2);
let matches = false;
try {
  matches = fs.realpathSync(link) === fs.realpathSync(target);
} catch {
  try { matches = path.resolve(path.dirname(link), fs.readlinkSync(link)) === path.resolve(target); } catch {}
}
process.exit(matches ? 0 : 1);
NODE
            then
                echo "external preflight error: foreign conflict at alternate skill path: $destination" >&2
                exit 1
            fi
        fi
    done
done

preflight_errors=0
for skill_name in "${BASELINE_SKILLS[@]}"; do
    for foreign_name in "${foreign_locked_skills[@]-}"; do
        if [[ "$skill_name" == "$foreign_name" ]]; then
            echo "external preflight error: foreign lock entry for $skill_name" >&2
            preflight_errors=$((preflight_errors + 1))
        fi
    done
done
for target_dir in "${target_dirs[@]}"; do
    for skill_name in "${BASELINE_SKILLS[@]}"; do
        destination="$target_dir/$skill_name"
        if [[ -e "$destination" || -L "$destination" ]]; then
            if ! is_managed_skill "$skill_name"; then
                echo "external preflight error: foreign conflict at $destination" >&2
                preflight_errors=$((preflight_errors + 1))
            fi
        fi
    done
done

if [[ $preflight_errors -ne 0 ]]; then
    echo "External preflight failed with $preflight_errors conflict(s); no upstream skills were changed." >&2
    exit 1
fi

for retired_name in "${RETIRED_SKILLS[@]-}"; do
    for skill_name in "${BASELINE_SKILLS[@]}"; do
        if [[ -n "$retired_name" && "$retired_name" == "$skill_name" ]]; then
            echo "external preflight error: $skill_name is both selected and retired" >&2
            exit 1
        fi
    done
done

echo ""
echo "Refreshing Matt Pocock baseline"
echo "  source: $UPSTREAM_URL"
echo "  skills CLI: $SKILLS_CLI_VERSION"
echo "  selected: ${#BASELINE_SKILLS[@]} skill(s)"
echo "  agents: $*"

add_skills=()
update_skills=()
for skill_name in "${BASELINE_SKILLS[@]}"; do
    needs_add=false
    if ! is_updateable_skill "$skill_name"; then
        needs_add=true
    else
        for target_dir in "${target_dirs[@]}"; do
            if [[ ! -f "$target_dir/$skill_name/SKILL.md" ]]; then
                needs_add=true
                break
            fi
        done
    fi
    if $needs_add; then
        add_skills+=("$skill_name")
    else
        update_skills+=("$skill_name")
    fi
done

if [[ ${#update_skills[@]} -gt 0 ]]; then
    echo "  checking ${#update_skills[@]} installed skill(s) for changes"
    update_output="$(npx --yes "skills@$SKILLS_CLI_VERSION" update \
        --global --yes "${update_skills[@]}" 2>&1)" || {
        echo "$update_output" >&2
        exit 1
    }
    echo "$update_output"
    # The CLI can return success after a failed remote check. Do not report a
    # successful refresh when it could not determine whether skills changed.
    if [[ "$update_output" == *"Failed to check skills from"* \
        || "$update_output" == *"Failed to update"* \
        || "$update_output" == *"cannot be checked automatically"* ]]; then
        echo "external validation error: update check was incomplete" >&2
        exit 1
    fi
fi

if [[ ${#add_skills[@]} -gt 0 ]]; then
    echo "  installing or repairing ${#add_skills[@]} skill(s)"
    skill_args=()
    for skill_name in "${add_skills[@]}"; do
        skill_args+=(--skill "$skill_name")
    done
    npx --yes "skills@$SKILLS_CLI_VERSION" add "$UPSTREAM_URL" \
        "${skill_args[@]}" \
        --agent "$@" \
        --global \
        --yes
fi

for target_dir in "${link_dirs[@]-}"; do
    [[ -n "$target_dir" ]] || continue
    mkdir -p "$target_dir"
    for skill_name in "${BASELINE_SKILLS[@]}"; do
        destination="$target_dir/$skill_name"
        if [[ ! -e "$destination" && ! -L "$destination" ]]; then
            ln -s "$CANONICAL_SKILLS_DIR/$skill_name" "$destination"
        fi
    done
done

for retired_name in "${RETIRED_SKILLS[@]-}"; do
    [[ -n "$retired_name" ]] || continue
    if is_managed_skill "$retired_name"; then
        echo "  removing retired skill: $retired_name"
        npx --yes "skills@$SKILLS_CLI_VERSION" remove \
            --global --yes "$retired_name"
        for target_dir in "${link_dirs[@]-}"; do
            [[ -n "$target_dir" ]] || continue
            destination="$target_dir/$retired_name"
            if [[ -L "$destination" && "$(readlink "$destination")" == "$CANONICAL_SKILLS_DIR/$retired_name" ]]; then
                rm "$destination"
            fi
        done
        if node - "$GLOBAL_SKILL_LOCK" "$retired_name" <<'NODE'
const fs = require('fs');
const lock = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
process.exit(lock.skills?.[process.argv[3]] ? 1 : 0);
NODE
        then
            :
        else
            echo "external validation error: retired skill remains in global lock: $retired_name" >&2
            exit 1
        fi
        for target_dir in "${target_dirs[@]}"; do
            if [[ -e "$target_dir/$retired_name" || -L "$target_dir/$retired_name" ]]; then
                echo "external validation error: retired skill remains at $target_dir/$retired_name" >&2
                exit 1
            fi
        done
    fi
done

node "$SCRIPT_DIR/validate-mattpocock-install.mjs" \
    "$GLOBAL_SKILL_LOCK" \
    "" \
    "${target_dirs[@]}" \
    -- \
    "${BASELINE_SKILLS[@]}"

echo "External baseline validated."
