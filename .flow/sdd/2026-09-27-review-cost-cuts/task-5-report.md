# Task 5 Report — Split-spec reading and writing in brainstorming, writing-plans, development-workflow

## Workspace verification

```
$ git rev-parse --show-toplevel
/home/m/dotfiles/.claude/worktrees/feat+review-cost-cuts
$ git branch --show-current
worktree-feat+review-cost-cuts
```

Matches the dispatched worktree/branch. `git status` at start showed only the
untracked `.flow/sdd/2026-09-27-review-cost-cuts/` dir (briefs/report), no
foreign changes.

## What I implemented

Five edits, all under `.claude/skills/`, wiring the split-spec mechanism
(`## Splitting a spec past 40 KB` in writing-specs, added by Task 4) into the
three places that read/write the living spec during normal (non-writing-specs)
work:

1. **brainstorming, Checklist step 1** — after "read the project's living spec
   first", added "(for a split spec: the index and the topic files this
   change touches)".
2. **brainstorming, `## The Project Spec`** — new paragraph after the one
   starting "Their shape varies by project", opening with bold **A split
   spec**, describing `spec.md` as an index over `docs/<topic>.md`, pointing
   at writing-specs' `## Splitting a spec past 40 KB`, and stating: read the
   index plus only the topic files touched; the decision row and any open
   point go into the topic file that owns the section; the D number comes
   from the index's next free D number and the same commit updates both that
   number and the index's line for the file; when the file being written into
   is over 40 KB (`wc -c`), flag it in one sentence at the design gate as a
   separate writing-specs job and carry on — it does not block the change.
3. **brainstorming, item 2 of "At this gate, write both"** — added: "In the
   row and anywhere else in the spec, cite code by path and symbol, never by
   line."
4. **writing-plans, `## Keeping the Living Spec True`** — changed "listing
   them by heading" to "listing each by file and heading (`docs/player.md`
   §7.2, not "the player section")"; added that for a split spec the task's
   implementer reads those files only (never the whole spec), cites code by
   path and symbol never by line, and flags in one line when a file it writes
   into is over 40 KB (splitting stays a separate writing-specs job).
   Also extended the `**Spec:**` header-template placeholder: "For a split
   spec, the index plus the topic files this change touches."
5. **development-workflow, Small Lane step 1** — after "add the row now, at
   the gate —" and its clause, added: "For a split spec, the row goes into
   the topic file that owns the section, and the index's next free D number
   is updated in the same commit."

No other passages were touched.

## TDD evidence

**RED** — check script written to
`/tmp/claude-1000/-home-m-dotfiles--claude/5f991275-cf7e-4ff1-863c-1e81c88f255f/scratchpad/check-task5.sh`
(brief's Step 1 content verbatim), run before any implementation edit:

```
$ bash $S/check-task5.sh
MISSING in skills/brainstorming/SKILL.md: (for a split spec: the index and the topic files this change touches)
MISSING in skills/brainstorming/SKILL.md: read the index plus only the topic files this change touches
MISSING in skills/brainstorming/SKILL.md: Splitting a spec past 40 KB
MISSING in skills/brainstorming/SKILL.md: next free D number
MISSING in skills/brainstorming/SKILL.md: over 40 KB
MISSING in skills/brainstorming/SKILL.md: cite code by path and symbol, never by line
MISSING in skills/writing-plans/SKILL.md: listing each by file and heading
MISSING in skills/writing-plans/SKILL.md: reads those files only
MISSING in skills/writing-plans/SKILL.md: cite code by path and symbol, never by line
MISSING in skills/writing-plans/SKILL.md: the index plus the topic files this change touches
MISSING in skills/development-workflow/SKILL.md: for a split spec, the row goes into the topic file that owns the section
STILL PRESENT in skills/writing-plans/SKILL.md: sections**, listing them by heading,
(exit code 1)
```

Eleven MISSING + one STILL PRESENT, exit 1 — matches the brief's expected RED
exactly ("exit 1 with eleven MISSING lines and one STILL PRESENT").

**GREEN** — after the five edits:

```
$ bash $S/check-task5.sh
PASS
$ bash .claude/hooks/flow-guard-test | tail -1
124 passed, 0 failed
```

## Files changed

- `.claude/skills/brainstorming/SKILL.md`
- `.claude/skills/writing-plans/SKILL.md`
- `.claude/skills/development-workflow/SKILL.md`

Check script (scratchpad, not repo):
`/tmp/claude-1000/-home-m-dotfiles--claude/5f991275-cf7e-4ff1-863c-1e81c88f255f/scratchpad/check-task5.sh`

## Self-review findings

- Initial edit to writing-plans left an awkward line wrap ("...describes.
  That\nis the whole mechanism") because the edit boundary split mid-sentence.
  Fixed by re-wrapping that paragraph to ~80 columns before committing;
  re-ran both check script and flow-guard-test after the fix (still PASS /
  124 passed, 0 failed).
- Confirmed the new brainstorming paragraph follows the existing bold
  lead-in convention (e.g. "**Sections that describe state**") per the
  brief's instruction.
- Confirmed no other passages in the three files were touched (`git diff`
  reviewed in full; only the five named spots changed).
- Grep-checked that the required exact phrases appear verbatim (not just
  paraphrased) since the check script uses literal substring matching (e.g.
  "cite code by path and symbol, never by line" appears as an exact
  imperative clause in both brainstorming and writing-plans, not conjugated
  as "cites").

## Concerns

None. All eleven required phrases are present verbatim, the one forbidden
phrase ("sections**, listing them by heading,") is gone, and both the
task-5 check and the full flow-guard-test suite are green.
