#!/usr/bin/env bash
# Review skill symlinks in ~/.claude/skills/ that point into this repo.
# Prompts before removing anything — never silently deletes.
set -euo pipefail

SKILLS_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$HOME/.claude/skills"
DEPRECATED_DIR="$SKILLS_DIR/deprecated"

echo "=== Cleanup: reviewing skill symlinks in $TARGET_DIR ==="
echo ""

removed=0
kept=0
clean=0

for link in "$TARGET_DIR"/*/; do
    link="${link%/}"
    [[ -L "$link" ]] || continue

    target="$(readlink "$link")"
    skill_name="$(basename "$link")"

    # Only handle symlinks that point into this repo
    [[ "$target" == "$SKILLS_DIR"/* ]] || continue

    # Broken symlink — target directory was deleted entirely
    if [[ ! -e "$link" ]]; then
        echo "BROKEN: $skill_name"
        echo "  -> $target (target no longer exists)"
        read -rp "  Remove broken symlink? [y/N] " ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            rm "$link"
            echo "  Removed."
            removed=$((removed + 1))
        else
            echo "  Kept."
            kept=$((kept + 1))
        fi
        echo ""
        continue
    fi

    # Deprecated — skill was moved to deprecated/
    if [[ "$target" == "$DEPRECATED_DIR"/* ]]; then
        echo "DEPRECATED: $skill_name"
        echo "  -> $target"
        read -rp "  Remove symlink for deprecated skill '$skill_name'? [y/N] " ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            rm "$link"
            echo "  Removed."
            removed=$((removed + 1))
        else
            echo "  Kept (deprecated skill still active in Claude Code)."
            kept=$((kept + 1))
        fi
        echo ""
        continue
    fi

    clean=$((clean + 1))
done

echo "Done. Removed: $removed  Kept (reviewed): $kept  Clean (untouched): $clean"
