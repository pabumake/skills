---
name: pbmk-skill-install
description: Install, migrate, or update personal skills for detected Codex, Claude Code, OpenCode, and T3 Code environments without leaving stale repository links.
metadata:
  origin: "https://github.com/pabumake/skills"
---

# pbmk-skill-install

Bootstrap or refresh skills from the personal skills repository (`~/Documents/skills/`, GitHub: https://github.com/pabumake/skills) for the supported AI tools installed on the current machine.

## Steps

1. Run `~/Documents/skills/install.sh` and report the detected tools plus migrated, removed, linked, reused, skipped, and conflicting skills.
2. Explain that the installer automatically removes only stale or legacy symlinks owned by this repository. It preserves real directories and foreign symlinks.
3. Offer `~/Documents/skills/cleanup.sh` only as an optional interactive audit.
4. Repeat the restart or new-session instructions printed for each detected tool.

## Notes

- `install.sh` is idempotent and automatically lifts links from the old flat layout into the current category layout.
- Codex, Claude Code, and OpenCode are detected from their CLI commands. T3 Code is detected from its command or desktop app.
- Codex and OpenCode share `~/.agents/skills` when compatible discovery is enabled. Claude Code uses its own skill directory.
- T3 Code uses the skills of its underlying Codex, Claude Code, or OpenCode provider and has no separate link target.
- Any promoted category under `skills/` is discovered recursively. No manual registration is needed.
- Skills under `skills/in-progress/` and `skills/deprecated/` are skipped by the installer.
- Obsolete Codex and OpenCode destinations are cleared only of symlinks that point into this repository.
- `cleanup.sh` remains available to review all known target directories interactively.
