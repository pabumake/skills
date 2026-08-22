---
name: secure-code-review
description: Review a fixed code change for exploitable security weaknesses introduced by the diff. Use for pull requests, branches, commits, patches, or work-in-progress changes involving trust boundaries, authentication, authorization, input handling, secrets, cryptography, dependencies, or security logging.
metadata:
  origin: "https://github.com/mattpocock/skills/blob/5b15a47f2d7150f545fbcacbfe381787fc0230dc/skills/engineering/code-review/SKILL.md"
  source_commit: "5b15a47f2d7150f545fbcacbfe381787fc0230dc"
  license: "MIT"
---

# Secure code review

Read and apply [security-analysis](../security-analysis/SKILL.md). This workflow reviews and reports; it does not edit code unless the user separately requests fixes.

## 1. Pin the review surface

Resolve the user-provided commit, branch, tag, merge base, patch, or file set. For branch review, use the merge-base diff and record the exact command and commit IDs.

Fail early when the fixed point is invalid or the diff is empty. Keep findings tied to behavior introduced or changed by the review surface. Existing weaknesses outside the diff may be noted separately but are not review findings.

## 2. Build the security model

Identify changed entry points, trust boundaries, identities, privileges, sensitive assets, attacker-controlled inputs, security controls, and downstream side effects. Trace changed data across functions and services far enough to determine whether a suspected weakness is reachable.

Read repository security requirements, threat models, ADRs, and coding standards when present. A documented requirement overrides a generic preference, but not a demonstrated vulnerability.

## 3. Review high-signal classes

Inspect only relevant classes:

- Authentication state and session lifecycle.
- Authorization at the resource and action boundary.
- Input parsing, injection, traversal, deserialization, and output encoding.
- Secret handling, cryptographic use, randomness, and key boundaries.
- Sensitive logging, error disclosure, and audit completeness.
- Race conditions, replay, fail-open behavior, and unsafe defaults.
- Dependency, build, CI, and deployment changes that alter trust.
- Resource exhaustion or unbounded attacker-controlled work.

Do not report a checklist item without a concrete path from attacker-controlled conditions to impact.

## 4. Prove each finding

A finding must include:

- Changed file and line or hunk.
- Attacker capability and preconditions.
- Reachable execution or data-flow path.
- Violated security property.
- Concrete impact.
- Confidence and supporting evidence.
- Minimal remediation at the correct boundary.
- A regression or verification test.

Rank severity from demonstrated impact and realistic preconditions. Do not invent CVSS. Suppress style observations, generic hardening advice, and speculative concerns that lack a reachable path.

## Output

This findings-first format replaces the shared result layout; retain the shared evidence, authorization, confidence, unknowns, and redaction rules throughout.

Lead with findings ordered by severity. If there are none, say that no supported vulnerabilities were found in the reviewed surface and list material areas not examined.

After findings, include:

- **Review surface:** Fixed point, commits, files, and commands.
- **Threat model:** Trust boundaries and attacker assumptions used.
- **Coverage:** Security classes examined.
- **Residual uncertainty:** Missing tests, runtime configuration, generated code, or external systems that limited confidence.
