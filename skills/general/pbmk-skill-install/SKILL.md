---
name: pbmk-skill-install
description: Install or update this personal skill collection and its pinned Matt Pocock engineering baseline for detected Codex, Claude Code, OpenCode, and T3 Code environments.
metadata:
  origin: "https://github.com/pabumake/skills"
---

# pbmk-skill-install

Bootstrap or refresh skills from the personal repository at `~/Documents/skills/`. The root installer links locally maintained skills and installs an audited Matt Pocock baseline from a pinned upstream commit.

## Steps

1. Before running the installer, state that it contacts GitHub and npm and changes the detected tools' global skill directories. Ask for confirmation unless the user explicitly requested installation or update.
2. Run `~/Documents/skills/install.sh`.
3. Report local results and external baseline results separately. Include the detected tools, local links migrated or removed, conflicts, upstream commit, selected skill count, and validation result.
4. Explain that the installer removes only stale or legacy symlinks owned by this repository. It preserves real directories and foreign symlinks. The external installer accepts an existing baseline skill only when the global skill lock attributes it to `mattpocock/skills`.
5. If the external step fails, report that local changes remain applied and do not claim installation succeeded.
6. Offer `~/Documents/skills/cleanup.sh` only as an optional interactive audit.
7. Repeat the restart or new-session instructions printed for each detected tool. After the first installation, tell the user to run `$setup-matt-pocock-skills` once in each project that will use the engineering workflow.

## Notes

- `install.sh` is the only install entry point. It always refreshes the pinned external baseline after local installation succeeds.
- The external script pins both the `skills` CLI and the Matt Pocock source commit. Advancing either pin requires a reviewed repository change. Do not replace this flow with `npx skills update`.
- The external allowlist lives beside the installer in `scripts/mattpocock-baseline.txt`. Pass every selected name explicitly; do not use the CLI's whole-repository option.
- `install.sh` is idempotent and automatically lifts links from the old flat layout into the current category layout.
- Codex, Claude Code, and OpenCode are detected from their CLI commands. T3 Code is detected from its command or desktop app.
- Codex and OpenCode share `~/.agents/skills` when compatible discovery is enabled. Claude Code uses its own skill directory.
- T3 Code uses the skills of its underlying Codex, Claude Code, or OpenCode provider and has no separate link target.
- Any promoted category under `skills/` is discovered recursively. No manual registration is needed.
- Skills under `skills/in-progress/` and `skills/deprecated/` are skipped by the installer.
- Obsolete Codex and OpenCode destinations are cleared only of symlinks that point into this repository.
- `cleanup.sh` remains available to review all known target directories interactively.
