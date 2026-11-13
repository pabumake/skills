# skills

Personal agent skills for technical and defensive security work. The repository owns the general and security skills. An external baseline supplies Matt Pocock's engineering and productivity skills without keeping edited copies here.

## Catalog

### General

- [`pbmk-skill-install`](./skills/general/pbmk-skill-install/SKILL.md): Install local skills and refresh the external skills.
- [`ste`](./skills/general/ste/SKILL.md): Apply ASD-STE100 Simplified Technical English rules.
- [`unslop`](./skills/general/unslop/SKILL.md): Remove common AI-writing patterns.

### External Matt Pocock skills

The installer selects all 27 skills listed in the [upstream README](https://github.com/mattpocock/skills): 20 engineering skills and 7 productivity skills.

- Workflow: `setup-matt-pocock-skills`, `ask-matt`, `grill-with-docs`, `triage`, `to-spec`, `to-tickets`, `implement`, `implement-spec`
- Disciplines: `grilling`, `domain-modeling`, `tdd`, `code-review`, `codebase-design`, `diagnosing-bugs`, `prototype`, `research`
- Extended engineering: `improve-codebase-architecture`, `wayfinder`, `pr`, `retro`, `wizard`
- Productivity: `grill-me`, `handoff`, `teach`, `to-questionnaire`, `wait-what`, `writing-for-agents`

Upstream `misc`, `in-progress`, and `deprecated` skills are outside the README skillset.

### Security

- [`ask-security`](./skills/security/ask-security/SKILL.md): Select the correct security workflow.
- [`security-analysis`](./skills/security/security-analysis/SKILL.md): Apply shared evidence, confidence, redaction, and authorization discipline.
- [`alert-investigation`](./skills/security/alert-investigation/SKILL.md): Investigate and disposition a security alert.
- [`vulnerability-assessment`](./skills/security/vulnerability-assessment/SKILL.md): Assess affectedness, exposure, exploitability, and priority.
- [`detection-engineering`](./skills/security/detection-engineering/SKILL.md): Design a testable vendor-neutral detection.
- [`threat-research`](./skills/security/threat-research/SKILL.md): Research threats from high-trust sources.
- [`secure-code-review`](./skills/security/secure-code-review/SKILL.md): Review a fixed code change for exploitable security weaknesses.

`skills/in-progress/` and `skills/deprecated/` are lifecycle buckets and are not installed as local skills.

## Install

```bash
git clone https://github.com/pabumake/skills.git ~/src/skills
~/src/skills/install.sh
```

Installation requires network access, `npx`, and Node.js 22.20 or newer. It changes the global skill directories for every detected tool.

The installer detects supported tools before it writes anything:

| Tool | Detection | Destination |
|---|---|---|
| Codex | `codex` on `PATH` | `${AGENT_SKILLS_DIR:-$HOME/.agents/skills}` |
| Claude Code | `claude` on `PATH` | `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills` |
| OpenCode | `opencode` on `PATH` | Shared `.agents/skills`; native links for disabled external discovery or a custom shared path |
| Hermes | `hermes` on `PATH` | Shared `.agents/skills`, registered in `skills.external_dirs` |
| T3 Code | CLI or desktop application | Shared `.agents/skills` plus Claude's skill directory for provider compatibility |

Local skills are discovered recursively under promoted categories, then linked by skill name directly into each destination. Before linking, the installer migrates repository-owned links from the old flat layout and removes repository-owned links from obsolete destinations or retired skills.

Preview installation without writes, CLI initialization, or network requests:

```bash
~/src/skills/install.sh --dry-run
```

The preview reports local link actions and the external update phase. It cannot
determine remote version changes or validate future installations. With no
supported tools installed, the installer exits before migration or linking.

### Hermes and shared skills

Hermes-only installations populate the same shared catalog. The external skills
CLI uses its `codex` target to write that shared directory; Codex need not be
installed. Hermes configuration uses its own `config get/set` commands and
requires a version supporting `config get skills --json` and
`skills.external_dirs`. Python 3 is required for the configuration helper.

The helper preserves existing external directories and other settings.
`HERMES_HOME` selects a custom home or profile. Otherwise, the helper reads
`~/.hermes/active_profile`, falling back to the default profile. It prints the
selected home before configuring it. Repeat the installation with another
`HERMES_HOME` to configure another profile.

Hermes-local skills override shared ones. Installation reports those overrides
and compares complete directories, including support files and executable bits.
To back up identical copies imported from Claude Code:

```bash
~/src/skills/install.sh --dry-run --deduplicate-hermes-imports
~/src/skills/install.sh --deduplicate-hermes-imports
```

Only verified identical ordinary directories under `skills/claude-code-imports`
are moved to `skill-import-backups` inside the selected Hermes home. Differing
imports and foreign links are retained. Merge useful local changes before
retiring a differing override. Shared directories remain writable by Hermes
when filesystem permissions permit it.

`AGENT_SKILLS_DIR` can select a nonstandard shared directory. Hermes registers
the resolved path; OpenCode also receives native-directory links because it
does not automatically discover arbitrary shared locations. The external CLI
always stores its canonical copies in `~/.agents/skills`; the installer links
those copies into alternate destinations and preserves conflicting local copies.

After local installation succeeds, the installer uses the latest `skills` CLI to check the 27 selected Matt Pocock skills against the current upstream repository. It skips unchanged skills, updates changed skills, and adds missing skills. Skills recorded against an old pinned commit are reinstalled from the current source once. It removes explicitly retired skills only when the global skill lock attributes them to `mattpocock/skills`. It does not update unrelated global skills. Existing external names are refreshed only when the global skill lock attributes them to `mattpocock/skills`; real directories and foreign symlinks are otherwise preserved as conflicts.

The external phase validates the source and installed `SKILL.md` files. It does not pin or validate an upstream commit. A network, npm, CLI, or validation failure returns a nonzero status. Local changes made before that failure remain applied.

Run cleanup when you want an additional interactive audit:

```bash
~/src/skills/cleanup.sh
```

Cleanup reviews current destinations plus legacy Codex and OpenCode locations. It prompts before removing any remaining repository-owned link and ignores third-party links. Normal upgrades do not require it because `install.sh` performs the safe migration automatically.

## Update

```bash
git -C ~/src/skills pull
~/src/skills/install.sh
```

The upstream source and CLI use their latest versions. `install.sh` limits the update check to the 27 selected skills and repairs missing installations. When the upstream README adds a skill, add its name to the baseline file before reinstalling.

Start a new Codex session or restart Claude Code after installation. OpenCode
reloads skills automatically; use `/reload` if needed. In Hermes, verify the
catalog with `hermes skills list`; retained local overrides still take precedence.

## Use a skill

Ask for a skill by name. Codex supports `$skill-name`; Claude Code supports `/skill-name`. Skills with precise descriptions can also activate automatically. `ask-security` is explicit-only.

```text
$alert-investigation Investigate this authentication alert from the attached redacted events.
$vulnerability-assessment Assess whether CVE-... affects this deployment.
/detection-engineering Build a vendor-neutral detection specification for this behavior.
```

After the first install, run `$setup-matt-pocock-skills` once in each project that will use the engineering workflow. It records the issue tracker, triage labels, and domain-document layout expected by the upstream skills.

## Security defaults

Security workflows are defensive and read-only by default. They separate observation from inference, state confidence and unknowns, keep evidence local, redact sensitive data, and require explicit authority before external indicator lookups or operational changes.

The first release is vendor-neutral. OpenSearch, Elastic, and Kibana adapters can be added later without changing the core detection specification.

## Add or retire a skill

Create a unique skill directory inside a promoted category:

```text
skills/<category>/<skill-name>/SKILL.md
```

The frontmatter `name` must match `<skill-name>`. Imported or adapted skills must use commit-pinned provenance metadata and include the upstream license in [`THIRD_PARTY_NOTICES.md`](./THIRD_PARTY_NOTICES.md).

Move retired skills into `skills/deprecated/` and rerun `install.sh`. Its old repository-owned link is removed automatically.

The selected names are declared in [`mattpocock-baseline.txt`](./skills/general/pbmk-skill-install/scripts/mattpocock-baseline.txt). [`mattpocock-retired.txt`](./skills/general/pbmk-skill-install/scripts/mattpocock-retired.txt) records removals. [`install-mattpocock.sh`](./skills/general/pbmk-skill-install/scripts/install-mattpocock.sh) performs the update check and installation.
