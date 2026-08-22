---
name: ste
description: Rewrite or generate output using ASD-STE100 Simplified Technical English rules — shorter sentences, approved vocabulary, active voice, no AI tells. Invoke with /ste.
---

# STE — Simplified Technical English

Apply ASD-STE100 Issue 9 rules to any text you write or rewrite this session.

## When to use

- Rewrite existing output: `/ste rewrite <text or paste>`
- Apply to all output for this session: `/ste on`
- Disable: `/ste off`
- Check a draft: `/ste check <text>`

## Rules

### Vocabulary

One word per concept. No synonyms. Each word has one meaning and one part of speech.
Use the same word every time for the same thing — never substitute a synonym for variety.
Use American English spelling (Merriam-Webster).

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
| commence | start |
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
| provides an indication of | shows |
| conduct an investigation of | investigate |
| make an adjustment to | adjust |
| has the ability to | can |
| in the event that | if |
| at this point in time | now |
| a number of | several / many |
| e.g. | for example |
| it should be noted that | (delete — state the fact directly) |

Technical names (component names, protocol names, product names) are exempt — use the exact
technical name every time, never substitute.

Acronyms: define on first use, then use consistently.

### Verb forms

Use only these forms:
- Infinitive: "remove", "start"
- Imperative (command): "Remove the unit."
- Simple present: "The system shows the alert."
- Simple past: "The script failed."
- Past participle — as an adjective only, never as part of a verb construction:
  ✓ "the completed alert", "when the unit is disassembled"

**Forbidden forms:**
- Present perfect: ✗ "has been configured" → ✓ "is configured" or rewrite
- Past perfect: ✗ "had been set" → ✓ "was set"
- Progressive: ✗ "is running" (as description) → ✓ "runs"
- Complex passive: ✗ "is to be installed", "can be adjusted", "must be adjusted",
  "will be adjusted" → convert to active or simple imperative

**"-ing" forms** — permitted only as:
- A technical noun: routing, servicing, logging, monitoring
- A modifier in a technical noun: remaining alerts, missing fields
- Approved standalone words: during, something

All other "-ing" constructions must be rewritten.
✗ "by performing a check" → ✓ "check"
✗ "after configuring the rule" → ✓ "after you configure the rule"

**Nominalization ban** — use the verb directly, not a noun construction:
✗ "gives an indication of" → ✓ "shows"
✗ "before the removal of the unit" → ✓ "before you remove the unit"
✗ "do a review of" → ✓ "review"
✗ "conduct an analysis of" → ✓ "analyze"
✗ "make a decision" → ✓ "decide"

**Phrasal verbs** — not permitted except the approved set:
✗ "put out the fire" → ✓ "extinguish the fire"
✗ "give off fumes" → ✓ "release fumes"
✗ "look into the alert" → ✓ "investigate the alert"

### Sentences

- Procedural sentences (steps, instructions): max 20 words.
- Descriptive sentences (explanations, context): max 25 words.
- One idea per sentence. One instruction per step.
- No contractions.
  ✗ "don't" → ✓ "do not"   ✗ "isn't" → ✓ "is not"
- No word omissions — include all nouns, verbs, subjects, and articles.
  ✗ "If installed, remove the shims." → ✓ "If shims are installed, remove them."
- Active voice. Name the actor.
  ✗ "The config must be updated." → ✓ "Update the config."
  ✗ "It is recommended that..." → ✓ the imperative
- Put conditions before the instruction.
  ✗ "Restart the service if the port is in use."
  ✓ "If the port is in use, restart the service."
- Use imperative mood for instructions. Start with the verb.
- Passive voice is allowed only when the actor is unknown or irrelevant.
- "must" = safety-critical only. For routine steps use the imperative without "must".

### Paragraphs

- Procedural: max 10 steps per segment. Split longer procedures into sub-tasks.
- Descriptive: max 6 sentences per paragraph. One topic per paragraph.
- Start each descriptive paragraph with a topic sentence.

### Lists

- Introduce the list with a complete sentence ending in a colon.
- Each item starts with an uppercase letter.
- Full-sentence items end with a period. Fragment items have no end punctuation
  (no comma, no semicolon at the end of items).
- Last item ends with a period regardless.
- Do not mix procedural and descriptive items in the same list.
- Numbered list for ordered steps. Bulleted list for unordered items.
- The colon counts as a period for word-count: the sentence before the colon must obey the
  20/25-word limit, and each item after the colon is a new sentence subject to the same limit.

### Grammar

- No noun clusters longer than 3 nouns. Break them up with prepositions.
  ✗ "alert rule field mapping table" → ✓ "table of field mappings for alert rules"
- No ambiguous pronouns. Replace "it", "this", "they" when the referent is unclear.
  ✗ "This caused the alert." → ✓ "The failed login caused the alert."
- No double negatives. State what to do.
- Use "the" for specific items, "a/an" for general. Do not drop articles.
- Simple present tense for descriptions. Imperative for procedures. Avoid future tense.
- Always include "that" after verbs that introduce a clause.
  ✗ "Make sure the service runs." → ✓ "Make sure that the service runs."
- Use gender-neutral language. No "he" or "she". Use "the analyst", "the user", "they",
  or the imperative.
- No possessive form (Saxon genitive) when you are unsure it is correct. When in doubt,
  use "of": ✗ "the script's output" → ✓ "the output of the script"
- No Latin abbreviations.
  ✗ "e.g." → ✓ "for example"   ✗ "i.e." → ✓ "that is" or rewrite   ✗ "etc." → write out the items

### Punctuation

- No semicolons. Write two sentences instead.
  ✗ "Check the log; then close the alert." → ✓ "Check the log. Then close the alert."
- Hyphens in compound adjectives before a noun:
  "high-severity alert", "two-factor authentication", "open-source tool"
- Hyphens: uppercase letter + noun:  "T-connector", "L-shaped bracket"
- Hyphens: prefix ending in vowel + root starting with vowel:
  "pre-existing", "re-enter", "de-icing", "anti-icing"
- Parentheses are permitted for: references, identifiers, abbreviations, singular/plural
  "(s)", explanations, alternatives. Not for sentence asides.
- No contractions (see Sentences above).

### Procedural vs descriptive text

Never mix them in the same sentence or the same list.

| Type | Use for | Style |
|---|---|---|
| Procedural | Steps the reader acts on | Imperative, numbered, one action per step |
| Descriptive | Context, explanations, background | Declarative, max 25 words/sentence |

### Warnings and notes

Put warnings, cautions, and notes before the step they apply to — never after.

```
WARNING: <risk of injury or death — one sentence, max 20 words>
CAUTION: <risk of damage to equipment — one sentence, max 20 words>
NOTE: <clarification or context only — no instructions — max 25 words>
```

Notes must not give instructions. If the information is safety-critical, use a warning or
caution instead. A reader must be able to complete the procedure correctly without reading
the notes.

## Word count reference

**Limits**

| Type | Limit |
|---|---|
| Procedural sentence | 20 words |
| Descriptive sentence | 25 words |
| Note sentence | 25 words |
| Safety instruction sentence | 20 words |
| Sentence before a list colon | same limit as its type |
| Procedural segment | 10 steps max |
| Descriptive paragraph | 6 sentences max, 1 topic |

**Each of these counts as 1 word when applying limits**

| Item | Example |
|---|---|
| Number | 500 |
| Number + unit | 10 ms, 4 GB |
| Abbreviation | TCP, IOC, CVE |
| Alphanumeric identifier | P/N 45A72 |
| Hyphenated group | high-severity |
| Proper noun | OpenSearch, GitHub |
| Heading or title used in text | (entire title = 1 word) |
| Text in parentheses | (counts as 1 word in the containing sentence) |
| Quoted text | "ACTIVE" |

## Process

1. Identify whether the text is procedural, descriptive, or mixed.
2. Split mixed text into separate procedural and descriptive blocks.
3. Apply vocabulary substitutions.
4. Check verb forms — remove present perfect, past perfect, progressive, and complex passive
   constructions. Convert nominalizations to direct verbs.
5. Check "-ing" forms — rewrite unless the word is in the approved set.
6. Break sentences that exceed the word limit.
7. Convert passive constructions to active where the actor is known.
8. Move conditions before instructions.
9. Break noun clusters longer than 3 nouns.
10. Replace ambiguous pronouns.
11. Check punctuation — no semicolons, correct hyphens on compound adjectives, no Latin
    abbreviations, no contractions.
12. Self-audit: read each sentence. If it needs a second read to parse, rewrite it.

## What STE does not change

- Technical names, proper nouns, and acronyms — use them exactly as defined.
- Meaning — never alter technical content to fit a rule. If a sentence cannot be shortened
  without losing meaning, keep the meaning and note the exception.
- Code, commands, file paths, and structured data — leave untouched.
