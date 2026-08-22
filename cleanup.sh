#!/usr/bin/env bash
# Review repository-owned links in current and legacy agent skill directories.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
SKILLS_ROOT="$REPO_ROOT/skills"

AGENT_SKILLS_DIR="${AGENT_SKILLS_DIR:-$HOME/.agents/skills}"
CLAUDE_SKILLS_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
OPENCODE_BASE_DIR="${OPENCODE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode}"
OPENCODE_SKILLS_DIR="$OPENCODE_BASE_DIR/skills"
LEGACY_CODEX_SKILLS_DIR="${CODEX_HOME:-$HOME/.codex}/skills"

is_truthy() {
    case "${1:-}" in
        1 | true | TRUE | True | yes | YES | Yes) return 0 ;;
        *) return 1 ;;
    esac
}

opencode_kind="legacy"
if is_truthy "${OPENCODE_DISABLE_EXTERNAL_SKILLS:-}"; then
    opencode_kind="current"
fi

target_names=("Agent Skills" "Claude Code" "OpenCode native" "Legacy Codex")
target_dirs=("$AGENT_SKILLS_DIR" "$CLAUDE_SKILLS_DIR" "$OPENCODE_SKILLS_DIR" "$LEGACY_CODEX_SKILLS_DIR")
target_kinds=("current" "current" "$opencode_kind" "legacy")
seen_dirs=()

removed=0
kept=0
clean=0

already_seen() {
    local candidate="$1"
    local seen
    for seen in "${seen_dirs[@]-}"; do
        [[ -n "$seen" && "$seen" == "$candidate" ]] && return 0
    done
    return 1
}

prompt_remove() {
    local link="$1"
    local prompt="$2"
    local ans

    read -rp "  $prompt [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        rm "$link"
        echo "  Removed."
        removed=$((removed + 1))
    else
        echo "  Kept."
        kept=$((kept + 1))
    fi
}

review_target() {
    local tool_name="$1"
    local target_dir="$2"
    local target_kind="$3"
    local link target normalized_target skill_name state

    if already_seen "$target_dir"; then
        return
    fi
    seen_dirs+=("$target_dir")

    echo "=== $tool_name: $target_dir ==="
    if [[ ! -d "$target_dir" ]]; then
        echo "  skipped: directory does not exist"
        echo ""
        return
    fi

    for link in "$target_dir"/*; do
        [[ -L "$link" ]] || continue

        target="$(readlink "$link")"
        normalized_target="${target%/}"
        skill_name="$(basename "$link")"

        [[ "$normalized_target" == "$REPO_ROOT"/* ]] || continue

        state="clean"
        [[ ! -e "$link" ]] && state="broken"
        [[ "$normalized_target" == "$SKILLS_ROOT/deprecated"/* ]] && state="deprecated"
        [[ "$target_kind" == "legacy" ]] && state="legacy"

        case "$state" in
            legacy)
                echo "LEGACY: $skill_name"
                echo "  -> $target"
                [[ ! -e "$link" ]] && echo "  note: target no longer exists"
                prompt_remove "$link" "Remove legacy repository link?"
                echo ""
                ;;
            broken)
                echo "BROKEN: $skill_name"
                echo "  -> $target (target no longer exists)"
                prompt_remove "$link" "Remove broken repository link?"
                echo ""
                ;;
            deprecated)
                echo "DEPRECATED: $skill_name"
                echo "  -> $target"
                prompt_remove "$link" "Remove deprecated repository link?"
                echo ""
                ;;
            clean)
                clean=$((clean + 1))
                ;;
        esac
    done
    echo ""
}

for index in 0 1 2 3; do
    review_target "${target_names[$index]}" "${target_dirs[$index]}" "${target_kinds[$index]}"
done

echo "Done. Removed: $removed  Kept: $kept  Clean: $clean"
