# Task 1 Report: writing-plans — the plan fixes the contract, not the implementation

## What I implemented

Rewrote four passages of `.claude/skills/writing-plans/SKILL.md` per the
brief's Step 3 approach, all four driven by the brief's fixed check script:

1. **Overview** (was line 10): the file-list sentence now names the contract
   ("files, interfaces, the tests in full, exact values, the pattern to
   follow, how to test it") instead of "which files to touch for each task,
   code, testing, docs...". "Assuming...questionable taste" became "assume
   ... does not know its patterns, so every approach names the one to
   follow." Rest of the paragraph (DRY/YAGNI/TDD/Frequent commits) untouched.

2. **New section** `## What the Plan Fixes, and What It Leaves to the
   Implementer`, inserted directly before `## Task Right-Sizing`. Contains:
   a two-column table (always-in-full: interface signatures, full RED test
   code with expected failure, exact values, verified external API shapes;
   only-when-a-decision: implementation code); the criterion sentence with
   the exact phrase "a reviewer would reject a reasonable alternative"
   (examples: algorithm, storage format, lock order, error-handling
   contract); the otherwise-case (1–3 sentence approach + `Follow:`-style
   pattern reference, first-instance-with-no-pattern gets full code); a
   "why, briefly" paragraph (8–22k words, slowed red-team/review, sat in
   controller context, froze pre-existing-task code never run — tests stay
   full because they're the reviewer's contract); and a pointer to the
   absolute design record path
   `~/dotfiles/.flow/specs/2026-09-23-plan-granularity-design.md`.

3. **Task Structure Step 3**: renamed `Write minimal implementation` →
   `Implement`. Code block replaced with an approach placeholder line, a
   `Follow:` line (`` `src/path/existing.py:40-62` (`parse_header`) ``
   example, as specified), and a note that a code block belongs here only
   when the implementation is itself a decision, per the new section. Steps
   1, 2, 4, 5 left untouched.

4. **No Placeholders**: the "code blocks required for code steps" bullet
   replaced with one stating test code is always shown in full, and
   implementation code only when it's a decision, containing the exact
   phrase "an approach with no pattern to follow" (paired with "or with
   nothing concrete in it, is a placeholder"). The "Similar to Task N"
   bullet now says "repeat the test code and values" instead of "repeat the
   code".

Left `## Bite-Sized Task Granularity`, the header template, Self-Review,
Red-Team Pass, Execution Handoff, and `red-team.md` untouched, as the brief
required.

## TDD evidence

**RED** — saved the brief's check script to
`/tmp/claude-1000/-home-m-dotfiles--claude/d2fa4c06-9a89-4a4c-9ce4-5cb1963cfa32/scratchpad/check-task1.sh`
(outside the repo, not committed) and ran it before any edit:

```
$ bash .../scratchpad/check-task1.sh; echo "EXIT: $?"
MISSING: ## What the Plan Fixes, and What It Leaves to the Implementer
MISSING: a reviewer would reject a reasonable alternative
MISSING: - [ ] **Step 3: Implement**
MISSING: an approach with no pattern to follow
STILL PRESENT: code blocks required for code steps
STILL PRESENT: which files to touch for each task, code, testing
STILL PRESENT: - [ ] **Step 3: Write minimal implementation**
ORDER: new section must precede Task Right-Sizing
EXIT: 1
```

This matches exactly the brief's expected RED output (Step 2) — the
required content was genuinely absent and the check script correctly
detects that, not a typo in the script.

**GREEN** — after all four edits:

```
$ bash .../scratchpad/check-task1.sh; echo "EXIT: $?"
PASS
EXIT: 0

$ bash .claude/hooks/flow-guard-test | tail -5
=== context reflects the real vocabulary ===
PASS  a done task is reported to subagents as complete
PASS  a started task is reported in flight

124 passed, 0 failed
```

Both match the brief's Step 4 expectations exactly (`PASS`, then
`124 passed, 0 failed`).

## Files changed

- `.claude/skills/writing-plans/SKILL.md` — 47 insertions, 8 deletions,
  confined to the four passages the brief named (verified via
  `git diff --stat` before commit: one file, no other files touched).

## Self-review

- **Complete:** all four edits present, check script and regression suite
  both green.
- **Surgical:** `git status` before staging showed only
  `.claude/skills/writing-plans/SKILL.md` modified; the untracked
  `.flow/sdd/2026-09-23-plan-granularity/` (brief/report directory) was left
  untracked, not added — it's not part of this task's deliverable.
- **Voice/formatting:** kept the file's existing paragraph-then-bullets
  style; the brief explicitly asked for a table in the new section, which
  is the one structural departure from the rest of the file (this file uses
  prose/lists elsewhere) — flagged below as the one judgment call.
- **Placeholder check:** the new Step 3 template still contains bracketed
  placeholder text (`[The approach, 1–3 sentences.]`) and an illustrative
  `Follow:` path — this is intentional and mirrors the existing template's
  own placeholders (`exact/path/to/file.py`, `[what this task uses...]`)
  one section up; it's a template for future plans to fill in, not a plan
  step itself, so it isn't subject to "No Placeholders" (which governs the
  plans an author writes, not this document's own template).
- Re-ran `git rev-parse --show-toplevel` and `git branch --show-current`
  immediately before staging/commit; both still matched the given worktree
  and branch.

## Concerns

- **Prose vs. table judgment call:** the brief mandated "a two-column
  table" for the new section; I used a literal Markdown table since that's
  the most direct reading, even though the rest of this skill file favors
  prose and bullet lists. If a reviewer prefers converting the table to a
  bulleted always/only-when pair to match file voice more closely, that's a
  one-line judgment call, not a content gap — the required phrase and all
  four content items are present either way.
- Per the brief's own note: this task's controller runs on Sonnet with the
  *old* reviewer rules (D3 not live), so the task-reviewer may raise
  prose-preference findings here that the controller was told to weigh
  itself rather than treat as blocking.
