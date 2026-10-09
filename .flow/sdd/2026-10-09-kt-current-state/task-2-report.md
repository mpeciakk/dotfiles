# Task 2 report: SKILL.md to D32

Status: DONE. Commit cfd6029 "skills: knowledge-transfer — how it works and current state, machine-agnostic (D32)".

## Implemented
Rewrote `.claude/skills/knowledge-transfer/SKILL.md` per brief changes 1-9 (frontmatter and Hard rules untouched; 206 lines, under the 230 limit). `.claude/README.md`: `dated` -> `current-state` in the Outside-the-pipeline paragraph, re-wrapped (3 lines, same width).

## TDD evidence
Check script: `/tmp/kt-task2-check.sh` (Step 1 block verbatim), run as `bash /tmp/kt-task2-check.sh` from the worktree.

RED (before rewrite), exit 1, `fails=35`:
- still present: dated, reader-prioritised snapshot / Link to the spec instead of restating it / two sentences and / Gdzie stanąłem / Mapa systemu / Pułapki i obejścia / how the user runs it
- missing: all 11 `## N.` headings, Opisuje commit, Skutek:, Do czasu ustalenia:, Current state, not events, Machine- and person-agnostic, datę wygaśnięcia, ../../spec.md, the six new-row quotes, the three Process phrases
- README still says dated

Expected, with one deviation: the brief expected `still present: whether the repo lets them recover it`, but that phrase is line-wrapped in the old file, so `grep -F` did not match it (it passed vacuously). Everything else matched the brief's expectation.

GREEN (after rewrite): first run `fails=1` (`missing: how it was run in the past` - my line wrap split the phrase; fixed by re-wrapping the bullet so the phrase sits on one line). Second run: `fails=0`, exit 0.

## Files changed
- `.claude/skills/knowledge-transfer/SKILL.md`
- `.claude/README.md`

## Self-review
- Every brief change applied in the given wording: opening, Boundary KT row, Intake goal, step 3 formula, step 4 Still asked and Run history, eleven-line heading block, per-section bullets, rule bullets, Cold read line, Common mistakes intro, two replaced Counter cells, six new rows with quotes verbatim.
- Placement choice: the rule bullets (Current state, Machine-agnostic, Explain, Links, existing "Every claim traces" bullet) sit under a lead-in line "Rules for all sections:" which the brief did not spell out. Also "Use these headings verbatim ..." sentence is preceded by "Exactly these eleven headings, in this order:" replacing "One list, in this order:".
- Run history bullet starts "When or whether ..." (capital W after bold label), as the brief's sentence.
- Did not run `check-d32.sh` (that is Task 3, against a real package).

## Concerns
None blocking. Quotes in the new mistake rows include real names/addresses from the first run (10.100.100.205, `pc`), as the brief dictates; they are mistake examples, not package content.
