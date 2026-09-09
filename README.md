# skills

Personal agent skills for technical and defensive security work. The repository owns the general and security skills. A pinned external baseline supplies the engineering workflow without keeping edited copies here.

## Catalog

### General

- [`pbmk-skill-install`](./skills/general/pbmk-skill-install/SKILL.md): Install local skills and the pinned external engineering baseline.
- [`ste`](./skills/general/ste/SKILL.md): Apply ASD-STE100 Simplified Technical English rules.
- [`unslop`](./skills/general/unslop/SKILL.md): Remove common AI-writing patterns.

### External engineering baseline

The installer selects 18 original skills from [`mattpocock/skills`](https://github.com/mattpocock/skills/tree/3cca18b368ae95cdbdebbff572ccafa662551015):

- Workflow: `setup-matt-pocock-skills`, `grill-with-docs`, `triage`, `to-spec`, `to-tickets`, `implement`
- Disciplines: `grilling`, `domain-modeling`, `tdd`, `code-review`, `codebase-design`, `diagnosing-bugs`, `prototype`, `research`
- Extended engineering: `improve-codebase-architecture`, `wayfinder`, `resolving-merge-conflicts`, `wizard`

`ask-matt` is excluded because it routes to productivity skills outside this baseline. Other upstream productivity skills are also excluded.

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
git clone https://github.com/pabumake/skills.git ~/Documents/skills
~/Documents/skills/install.sh
```

Installation requires network access, `npx`, and Node.js 22.20 or newer. It changes the global skill directories for every detected tool.

The installer detects supported tools before it writes anything:

| Tool | Detection | Destination |
|---|---|---|
| Codex | `codex` on `PATH` | `${AGENT_SKILLS_DIR:-$HOME/.agents/skills}` |
| Claude Code | `claude` on `PATH` | `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills` |
| OpenCode | `opencode` on `PATH` | Shared `.agents/skills`, or its native config directory when external skills are disabled |
| T3 Code | CLI or desktop application | Shared `.agents/skills` plus Claude's skill directory for provider compatibility |

Local skills are discovered recursively under promoted categories, then linked by skill name directly into each destination. Before linking, the installer migrates repository-owned links from the old flat layout and removes repository-owned links from obsolete destinations or retired skills.

After local installation succeeds, the installer runs `skills` CLI 1.5.25 against the pinned Matt Pocock commit above. It passes the 18 names explicitly and installs them globally. It never requests the whole upstream repository. Existing external names are refreshed only when the global skill lock attributes them to `mattpocock/skills`; real directories and foreign symlinks are otherwise preserved as conflicts.

The external phase validates the source, commit, and installed `SKILL.md` files. A network, npm, CLI, or validation failure returns a nonzero status. Local changes made before that failure remain applied.

Run cleanup when you want an additional interactive audit:

```bash
~/Documents/skills/cleanup.sh
```

Cleanup reviews current destinations plus legacy Codex and OpenCode locations. It prompts before removing any remaining repository-owned link and ignores third-party links. Normal upgrades do not require it because `install.sh` performs the safe migration automatically.

## Update

```bash
git -C ~/Documents/skills pull
~/Documents/skills/install.sh
```

The external commit and CLI version advance only through reviewed changes to this repository. `npx skills update` is not part of this workflow.

Start a new Codex session or restart Claude Code and OpenCode after installation.

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

The selected names are declared in [`mattpocock-baseline.txt`](./skills/general/pbmk-skill-install/scripts/mattpocock-baseline.txt), while [`install-mattpocock.sh`](./skills/general/pbmk-skill-install/scripts/install-mattpocock.sh) pins the source commit and CLI version. Review upstream changes before advancing any of them.
