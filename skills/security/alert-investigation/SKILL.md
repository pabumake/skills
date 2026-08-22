---
name: alert-investigation
description: Investigate and disposition a defensive security alert from local evidence. Use for suspicious authentication, endpoint, network, cloud, identity, or application events. Produces a scoped true-positive, benign-positive, false-positive, or inconclusive result.
metadata:
  origin_diagnosis: "https://github.com/mattpocock/skills/blob/5b15a47f2d7150f545fbcacbfe381787fc0230dc/skills/engineering/diagnosing-bugs/SKILL.md"
  origin_triage: "https://github.com/mattpocock/skills/blob/5b15a47f2d7150f545fbcacbfe381787fc0230dc/skills/engineering/triage/SKILL.md"
  source_commit: "5b15a47f2d7150f545fbcacbfe381787fc0230dc"
  license: "MIT"
---

# Alert investigation

Read and apply [security-analysis](../security-analysis/SKILL.md) before handling evidence.

## 1. Frame the alert

Record the alert source, rule name and version, source severity, trigger time, entities, raw event references, and the behavior the rule claims to detect. Preserve the original query or condition when available.

Define the decision:

- **True positive:** The detected behavior occurred and is unauthorized or malicious.
- **Benign positive:** The detected behavior occurred but is authorized or expected.
- **False positive:** The rule logic or data interpretation detected behavior that did not occur as claimed.
- **Inconclusive:** Available evidence cannot distinguish the outcomes.

## 2. Establish scope and coverage

Normalize the investigation window to UTC while retaining original timestamps. List the identities, hosts, processes, network endpoints, cloud resources, and data sources in scope.

State telemetry coverage, retention, ingestion delay, and any missing source needed to test the alert. Do not interpret a missing event as a negative result without coverage evidence.

## 3. Build and test hypotheses

Create a short ranked set that includes both malicious and benign explanations. For each hypothesis, state the observation that would strengthen it and the observation that would falsify it.

Use authorized local evidence to correlate stable identifiers across the smallest useful time window. Expand the window or entity scope only when a specific hypothesis requires it. Keep queries and results tied to evidence numbers.

## 4. Decide and bound the result

Choose one disposition only when evidence supports it. State confidence, the affected scope proved by the evidence, and the earliest and latest confirmed activity.

Separate:

- Confirmed activity.
- Plausible but unconfirmed extension.
- Areas not examined.

Recommend the lowest-risk next verification step. Containment, blocking, isolation, password reset, or case-system changes require explicit authorization.

## Output

Follow the shared result contract, then add:

- **Disposition:** One of the four defined values.
- **Alert logic assessment:** Correct, overly broad, data-quality failure, or not assessed.
- **Timeline:** UTC events with source IDs.
- **Detection feedback:** A specific tuning or telemetry recommendation only when evidence supports it.
