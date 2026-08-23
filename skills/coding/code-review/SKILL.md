---
name: code-review
description: Review a fixed code change for correctness, regressions, maintainability, test quality, and fidelity to its specification. Use for pull requests, branches, commits, patches, or work-in-progress diffs. Use secure-code-review separately when exploitability is in scope.
metadata:
  origin: "https://github.com/mattpocock/skills/blob/5b15a47f2d7150f545fbcacbfe381787fc0230dc/skills/engineering/code-review/SKILL.md"
  source_commit: "5b15a47f2d7150f545fbcacbfe381787fc0230dc"
  license: "MIT"
---

# Code review

Review only the fixed change the user placed in scope. Resolve the base ref and confirm the diff is non-empty. Read repository instructions, the originating issue or specification when available, and the changed code in enough surrounding context to judge behavior.

Run independent standards and specification passes in parallel agents when delegation is available. Keep their evidence separate until both passes finish.

## Standards and correctness pass

Look for concrete defects, behavior regressions, broken error handling, invalid state transitions, race conditions, resource leaks, incompatible interfaces, and tests that cannot detect the claimed behavior. Apply documented repository standards before generic preferences.

Use code smells only when they create a real maintenance risk in the change. Relevant smells include duplicated logic, scattered edits for one behavior, speculative abstractions, pass-through modules, repeated conditionals, hidden ordering constraints, and names that conceal domain meaning.

## Specification pass

Check every stated requirement against the diff. Report missing or partial behavior, incorrect implementations, and unrequested behavior that raises risk. If no specification exists, say so and review against the user-visible intent without inventing requirements.

## Findings

Report findings first, ordered by severity. Each finding must include a file and line, the triggering condition, the observable impact, and a specific correction. Do not report style preferences or issues unrelated to the diff. If no material findings remain, say that and list meaningful residual test gaps.

Do not edit code, post comments, approve, merge, or otherwise mutate external state during a review-only request.
