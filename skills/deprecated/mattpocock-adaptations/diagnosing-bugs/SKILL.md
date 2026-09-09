---
name: diagnosing-bugs
description: Diagnose hard bugs and performance regressions with a reproducible feedback loop, falsifiable hypotheses, targeted instrumentation, and a verified regression test. Use when software is broken, failing, flaky, or unexpectedly slow.
metadata:
  origin: "https://github.com/mattpocock/skills/blob/5b15a47f2d7150f545fbcacbfe381787fc0230dc/skills/engineering/diagnosing-bugs/SKILL.md"
  source_commit: "5b15a47f2d7150f545fbcacbfe381787fc0230dc"
  license: "MIT"
---

# Diagnosing bugs

Build confidence through an observable loop. Do not start with a favorite theory.

Work read-only by default. Keep reproduction, replay, stress, fuzz, and instrumentation work local or isolated. Obtain explicit authorization before testing a non-local target, generating meaningful load, replaying production traffic, changing external state, or accessing sensitive production data. A request to diagnose does not authorize a code fix.

## Protect captured data

Treat logs, traces, requests, dumps, and screenshots as potentially sensitive. Keep credentials in environment variables. Redact secrets, tokens, personal data, and authentication headers before showing or saving output.

## 1. Build a red-capable loop

Create one command that reaches the reported failure and distinguishes broken from fixed. Prefer, in order:

1. A focused automated test.
2. A CLI or HTTP reproduction using a fixture.
3. A browser or protocol replay.
4. A minimal harness around the failing seam.
5. A seeded stress, fuzz, differential, or bisection loop.

Tighten the loop until it is specific, repeatable, fast enough to run often, and unattended. For a flaky bug, increase and measure the reproduction rate.

If no valid loop is possible, state what is missing and request the smallest artifact or access needed. Do not present an untested hypothesis as a diagnosis.

## 2. Reproduce and minimize

Run the loop and confirm that it catches the user's exact symptom. Remove inputs, configuration, and steps one at a time until every remaining element is necessary.

## 3. Test hypotheses

Write three to five ranked hypotheses. Each must predict an observable result. Test one variable at a time, starting with the cheapest discriminating test.

Use an existing debugger, profiler, or read-only trace when available. Add narrow boundary instrumentation with a unique marker such as `[DEBUG-a4f2]` only when the user authorized local edits or when working in a disposable isolated copy that cannot affect the user's working tree. Otherwise state which missing signal would discriminate the hypothesis. Avoid broad logging.

## 4. Fix at the correct seam when requested

If the user asked to implement a fix, turn the minimized reproduction into a failing regression test when a real seam exists. Observe the failure, apply the smallest causal fix, observe the test pass, and rerun the original reproduction. Otherwise, stop after establishing the supported root cause and propose the smallest fix and regression test without changing code.

If the architecture prevents a valid regression test, report that limitation rather than adding a shallow test that cannot catch the bug.

## 5. Close cleanly

Before completion:

- Re-run the original reproduction.
- Run the relevant broader test set.
- Remove any tagged instrumentation or throwaway artifacts that this authorized workflow created; do not remove pre-existing user artifacts.
- State the root cause, the evidence that selected it, and why the fix addresses it.
- Record any residual risk or untested boundary.
