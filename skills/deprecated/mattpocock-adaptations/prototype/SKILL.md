---
name: prototype
description: Build throwaway code to answer a specific product, state-model, interaction, or UI question before production implementation. Use for logic demos, state-machine exploration, and visibly different UI variants. Do not use when the user has already chosen the design and wants production code.
metadata:
  origin: "https://github.com/mattpocock/skills/tree/5b15a47f2d7150f545fbcacbfe381787fc0230dc/skills/engineering/prototype"
  source_commit: "5b15a47f2d7150f545fbcacbfe381787fc0230dc"
  license: "MIT"
---

# Prototype

A prototype is throwaway code that answers one written question. State that question before writing code and choose the smallest useful form.

## Logic and state questions

Create a single self-contained HTML file that a non-developer can open directly. Keep the model in a pure reducer, state machine, or small function set with no DOM dependency. Show the full relevant state after each action.

Include free-play controls and guided scenarios for the happy path, the most uncertain edge case, and an invalid transition. Use product language in labels. Do not connect to production data or add a framework, persistence, tests, or generalized abstractions.

## UI and interaction questions

Create three structurally different variants unless the user requests another number. Vary layout, information hierarchy, and the primary interaction, not only colors or copy.

Prefer placing variants inside the real surrounding screen with its existing data and styles. Switch variants through a shareable `?variant=` parameter and a development-only control. Keep mutations stubbed or isolated.

## Constraints and handoff

- Put the prototype near the code it informs and mark it clearly as a prototype.
- Make it runnable with one obvious command or by opening one file.
- Skip production hardening, broad error handling, and speculative features.
- Show the user how to run it and what question to judge.
- Record the decision once the question is answered. Move validated ideas into production code through the normal implementation and test workflow.
- Remove prototype-only code from the production path. Preserve it on a separate branch only when the user asks.
