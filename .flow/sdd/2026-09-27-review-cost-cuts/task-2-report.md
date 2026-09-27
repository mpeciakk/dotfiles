# Task 2 report — Fix loops: no fixer after all-Minor Approved, bounded fixes after branch review (D3)

## Implemented

Three edits, exactly as specified by the brief.

1. **`.claude/skills/requesting-code-review/SKILL.md`, step 4 ("Act on it").**
   Replaced the single opening sentence with the full rule as five bulleted
   cases: *Before any fixer* (record `fixbase=` via flow-state, or note it in
   the reply outside a run), *Critical or Important present* (one fix
   subagent, re-review scoped to `<fixbase>..HEAD` via `task-reviewer` whose
   brief is the finding list), *Kept Minor findings only* (one fixer, full
   suite green, no re-review), *Minor findings you do not keep* (record, don't
   drop), and *Why* (34/147 historical fixers ran after a branch review). Kept
   the trailing "push back if the reviewer is wrong" sentence unchanged.

2. **`.claude/skills/subagent-driven-development/SKILL.md`, loop step 7.**
   Appended one sentence after "Minor findings go into the ledger note and get
   handed to the final review to triage.": the all-Minor-Approved rule
   ("An Approved review whose findings are all Minor, with every ⚠️ resolved,
   ends the task: its Minor findings go to the ledger, never to a fixer.")
   plus its own "why" (15/147 fixers ran after an Approved review), matching
   the voice already used in that step (rule, then a short why backed by
   history).

3. **`.claude/skills/subagent-driven-development/SKILL.md`, after-last-task and
   `## Never`.**
   - After-last-task: added "Acting on its findings follows
     requesting-code-review, step 4." right after the sentence about passing
     the accumulated Minor findings, before the "Skip it in one case only"
     sentence.
   - `## Never`: qualified the existing bullet "Move to the next task with
     unfixed Critical/Important findings, or skip the re-review after a fix."
     with its one exception — "except a Minor-only fix after the branch review
     (requesting-code-review, step 4)." — and added a new bullet directly
     after it: "Dispatch a fixer after an Approved task review whose findings
     are all Minor."

No other lines in either file were touched. SDD refers to requesting-code-review
step 4 by name in two places (after-last-task, Never) rather than restating the
rule, per the brief's Interfaces note.

## TDD evidence

**RED** — wrote `$S/check-task2.sh` (the preamble plus the exact ten
assertions given in the brief) before any edit, then ran it:

```
$ bash /tmp/claude-1000/-home-m-dotfiles--claude/5f991275-cf7e-4ff1-863c-1e81c88f255f/scratchpad/check-task2.sh
MISSING in skills/requesting-code-review/SKILL.md: the re-review covers only the fix range
MISSING in skills/requesting-code-review/SKILL.md: fixbase=
MISSING in skills/requesting-code-review/SKILL.md: whose brief is the finding list
MISSING in skills/requesting-code-review/SKILL.md: full suite green
MISSING in skills/requesting-code-review/SKILL.md: with no re-review
STILL PRESENT in skills/requesting-code-review/SKILL.md: Critical and Important findings go to ONE fix subagent with the complete list; Minor findings get recorded
MISSING in skills/subagent-driven-development/SKILL.md: An Approved review whose findings are all Minor, with every ⚠️ resolved, ends the task
MISSING in skills/subagent-driven-development/SKILL.md: Dispatch a fixer after an Approved task review whose findings are all Minor.
MISSING in skills/subagent-driven-development/SKILL.md: requesting-code-review, step 4
EXIT:1
```

8 `MISSING` lines and 1 `STILL PRESENT`, exit 1 — matches the brief's expected
RED exactly (the one `hasnt` on SDD for "the re-review covers only the fix
range" already passed pre-edit, as expected, since SDD never had that phrase).
This confirms the checks fail for the right reason: the rule text does not
exist yet in either file.

**GREEN** — after the three edits:

```
$ bash /tmp/claude-1000/-home-m-dotfiles--claude/5f991275-cf7e-4ff1-863c-1e81c88f255f/scratchpad/check-task2.sh
PASS
```

**Full suite** — ran after check-task2 passed:

```
$ bash .claude/hooks/flow-guard-test | tail -1
124 passed, 0 failed
```

## Files changed

- `.claude/skills/requesting-code-review/SKILL.md` (step 4 rewritten, rest
  unchanged) — 3621 bytes, well under the 40 KB threshold.
- `.claude/skills/subagent-driven-development/SKILL.md` (step 7, after-last-task,
  `## Never` — three localized additions) — 15576 bytes, well under the
  threshold.

Commit: `470f3f0` — "review: no fixer after all-Minor Approved, branch-review
fixes re-reviewed over the fix range"

## Self-review

- Diff is surgical: `git diff --stat` shows only the two named files, 28
  insertions / 7 deletions total, and `git diff` confirms every hunk maps to
  one of the three specified edit points — no incidental reformatting.
- Voice/style: matched the existing bullet-list convention already used
  elsewhere in requesting-code-review (numbered steps with bold lead-ins) and
  the "rule, then why, backed by a count" pattern SDD step 7 already had.
  Line wrapping kept near the existing ~80-column style.
- Interfaces: confirmed the phrase "the re-review covers only the fix range"
  exists only in requesting-code-review (not duplicated into SDD) — the final
  `hasnt` in the check enforces this and passed.
- No edits were made outside the two named files; the `.flow/sdd/...` brief
  and report files are the only other untracked paths and were not added to
  git.

## Concerns

None. All ten check assertions and the full flow-guard-test suite pass; the
edits are confined to exactly the passages the brief named.
