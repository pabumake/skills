---
name: tdd
description: Build a feature or fix a bug through small red-green cycles at agreed public seams. Use when the user asks for test-first work, red-green-refactor, integration tests, or a regression test with an implementation.
metadata:
  origin: "https://github.com/mattpocock/skills/tree/5b15a47f2d7150f545fbcacbfe381787fc0230dc/skills/engineering/tdd"
  source_commit: "5b15a47f2d7150f545fbcacbfe381787fc0230dc"
  license: "MIT"
---

# Test-driven development

Read the project glossary and relevant ADRs when present. Identify the public seams that matter and confirm them with the user before creating a new test strategy. If a seam is unclear, use the `codebase-design` skill to shape the interface first.

## Cycle

Work in vertical slices:

1. Add one focused test for observable behavior through a public interface.
2. Run it and verify that it fails for the intended reason.
3. Add only enough implementation to make that test pass.
4. Run the focused test again, then the relevant nearby tests.
5. Repeat with the next behavior. Refactor only after the behavior is green.

Never write a batch of imagined tests followed by a batch of implementation.

## Test quality

- Name the caller-visible behavior, not the internal method sequence.
- Derive expected values from a specification, worked example, fixture, or known literal independent of the implementation.
- Test through the module's interface. Do not reach into private state or verify through a side channel.
- Mock only real system seams such as network APIs, time, randomness, file systems, or databases when a test database is impractical.
- Do not mock internal collaborators merely to assert calls, order, or counts.
- Prefer the smallest integration-style test that can fail when the behavior breaks and survive an internal refactor.

Before finishing, run the broader relevant suite and report the exact tests executed.
