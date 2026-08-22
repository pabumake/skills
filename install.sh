#!/usr/bin/env bash
# Symlink all skills from this repo into ~/.claude/skills/ so Claude Code discovers them.
# Safe to re-run — ln -sf updates existing symlinks.
set -euo pipefail

SKILLS_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$HOME/.claude/skills"
DEPRECATED_DIR="$SKILLS_DIR/deprecated"

mkdir -p "$TARGET_DIR"

echo "Installing skills from $SKILLS_DIR"
echo ""

linked=0
for skill_dir in "$SKILLS_DIR"/*/; do
    skill_name="$(basename "$skill_dir")"

    # Skip deprecated/ directory
    [[ "$skill_dir" == "$DEPRECATED_DIR/" ]] && continue

    # Skip directories without SKILL.md
    [[ -f "${skill_dir}SKILL.md" ]] || continue

    ln -sf "$skill_dir" "$TARGET_DIR/$skill_name"
    # Prevent the install symlink from being tracked if the skill dir is inside this repo
    echo "$skill_name" > "${skill_dir}.gitignore"
    echo "  linked: $skill_name -> $TARGET_DIR/$skill_name"
    linked=$((linked + 1))
done

echo ""
echo "$linked skill(s) linked to $TARGET_DIR"
echo ""
echo "Restart Claude Code to pick up newly linked skills."
echo "Run ./cleanup.sh to review deprecated or removed skills."
