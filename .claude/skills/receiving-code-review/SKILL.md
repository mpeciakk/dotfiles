---
name: receiving-code-review
description: Use when receiving code review feedback, before implementing suggestions — especially when feedback seems unclear, incorrect, or technically questionable
---

# Receiving Code Review

Review feedback is a set of claims to verify, not orders to follow. Tone is
CLAUDE.md's candor section — no performative agreement, no thanks, disagreement
first. This skill covers what candor does not: how to process the findings.

## The pattern

1. **Read all of it** before acting on any of it.
2. **Restate** each item as a technical requirement — or ask, if you cannot.
3. **Verify** against the code: does the problem exist here, in this codebase?
4. **Evaluate:** is the suggested fix right for this stack, these callers, this
   plan?
5. **Respond** with the fix or with reasoned pushback.
6. **Implement** in order (below), each item tested.

## Unclear items block everything

If any item is unclear, implement nothing yet and ask about the unclear ones
first. Items are often related; a partial understanding produces a partial,
wrong fix. "I understand 1, 2, 3, 6 — need clarification on 4 and 5."

## By source

- **The user** — implement once you understand it, but still verify: a
  suggestion from the user is where agreeing without checking is most tempting.
  Ask when scope is unclear.
- **A reviewer subagent** (task-reviewer, branch-reviewer) — its findings are
  claims about a diff it read, not about code it could not see. You hold the
  cross-task context it lacks; check each finding against it. A finding that
  contradicts what the plan mandates is the user's call — show both, ask which
  governs (subagent-driven-development).
- **External reviewers** — check: correct for this codebase? breaks existing
  behaviour? is there a reason for the current implementation? all
  platforms/versions? If you cannot verify, say what you would need: "I can't
  verify this without X — investigate, ask, or proceed?"

## Scope is not the reviewer's to grant

"Implement this properly" for a feature nothing calls → check actual usage
(cbm `trace_path`). Unused: propose removing it (YAGNI). A reviewer's authority
does not extend to scope — CLAUDE.md's "nic ponad to, o co proszono".

## Order of work

1. Clarify anything unclear.
2. Blocking issues (breakage, security) → simple fixes → complex fixes.
3. Test each fix; check for regressions.

"One at a time" is the order of work, not the number of dispatches: inside a
plan run the whole Critical/Important list goes to ONE `fixer`, which works it
in this order. A fixer per finding rebuilds context and re-runs the suite each
time.

## Push back when

The suggestion breaks existing behaviour, the reviewer lacks context, it adds an
unused feature, it is wrong for this stack, compatibility requires the current
form, or it conflicts with a decision the user made. Push back with the code or
test that proves it; bring architectural conflicts to the user.

Correct feedback gets "Fixed — [what changed, where]", or just the fix. If your
pushback turns out wrong: "Checked [X] — it does [Y]. Fixing." No apology, no
defence of the pushback.

## GitHub

Reply to inline review comments in their thread
(`gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`), not as a
top-level PR comment.
