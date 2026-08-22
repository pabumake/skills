---
name: ask-security
description: Select the correct security workflow for an alert, vulnerability, detection, threat research question, or code review. Use when the user explicitly asks which security skill or process fits.
disable-model-invocation: true
metadata:
  origin: "https://github.com/mattpocock/skills/blob/5b15a47f2d7150f545fbcacbfe381787fc0230dc/skills/engineering/ask-matt/SKILL.md"
  source_commit: "5b15a47f2d7150f545fbcacbfe381787fc0230dc"
  license: "MIT"
---

# Ask security

Route the request to one primary workflow and name any supporting workflow. Do not perform the routed work unless the user also asks you to continue.

If the request seeks exploitation, credential abuse, persistence, evasion, destructive action, or another offensive outcome, say that no listed skill applies. Do not force-route it into a defensive workflow. When possible, offer a bounded defensive reframing such as assessing exposure, reviewing the vulnerable change, or designing a detection.

| Need | Primary skill |
|---|---|
| Investigate or disposition an alert or suspicious event | `alert-investigation` |
| Decide whether a vulnerability affects the environment and how urgently to act | `vulnerability-assessment` |
| Design, tune, or validate a detection | `detection-engineering` |
| Research a threat, campaign, technique, advisory, or indicator | `threat-research` |
| Review a code change for security weaknesses | `secure-code-review` |
| Diagnose broken or slow security software | `diagnosing-bugs` |

Every security workflow also applies `security-analysis`. If the request spans workflows, choose the one that produces the immediate decision and list the next workflow as a follow-up.

Respond with:

- The recommended skill.
- Why it fits.
- The minimum input needed to start.
- Any authority or data-disclosure decision the user must make first.
