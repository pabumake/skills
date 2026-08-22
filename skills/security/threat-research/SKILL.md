---
name: threat-research
description: Research a threat, campaign, technique, advisory, or indicator from high-trust sources while controlling disclosure and attribution confidence. Use for defensive threat intelligence and source-backed enrichment, not active engagement.
metadata:
  origin: "https://github.com/mattpocock/skills/blob/5b15a47f2d7150f545fbcacbfe381787fc0230dc/skills/engineering/research/SKILL.md"
  source_commit: "5b15a47f2d7150f545fbcacbfe381787fc0230dc"
  license: "MIT"
---

# Threat research

Read and apply [security-analysis](../security-analysis/SKILL.md). Before querying an indicator or case-derived value externally, disclose the exact value and destination and obtain approval.

## 1. Define the question

State the decision the research must support, the time cutoff, relevant geography or sector, and whether the user needs technical behavior, exposure, attribution, or defensive guidance.

## 2. Build a source plan

Prefer sources that own the claim:

1. Vendor advisories, standards, vulnerability records, government publications, and original research.
2. First-party technical reports with observable details.
3. Reputable secondary analysis used only to locate or compare primary evidence.

Record publication and update times. Treat search snippets, unsourced summaries, and copied IOC lists as leads rather than evidence.

## 3. Handle indicators safely

Keep the user's original representation in evidence and use defanged forms in narrative text when practical. Do not visit suspicious URLs, resolve domains, detonate files, or submit hashes, addresses, or files to third-party services without explicit authorization.

For each indicator, record type, first-party source, first and last observed time if known, context, confidence, and expiry or review condition. An indicator match is not actor attribution.

## 4. Assess claims

Separate technical observations from source assessment and analytic judgment. For attribution, state whether the source claims infrastructure overlap, tooling, behavior, victimology, timing, or direct responsibility. Preserve competing assessments.

Use high confidence only when independent evidence converges and material alternatives are weak. Name collection gaps and plausible alternatives.

## Output

Follow the shared result contract, then add:

- **Research question and cutoff.**
- **Key judgments:** Each with confidence and supporting source IDs.
- **Observed behaviors and indicators:** Contextualized, not bare lists.
- **Attribution assessment:** Or `not assessed`.
- **Defensive implications:** Collection, hunting, detection, and hardening opportunities separated from confirmed facts.
- **Sources:** Direct links with publication or retrieval date.
