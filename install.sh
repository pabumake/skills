#!/usr/bin/env bash
# Link promoted skills from this repo into each detected agent's skill directory.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
SKILLS_ROOT="$REPO_ROOT/skills"

AGENT_SKILLS_DIR="${AGENT_SKILLS_DIR:-$HOME/.agents/skills}"
CLAUDE_SKILLS_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
OPENCODE_BASE_DIR="${OPENCODE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode}"
OPENCODE_SKILLS_DIR="$OPENCODE_BASE_DIR/skills"

skill_dirs=()
skill_names=()
skill_paths=()
preflight_errors=0

is_truthy() {
    case "${1:-}" in
        1 | true | TRUE | True | yes | YES | Yes) return 0 ;;
        *) return 1 ;;
    esac
}

while IFS= read -r skill_md; do
    skill_dir="$(dirname "$skill_md")"
    relative_path="${skill_dir#"$SKILLS_ROOT"/}"
    category="${relative_path%%/*}"

    [[ "$category" == "in-progress" || "$category" == "deprecated" ]] && continue

    skill_name="$(basename "$skill_dir")"
    declared_name="$(sed -n 's/^name:[[:space:]]*//p' "$skill_md" | head -n 1)"
    declared_name="${declared_name#\"}"
    declared_name="${declared_name%\"}"
    declared_name="${declared_name#\'}"
    declared_name="${declared_name%\'}"

    if [[ -z "$declared_name" ]]; then
        echo "preflight error: $skill_md has no simple name field" >&2
        preflight_errors=$((preflight_errors + 1))
        continue
    fi
    if [[ "$declared_name" != "$skill_name" ]]; then
        echo "preflight error: $skill_md declares '$declared_name' but its directory is '$skill_name'" >&2
        preflight_errors=$((preflight_errors + 1))
        continue
    fi

    duplicate=false
    for existing_name in "${skill_names[@]-}"; do
        if [[ -n "$existing_name" && "$existing_name" == "$skill_name" ]]; then
            echo "preflight error: duplicate promoted skill name '$skill_name'" >&2
            preflight_errors=$((preflight_errors + 1))
            duplicate=true
            break
        fi
    done
    $duplicate && continue

    skill_dirs+=("$skill_dir")
    skill_names+=("$skill_name")
    skill_paths+=("$relative_path")
done < <(find "$SKILLS_ROOT" -type f -name SKILL.md -print | sort)

if [[ $preflight_errors -ne 0 ]]; then
    echo "Preflight failed with $preflight_errors error(s); no links were changed." >&2
    exit 1
fi
if [[ ${#skill_dirs[@]} -eq 0 ]]; then
    echo "No promoted skills found under $SKILLS_ROOT" >&2
    exit 1
fi

linked=0
updated=0
unchanged=0
conflicts=0
migrated=0
removed_stale=0
migration_dirs=()

promoted_skill_dir() {
    local requested_name="$1"
    local index

    for index in "${!skill_names[@]}"; do
        if [[ "${skill_names[$index]}" == "$requested_name" ]]; then
            printf '%s\n' "${skill_dirs[$index]}"
            return 0
        fi
    done
    return 1
}

migration_dir_seen() {
    local candidate="$1"
    local seen

    for seen in "${migration_dirs[@]-}"; do
        [[ -n "$seen" && "$seen" == "$candidate" ]] && return 0
    done
    return 1
}

migrate_repo_links() {
    local target_name="$1"
    local target_dir="$2"
    local target_kind="$3"
    local link current_target normalized_target skill_name expected_target

    migration_dir_seen "$target_dir" && return
    migration_dirs+=("$target_dir")

    if [[ ! -d "$target_dir" ]]; then
        return 0
    fi

    for link in "$target_dir"/*; do
        [[ -L "$link" ]] || continue

        current_target="$(readlink "$link")"
        normalized_target="${current_target%/}"
        [[ "$normalized_target" == "$REPO_ROOT"/* ]] || continue

        skill_name="$(basename "$link")"
        if [[ "$target_kind" == "legacy" ]]; then
            rm "$link"
            echo "  removed legacy: $target_name/$skill_name -> $current_target"
            removed_stale=$((removed_stale + 1))
            continue
        fi

        if expected_target="$(promoted_skill_dir "$skill_name")"; then
            if [[ "$normalized_target" != "${expected_target%/}" ]]; then
                ln -sfn "$expected_target" "$link"
                echo "  migrated: $target_name/$skill_name -> ${expected_target#"$SKILLS_ROOT"/}"
                migrated=$((migrated + 1))
            fi
        else
            rm "$link"
            echo "  removed stale: $target_name/$skill_name -> $current_target"
            removed_stale=$((removed_stale + 1))
        fi
    done
}

install_for_target() {
    local target_name="$1"
    local target_dir="$2"
    local resolved_target index skill_dir skill_name skill_path destination current_target

    echo ""
    echo "target: $target_name"
    echo "  directory: $target_dir"

    if [[ -L "$target_dir" && -d "$target_dir" ]]; then
        resolved_target="$(cd "$target_dir" && pwd -P)"
        case "$resolved_target" in
            "$REPO_ROOT" | "$REPO_ROOT"/*)
                echo "  conflict: target directory resolves inside this repository ($resolved_target)"
                conflicts=$((conflicts + 1))
                return
                ;;
        esac
    fi

    if ! mkdir -p "$target_dir"; then
        echo "  conflict: could not create $target_dir"
        conflicts=$((conflicts + 1))
        return
    fi

    for index in "${!skill_dirs[@]}"; do
        skill_dir="${skill_dirs[$index]}"
        skill_name="${skill_names[$index]}"
        skill_path="${skill_paths[$index]}"
        destination="$target_dir/$skill_name"

        if [[ -L "$destination" ]]; then
            current_target="$(readlink "$destination")"
            if [[ "${current_target%/}" == "${skill_dir%/}" ]]; then
                echo "  unchanged: $skill_name ($skill_path)"
                unchanged=$((unchanged + 1))
            elif [[ "${current_target%/}" == "$REPO_ROOT"/* ]]; then
                ln -sfn "$skill_dir" "$destination"
                echo "  updated: $skill_name -> $skill_path"
                updated=$((updated + 1))
            else
                echo "  conflict: $destination is a foreign symlink -> $current_target"
                conflicts=$((conflicts + 1))
            fi
        elif [[ -e "$destination" ]]; then
            echo "  conflict: $destination already exists and is not a symlink"
            conflicts=$((conflicts + 1))
        else
            ln -s "$skill_dir" "$destination"
            echo "  linked: $skill_name -> $skill_path"
            linked=$((linked + 1))
        fi
    done
}

has_codex=false
has_claude=false
has_opencode=false
has_t3_code=false

command -v codex >/dev/null 2>&1 && has_codex=true
command -v claude >/dev/null 2>&1 && has_claude=true
command -v opencode >/dev/null 2>&1 && has_opencode=true

if command -v t3 >/dev/null 2>&1 \
    || command -v t3-code >/dev/null 2>&1 \
    || command -v t3code >/dev/null 2>&1 \
    || [[ -d "/Applications/T3 Code.app" ]] \
    || [[ -d "$HOME/Applications/T3 Code.app" ]] \
    || [[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/applications/t3-code.desktop" ]] \
    || [[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/applications/t3code.desktop" ]] \
    || [[ -f "/usr/share/applications/t3-code.desktop" ]] \
    || [[ -f "/usr/share/applications/t3code.desktop" ]]; then
    has_t3_code=true
fi

echo "Discovered ${#skill_dirs[@]} promoted skill(s) under $SKILLS_ROOT"
echo ""
$has_codex && echo "detected: Codex" || echo "skipped: Codex (command not found)"
$has_claude && echo "detected: Claude Code" || echo "skipped: Claude Code (command not found)"
$has_opencode && echo "detected: OpenCode" || echo "skipped: OpenCode (command not found)"
$has_t3_code && echo "detected: T3 Code" || echo "skipped: T3 Code (command or desktop app not found)"

echo ""
echo "Migrating repository-owned links from the old layout"
migrate_repo_links "Agent Skills" "$AGENT_SKILLS_DIR" "current"
migrate_repo_links "Claude Code" "$CLAUDE_SKILLS_DIR" "current"
if is_truthy "${OPENCODE_DISABLE_EXTERNAL_SKILLS:-}"; then
    migrate_repo_links "OpenCode native" "$OPENCODE_SKILLS_DIR" "current"
else
    migrate_repo_links "OpenCode native" "$OPENCODE_SKILLS_DIR" "legacy"
fi
migrate_repo_links "Legacy Codex" "${CODEX_HOME:-$HOME/.codex}/skills" "legacy"

needs_shared_agents=false
$has_codex && needs_shared_agents=true
$has_t3_code && needs_shared_agents=true
if $has_opencode \
    && ! is_truthy "${OPENCODE_DISABLE_EXTERNAL_SKILLS:-}"; then
    needs_shared_agents=true
fi

if $needs_shared_agents; then
    install_for_target "Agent Skills (Codex/OpenCode)" "$AGENT_SKILLS_DIR"
fi
if $has_claude || $has_t3_code; then
    install_for_target "Claude Code/T3 Claude provider" "$CLAUDE_SKILLS_DIR"
fi
if $has_opencode && is_truthy "${OPENCODE_DISABLE_EXTERNAL_SKILLS:-}"; then
    install_for_target "OpenCode native fallback" "$OPENCODE_SKILLS_DIR"
fi

if $has_t3_code; then
    echo ""
    echo "covered: T3 Code provider-compatible skill locations were linked above"
fi

if ! $has_codex && ! $has_claude && ! $has_opencode && ! $has_t3_code; then
    echo ""
    echo "No supported AI tools detected; nothing was linked."
fi

echo ""
echo "Done. Migrated: $migrated  Removed stale: $removed_stale  Linked: $linked  Updated: $updated  Unchanged: $unchanged  Conflicts: $conflicts"
echo "Run ./cleanup.sh for an optional interactive audit."

$has_codex && echo "Start a new Codex session to load skill changes."
$has_claude && echo "Restart Claude Code or reload its window to load skill changes."
$has_opencode && echo "Restart OpenCode to load skill changes."

[[ $conflicts -eq 0 ]]
