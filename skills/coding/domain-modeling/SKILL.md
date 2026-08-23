---
name: domain-modeling
description: Define and sharpen a software product's domain language, state, relationships, and durable decisions. Use when terms are ambiguous, workflows need precise scenarios, a CONTEXT.md is being created or changed, or an architectural decision may need an ADR.
metadata:
  origin: "https://github.com/mattpocock/skills/tree/5b15a47f2d7150f545fbcacbfe381787fc0230dc/skills/engineering/domain-modeling"
  source_commit: "5b15a47f2d7150f545fbcacbfe381787fc0230dc"
  license: "MIT"
---

# Domain modeling

Build a shared vocabulary while designing. Read the nearest `CONTEXT.md`, `CONTEXT-MAP.md`, and relevant ADRs when they exist.

Challenge overloaded terms and propose one precise name for each distinct concept. Test the model with concrete scenarios, especially invalid transitions, retries, partial failure, cancellation, ownership changes, and concurrent actions. Compare claims with the current code and surface contradictions.

## Record the model

Create or update `CONTEXT.md` only when a term is resolved. Keep it as an implementation-free glossary. Each entry should name the term, define it in one or two sentences, state important distinctions, and link related terms when useful.

Use a root `CONTEXT.md` for a single domain. Use `CONTEXT-MAP.md` only when a large repository has genuinely separate domains, each with its own glossary.

## Record decisions sparingly

Offer an ADR only when the decision is hard to reverse, surprising without context, and based on a real tradeoff. Store it with the project's existing ADRs or under `docs/adr/`. Record status, context, decision, consequences, alternatives, and the evidence that would justify revisiting it.

Do not turn implementation details, temporary plans, or unresolved brainstorming into glossary entries or ADRs.
