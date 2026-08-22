---
name: detection-engineering
description: Design, review, tune, or validate a vendor-neutral security detection from a threat hypothesis and available telemetry. Use for detection-as-code, analytics rules, SIEM or EDR logic, false positives, telemetry gaps, and test cases.
metadata:
  origin_tdd: "https://github.com/mattpocock/skills/blob/5b15a47f2d7150f545fbcacbfe381787fc0230dc/skills/engineering/tdd/SKILL.md"
  origin_diagnosis: "https://github.com/mattpocock/skills/blob/5b15a47f2d7150f545fbcacbfe381787fc0230dc/skills/engineering/diagnosing-bugs/SKILL.md"
  source_commit: "5b15a47f2d7150f545fbcacbfe381787fc0230dc"
  license: "MIT"
---

# Detection engineering

Read and apply [security-analysis](../security-analysis/SKILL.md). Use the [detection specification](references/detection-spec.md) for the deliverable.

## 1. State the hypothesis

Write one falsifiable sentence describing the actor behavior, observable sequence, protected asset, and why it matters. Define what the detection does not claim to prove.

Map to ATT&CK only when the behavior matches a specific technique definition. Keep the mapping separate from the detection's evidence.

## 2. Establish the telemetry contract

For every field used by the logic, record its source, meaning, type, timestamp semantics, identity stability, expected cardinality, and known collection gaps.

Stop and report a telemetry gap when the available data cannot observe the hypothesis. Do not compensate with a query that detects a weaker behavior while retaining the stronger claim.

## 3. Specify logic before syntax

Describe the required events, joins, sequence, window, grouping, thresholds, and exclusions in vendor-neutral terms. Separate stable environmental filters from temporary suppression.

Do not produce platform syntax unless the target platform and field mappings are known. OpenSearch, Elastic, and Kibana adapters can be added as references later without changing this core specification.

## 4. Test red, green, and noisy

Create fixtures before finalizing logic:

- A positive case that must alert.
- A near miss that must not alert.
- A benign administrative or operational case.
- Missing, delayed, duplicated, and out-of-order telemetry where relevant.
- A boundary case for each threshold and time window.

Run the tests when an authorized local engine or harness exists. Otherwise label them as unexecuted fixtures; never describe untested logic as validated.

## 5. Operationalize

Define investigation pivots, severity rationale, grouping, suppression expiry, expected alert volume, monitoring for data-source failure, and the condition for retiring or revising the detection.

Deployment or modification of a live detection requires explicit authorization.

## Output

Return the completed detection specification in chat unless the user requests a file. This workflow-specific specification replaces the shared result layout; retain the shared evidence, authorization, confidence, unknowns, and redaction rules inside the relevant specification sections. Clearly mark validation status as `tested`, `partially tested`, or `not tested`.
