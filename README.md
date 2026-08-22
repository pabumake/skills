# skills

Personal agent skills for precise technical and defensive security work. Skills are organized by domain in the repository and installed as flat, individually linked skill folders for broad agent compatibility.

## Catalog

### General

- [`pbmk-skill-install`](./skills/general/pbmk-skill-install/SKILL.md): Install or update this repository for detected agent tools.
- [`ste`](./skills/general/ste/SKILL.md): Apply ASD-STE100 Simplified Technical English rules.
- [`unslop`](./skills/general/unslop/SKILL.md): Remove common AI-writing patterns.

### Coding

- [`diagnosing-bugs`](./skills/coding/diagnosing-bugs/SKILL.md): Diagnose hard bugs through a tight feedback loop and falsifiable hypotheses.

### Security

- [`ask-security`](./skills/security/ask-security/SKILL.md): Select the correct security workflow.
- [`security-analysis`](./skills/security/security-analysis/SKILL.md): Apply shared evidence, confidence, redaction, and authorization discipline.
- [`alert-investigation`](./skills/security/alert-investigation/SKILL.md): Investigate and disposition a security alert.
- [`vulnerability-assessment`](./skills/security/vulnerability-assessment/SKILL.md): Assess affectedness, exposure, exploitability, and priority.
- [`detection-engineering`](./skills/security/detection-engineering/SKILL.md): Design a testable vendor-neutral detection.
- [`threat-research`](./skills/security/threat-research/SKILL.md): Research threats from high-trust sources.
- [`secure-code-review`](./skills/security/secure-code-review/SKILL.md): Review a fixed code change for exploitable security weaknesses.

`skills/in-progress/` and `skills/deprecated/` are lifecycle buckets and are not installed.

## Install

```bash
git clone https://github.com/pabumake/skills.git ~/Documents/skills
~/Documents/skills/install.sh
```

The installer detects supported tools before it writes anything:

| Tool | Detection | Destination |
|---|---|---|
| Codex | `codex` on `PATH` | `${AGENT_SKILLS_DIR:-$HOME/.agents/skills}` |
| Claude Code | `claude` on `PATH` | `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills` |
| OpenCode | `opencode` on `PATH` | Shared `.agents/skills`, or its native config directory when external skills are disabled |
| T3 Code | CLI or desktop application | Shared `.agents/skills` plus Claude's skill directory for provider compatibility |

Skills are discovered recursively under promoted categories, then linked by skill name directly into each destination. Before linking, the installer migrates repository-owned links from the old flat layout and removes repository-owned links from obsolete destinations or retired skills. It never removes real directories or foreign symlinks. Rerunning it is idempotent.

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

Start a new Codex session or restart Claude Code and OpenCode after installation.

## Use a skill

Ask for a skill by name. Codex supports `$skill-name`; Claude Code supports `/skill-name`. Skills with precise descriptions can also activate automatically. `ask-security` is explicit-only.

```text
$alert-investigation Investigate this authentication alert from the attached redacted events.
$vulnerability-assessment Assess whether CVE-... affects this deployment.
/detection-engineering Build a vendor-neutral detection specification for this behavior.
```

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
