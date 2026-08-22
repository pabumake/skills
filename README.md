# skills

Personal Claude Code skills for the pabumake workspace. Each skill is a Claude Code slash
command that Claude reads at invocation time.

## Skills

| Skill | Slash command | Description |
|---|---|---|
| pbmk-skill-install | `/pbmk-skill-install` | Install or update all skills from this repo |
| ste | `/ste` | Rewrite text with ASD-STE100 Simplified Technical English rules |
| unslop | `/unslop` | Remove AI writing patterns and add human voice |

## Structure

```
skills/
├── install.sh              # Links all skills into ~/.claude/skills/
├── cleanup.sh              # Removes broken or deprecated skill symlinks
├── deprecated/             # Skills moved here are skipped by install.sh
├── pbmk-skill-install/
│   └── SKILL.md
├── ste/
│   └── SKILL.md
└── unslop/
    └── SKILL.md
```

Any subdirectory that contains a `SKILL.md` is a skill. `install.sh` discovers skills
automatically. No manual registration is needed.

## Install

Clone the repository and run the install script:

```bash
git clone https://github.com/pabumake/skills.git ~/Documents/skills
~/Documents/skills/install.sh
```

`install.sh` creates a symlink for each skill in `~/.claude/skills/`. Then restart Claude
Code to pick up the new skills.

The install script is safe to re-run. It updates existing symlinks.

## Update

Pull the latest changes and re-run the install script:

```bash
git -C ~/Documents/skills pull
~/Documents/skills/install.sh
```

Restart Claude Code after the update.

## Remove a skill

Move the skill directory to `deprecated/`:

```bash
mv ~/Documents/skills/<skill-name> ~/Documents/skills/deprecated/
~/Documents/skills/cleanup.sh
```

`cleanup.sh` shows all symlinks that point into this repo and prompts before it removes
anything. It does not remove third-party skills.

To remove all skills from this repo, run `cleanup.sh` and confirm each prompt.

## Add a skill

Create a new directory with a `SKILL.md` file, then run `install.sh`:

```bash
mkdir ~/Documents/skills/<skill-name>
# write SKILL.md
~/Documents/skills/install.sh
```

Restart Claude Code. The new skill is available as `/<skill-name>`.
