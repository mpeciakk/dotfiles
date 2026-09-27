# Branch review fix report

Findings applied at HEAD 9484a9b, per the branch reviewer's list. Fix range
for the re-review: 9484a9b..HEAD (this commit).

## Check script

Saved to
`/tmp/claude-1000/-home-m-dotfiles--claude/5f991275-cf7e-4ff1-863c-1e81c88f255f/scratchpad/check-branch-review.sh`,
one `has`/`hasnt` pair per finding, whitespace-flattened and case-insensitive
per the plan's preamble.

## RED

```
$ bash check-branch-review.sh
MISSING in skills/writing-plans/SKILL.md: alongside the code that made them true. cite code by path and symbol, never by line
STILL PRESENT in skills/writing-plans/SKILL.md: for a split spec: that task's implementer reads those files only, never the whole spec; cite code by path and symbol, never by line
MISSING in skills/brainstorming/SKILL.md: split or not, when the file you write into is over 40 kb
STILL PRESENT in skills/brainstorming/SKILL.md: in the index. when the file you write into is over 40 kb
MISSING in skills/writing-plans/SKILL.md: any blocking or serious objection: surface its ranked objections with your own honest take on each, and resolve the blocking ones
MISSING in skills/writing-plans/SKILL.md: minor objections only, or none
STILL PRESENT in skills/writing-plans/SKILL.md: the dispatch. surface its ranked objections with your own honest take on each
MISSING in skills/development-workflow/SKILL.md: next free d number and that file's line in the index are updated in the same commit
STILL PRESENT in skills/development-workflow/SKILL.md: next free d number is updated in the same commit.
MISSING in skills/requesting-code-review/SKILL.md: review-package <fixbase> head
MISSING in skills/requesting-code-review/SKILL.md: a second needs fixes goes to the user
MISSING in skills/requesting-code-review/SKILL.md: no second fix round
MISSING in skills/requesting-code-review/SKILL.md: .flow/sdd/<run>/branch-review-report.md
MISSING in skills/writing-plans/red-team.md: no objections, or minor ones only:
STILL PRESENT in skills/writing-plans/red-team.md: minor objections only: apply the minor list to the plan yourself
MISSING in skills/writing-specs/SKILL.md: a split also ends at its own user gate
MISSING in skills/writing-specs/SKILL.md: the user approves the topic grouping before the commit
STILL PRESENT in skills/writing-specs/SKILL.md: its own user gate. it is not a stage of the pipeline
MISSING in skills/brainstorming/SKILL.md: this change touches; see the project spec below
STILL PRESENT in skills/brainstorming/SKILL.md: this change touches) (see the project spec below
```
15 MISSING + 7 STILL PRESENT — one pair per finding (IMPORTANT 1 covers two
files, so it contributes two MISSING/STILL-PRESENT pairs).

## Fixes applied

**IMPORTANT 1 — writing-plans/SKILL.md (`## Keeping the Living Spec True`).**
The citation rule and the 40 KB check were gated inside "For a split spec:
... cite code by path and symbol, never by line; and when a file it writes
into is over 40 KB ...". Moved both out to apply unconditionally right after
"alongside the code that made them true."; "For a split spec:" now only
introduces "that task's implementer reads those files only, never the whole
spec."

**IMPORTANT 1 — brainstorming/SKILL.md (`## The Project Spec`, "A split
spec" paragraph).** The 40 KB sentence read as split-only because it sat
inside that paragraph. Prefixed it with "Split or not," per the finding's
suggested fix, leaving it in place syntactically but no longer scoped to the
split case.

**IMPORTANT 2 — writing-plans/SKILL.md (`## Red-Team Pass`).** Was
unconditional: "Surface its ranked objections ... and resolve the blocking
ones ... before execution starts." Qualified it: "Any blocking or serious
objection: surface its ranked objections ... resolve the blocking ones ...
before execution starts. Minor objections only, or none at all: see
red-team.md for how they get applied without a gate." — matching red-team.md
§"After the pass", which already branches this way.

**MINOR 1 — development-workflow/SKILL.md (Small Lane step 1).** "the
index's next free D number is updated in the same commit" became "the
index's next free D number and that file's line in the index are updated in
the same commit", matching writing-specs and brainstorming's existing
wording for the same rule.

**MINOR 2 — requesting-code-review/SKILL.md (step 4, "Critical or Important
present").** Added, in that bullet's own voice: "Package it with
`review-package <fixbase> HEAD`."; "A second Needs fixes goes to the user —
there is no second fix round."; "The fixer writes its evidence to
`.flow/sdd/<run>/branch-review-report.md`."

**MINOR 3 — writing-plans/red-team.md (`## After the pass`, last
paragraph).** "Minor objections only: apply the minor list ..." became "No
objections, or minor ones only: apply the minor list ...", so a report with
no objections at all is covered by the same branch (applying an empty minor
list is a no-op, still with "name what changed" — "no changes" is a valid
one-liner).

**MINOR 4 — writing-specs/SKILL.md (intro).** "This is a bootstrap job — one
document, one sitting, its own user gate." became "... its own user gate; a
split also ends at its own user gate, where the user approves the topic
grouping before the commit." so the sentence covers the split mode the
skill's description already admits.

**MINOR 6 — brainstorming/SKILL.md (Checklist step 1).** Two back-to-back
parentheticals "(for a split spec: ...) (see The Project Spec below)" merged
into one: "(for a split spec: the index and the topic files this change
touches; see The Project Spec below)".

## GREEN

```
$ bash check-branch-review.sh
PASS
```

## Full suite

```
$ bash .claude/hooks/flow-guard-test | tail -1
124 passed, 0 failed
```

## Side effect on an earlier task's check script

`check-task5.sh` (from Task 5's dispatch, kept in the scratchpad as a
historical artifact) asserts the old unmerged form `(for a split spec: the
index and the topic files this change touches)`. MINOR 6 changes that
substring intentionally. Re-running `check-task5.sh` now reports one
`MISSING` for that line; this is expected fallout of applying MINOR 6, not a
regression — `flow-guard-test` (the actual gate) stayed at 124/0 after the
change, and `check-branch-review.sh` (which supersedes it for this text)
passes.

## Declined

None. All seven findings (two IMPORTANT, five MINOR — MINOR 5 was not in the
list) were applied as specified.
