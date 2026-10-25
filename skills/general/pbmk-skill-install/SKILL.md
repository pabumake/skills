---
name: pbmk-skill-install
description: Install or update this personal skill collection and the selected Matt Pocock engineering skills for detected Codex, Claude Code, OpenCode, and T3 Code environments.
metadata:
  origin: "https://github.com/pabumake/skills"
---

# pbmk-skill-install

Bootstrap or refresh skills from this personal repository. The root installer links locally maintained skills and checks the selected Matt Pocock skills for upstream changes.

## Steps

1. Before running the installer, state that it contacts GitHub and npm and changes the detected tools' global skill directories. Ask for confirmation unless the user explicitly requested installation or update.
2. Run `install.sh` from the checkout containing this skill. It may be at `~/src/skills` or `~/Documents/skills`.
3. Report local results and external baseline results separately. Include the detected tools, local links migrated or removed, conflicts, selected skill count, updated and skipped skills, and validation result.
4. Explain that local migration removes only stale or legacy symlinks owned by this repository. The external installer removes explicitly retired skills only when the global skill lock attributes them to `mattpocock/skills`. It preserves foreign skills.
5. If the external step fails, report that local changes remain applied and do not claim installation succeeded.
6. Offer `cleanup.sh` from the same checkout only as an optional interactive audit.
7. Repeat the restart or new-session instructions printed for each detected tool. After the first installation, tell the user to run `$setup-matt-pocock-skills` once in each project that will use the engineering workflow.

## Notes

- `install.sh` is the only install entry point. After local installation succeeds, it checks existing Matt Pocock skills for changes and adds missing skills.
- The external script uses the latest `skills` CLI and Matt Pocock repository head. It validates ownership and installed files, but does not verify a fixed upstream commit.
- The external allowlist lives beside the installer in `scripts/mattpocock-baseline.txt`. Explicit removals live in `scripts/mattpocock-retired.txt`. Only those names may be passed to the CLI; do not update every globally installed skill or install the whole upstream repository.
- `install.sh` is idempotent and automatically lifts links from the old flat layout into the current category layout.
- After relocating the repository, `install.sh` also adopts links that still point to `~/Documents/skills`.
- Codex, Claude Code, and OpenCode are detected from their CLI commands. T3 Code is detected from its command or desktop app.
- Codex and OpenCode share `~/.agents/skills` when compatible discovery is enabled. Claude Code uses its own skill directory.
- T3 Code uses the skills of its underlying Codex, Claude Code, or OpenCode provider and has no separate link target.
- Any promoted category under `skills/` is discovered recursively. No manual registration is needed.
- Skills under `skills/in-progress/` and `skills/deprecated/` are skipped by the installer.
- Obsolete Codex and OpenCode destinations are cleared only of symlinks that point into this repository.
- `cleanup.sh` remains available to review all known target directories interactively.
