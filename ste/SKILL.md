---
name: ste
description: Rewrite or generate output using ASD-STE100 Simplified Technical English rules — shorter sentences, approved vocabulary, active voice, no AI tells. Invoke with /ste.
---

# STE — Simplified Technical English

Apply ASD-STE100 rules to any text you write or rewrite this session.

## When to use

- Rewrite existing output: `/ste rewrite <text or paste>`
- Apply to all output for this session: `/ste on`
- Disable: `/ste off`
- Check a draft: `/ste check <text>`

## Rules

### Vocabulary

Use one word per concept. No synonyms. Each word has one meaning and one part of speech.

**Replace these:**

| Unapproved | Approved |
|---|---|
| utilize | use |
| perform | do |
| indicate | show |
| prior to | before |
| in order to | to |
| subsequent | next / after |
| approximately | about |
| terminate | stop / end |
| ensure | make sure |
| initiate | start |
| facilitate | help |
| obtain | get |
| require | need |
| sufficient | enough |
| additional | more |
| however | but |
| therefore | so |
| regarding | about |
| concerning | about |
| leverage | use |

Technical names (component names, protocol names, product names) are exempt — use the exact technical name every time, never substitute.

Acronyms: define on first use, then use consistently.

### Sentences

- Procedural sentences (steps, instructions): max 20 words.
- Descriptive sentences (explanations, context): max 25 words.
- One idea per sentence. One instruction per step.
- Active voice. Name the actor.
  - ✗ "The config must be updated" → ✓ "Update the config."
  - ✗ "It is recommended that..." → ✓ "You must..." or just the imperative.
- Put conditions before the instruction.
  - ✗ "Restart the service if the port is already in use."
  - ✓ "If the port is already in use, restart the service."
- Use imperative mood for instructions. Start with the verb.
- Passive voice is allowed only when the actor is unknown or irrelevant.

### Paragraphs

- Procedural: max 10 steps per segment. Split longer procedures into sub-tasks.
- Descriptive: max 6 sentences per paragraph. One topic per paragraph.

### Grammar

- No noun clusters longer than 3 nouns. Break them up with prepositions.
  - ✗ "alert rule field mapping table" → ✓ "table of field mappings for alert rules"
- No ambiguous pronouns. Replace "it", "this", "they" when the referent is unclear.
- Avoid double negatives. State what to do, not what not to avoid.
- Use "the" for specific items, "a/an" for general. Do not drop articles.
- Simple present tense for descriptions. Imperative for procedures. Avoid future tense.

### Procedural vs descriptive text

Never mix them in the same sentence.

| Type | Use for | Style |
|---|---|---|
| Procedural | Steps the reader acts on | Imperative, numbered, one action per step |
| Descriptive | Context, explanations, warnings | Declarative, max 25 words/sentence |

### Warnings and notes

Put warnings, cautions, and notes before the step they apply to — never after.

Format:
```
WARNING: <hazard and consequence — one sentence>
CAUTION: <risk of damage — one sentence>
NOTE: <clarification — one sentence>
```

## Process

1. Identify whether the text is procedural, descriptive, or mixed.
2. Split mixed text into separate procedural and descriptive blocks.
3. Apply vocabulary substitutions.
4. Break sentences that exceed the word limit.
5. Convert passive constructions to active where the actor is known.
6. Move conditions before instructions.
7. Break noun clusters longer than 3 nouns.
8. Replace ambiguous pronouns.
9. Self-audit: read each sentence aloud. If it needs a second read to parse, rewrite it.

## What STE does not change

- Technical names, proper nouns, and acronyms — use them exactly as defined.
- Meaning — never alter the technical content to fit a rule. If a sentence cannot be shortened without losing meaning, keep the meaning and note the exception.
- Code, commands, file paths, and structured data — leave untouched.
