#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

SKILLS_CLI_VERSION="1.5.25"
UPSTREAM_REF="3cca18b368ae95cdbdebbff572ccafa662551015"
UPSTREAM_URL="https://github.com/mattpocock/skills/tree/$UPSTREAM_REF"
BASELINE_FILE="$SCRIPT_DIR/mattpocock-baseline.txt"

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
CLAUDE_SKILLS_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
OPENCODE_BASE_DIR="${OPENCODE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode}"
OPENCODE_SKILLS_DIR="$OPENCODE_BASE_DIR/skills"

if [[ -n "${XDG_STATE_HOME:-}" ]]; then
    GLOBAL_SKILL_LOCK="$XDG_STATE_HOME/skills/.skill-lock.json"
else
    GLOBAL_SKILL_LOCK="$(dirname "$AGENT_SKILLS_DIR")/.skill-lock.json"
fi

managed_skills=()
if [[ -f "$GLOBAL_SKILL_LOCK" ]]; then
    if ! managed_output="$(node - "$GLOBAL_SKILL_LOCK" <<'NODE'
const fs = require('fs');
const lock = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
for (const [name, entry] of Object.entries(lock.skills || {})) {
  if (entry && entry.source === 'mattpocock/skills') console.log(name);
}
NODE
    )"; then
        echo "external preflight error: could not read global skill lock $GLOBAL_SKILL_LOCK" >&2
        exit 1
    fi
    while IFS= read -r managed_name; do
        [[ -n "$managed_name" ]] && managed_skills+=("$managed_name")
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

is_truthy() {
    case "${1:-}" in
        1 | true | TRUE | True | yes | YES | Yes) return 0 ;;
        *) return 1 ;;
    esac
}

target_dirs=("$AGENT_SKILLS_DIR")
add_target_dir() {
    local requested="$1"
    local existing

    for existing in "${target_dirs[@]-}"; do
        [[ -n "$existing" && "$existing" == "$requested" ]] && return
    done
    target_dirs+=("$requested")
}

for agent in "$@"; do
    case "$agent" in
        claude-code) add_target_dir "$CLAUDE_SKILLS_DIR" ;;
        opencode)
            if is_truthy "${OPENCODE_DISABLE_EXTERNAL_SKILLS:-}"; then
                add_target_dir "$OPENCODE_SKILLS_DIR"
            fi
            ;;
    esac
done

preflight_errors=0
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

echo ""
echo "Installing Matt Pocock baseline"
echo "  source: $UPSTREAM_URL"
echo "  skills CLI: $SKILLS_CLI_VERSION"
echo "  selected: ${#BASELINE_SKILLS[@]} skill(s)"
echo "  agents: $*"

skill_args=()
for skill_name in "${BASELINE_SKILLS[@]}"; do
    skill_args+=(--skill "$skill_name")
done

npx --yes "skills@$SKILLS_CLI_VERSION" add "$UPSTREAM_URL" \
    "${skill_args[@]}" \
    --agent "$@" \
    --global \
    --yes

node "$SCRIPT_DIR/validate-mattpocock-install.mjs" \
    "$GLOBAL_SKILL_LOCK" \
    "$UPSTREAM_REF" \
    "${target_dirs[@]}" \
    -- \
    "${BASELINE_SKILLS[@]}"

echo "External baseline installed at $UPSTREAM_REF."
