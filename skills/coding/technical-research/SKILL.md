---
name: technical-research
description: Research a software engineering question from primary sources and save concise, cited findings in the project. Use for framework, platform, API, SDK, protocol, architecture, or implementation decisions. Do not use for threat intelligence.
metadata:
  origin: "https://github.com/mattpocock/skills/blob/5b15a47f2d7150f545fbcacbfe381787fc0230dc/skills/engineering/research/SKILL.md"
  source_commit: "5b15a47f2d7150f545fbcacbfe381787fc0230dc"
  license: "MIT"
---

# Technical research

Define the decision or question before searching. Delegate independent reading to a background agent when available so implementation work can continue.

Use sources that own the answer: official documentation, specifications, source code, release notes, first-party APIs, and research papers. Prefer current version-specific material. Trace important claims to the source instead of relying on secondary summaries.

Save one Markdown note where the project keeps technical research. If no convention exists, use `docs/research/<topic>.md`. Include:

- the question and relevant version or platform constraints;
- findings with direct citations near each claim;
- facts separated from inferences;
- a recommendation tied to the project's constraints;
- unresolved questions and a verification method.

Do not change production code as part of a research-only request. Keep credentials, private source code, and sensitive logs out of the note.
