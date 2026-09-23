# ADHD-shaped responses, adopted globally — 2026-09-23

Deliberation record. What was rejected and why; the chosen rules live in
`.claude/CLAUDE.md` (section "Kształt odpowiedzi").

## Source

[ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd) (MIT) — ten output
rules (action first, numbered steps, one closing next step, tangents deferred,
state restated, concrete time units, visible wins, matter-of-fact errors, lists
capped at five, no preamble/recap/closers), plus exceptions and a pre-send check.
Adopted in principle, not verbatim.

## D1 — Mechanism: a section in CLAUDE.md

Rejected: **the upstream skill + SessionStart hook** (injects the whole
~120-line SKILL.md). Half of it restates the existing Candor section in other
words — two versions of one rule drift apart — and SessionStart-injected context
is less certain to survive compaction than CLAUDE.md, which is where Candor and
the Karpathy rules already live for that reason. Rejected: **an output style**
(`outputStyle`) — it replaces part of the harness's system prompt, too much blast
radius next to the gated pipeline for a formatting change.

## D2 — Which rules, adapted how

- *Lead with the next action* → lead with the answer or the action; in reviews
  and assessments the top objection leads (Candor's rule, not a conflict).
- *Time estimates* → only conditionally: when an estimate is given, in concrete
  units. Not mandated — an estimate forced on every answer is a guess, against
  CLAUDE.md rule 3.
- *No preamble / no closers* → merged into Candor's existing line, not repeated.
- *Pre-send check* → only the first-line/last-line test kept; the deletion list
  duplicates rule 10 and Candor.
- *"stop adhd mode" toggle* → dropped. It is the user's standing rule, not a mode;
  the "explain / walk me through" exception covers long answers.

## Scope

User-facing responses only. Subagent report formats (task-reviewer, fixer,
branch-reviewer) are defined by their agent files and unchanged; the five-item
cap never truncates a findings list — presentation only, as upstream says.
