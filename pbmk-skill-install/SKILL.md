---
name: pbmk-skill-install
description: Install or update all skills from the personal skills repo into ~/.claude/skills/ by running install.sh. Also offers cleanup of deprecated skills.
origin: https://github.com/pabumake/skills
---

# pbmk-skill-install

Bootstrap or refresh skills from the personal skills repository (`~/Documents/skills/`, GitHub: https://github.com/pabumake/skills) into `~/.claude/skills/` so Claude Code discovers them.

## Steps

1. Run `~/Documents/skills/install.sh` and report the output — how many skills were linked and their names.
2. Ask the user: "Do you also want to run cleanup.sh to review deprecated or removed skills?"
3. If yes, run `~/Documents/skills/cleanup.sh` interactively (it will prompt before removing any symlink).
4. Remind the user to restart Claude Code (or reload the window) for newly linked skills to appear.

## Notes

- `install.sh` is idempotent — safe to run repeatedly after adding new skills to the repo.
- Any subdirectory in the repo containing a `SKILL.md` is auto-discovered. No manual registration needed.
- Skills moved to `deprecated/` are skipped by the installer.
- `cleanup.sh` only touches symlinks that point into this repo — it never removes third-party skills.
