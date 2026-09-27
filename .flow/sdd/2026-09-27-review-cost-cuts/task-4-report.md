# Task 4 report — writing-specs: split mode past 40 KB (D1)

## Workspace check
- `git rev-parse --show-toplevel` → `/home/m/dotfiles/.claude/worktrees/feat+review-cost-cuts` (matches dispatch)
- `git branch --show-current` → `worktree-feat+review-cost-cuts` (matches dispatch)
- `git status` before editing showed only the pre-existing untracked
  `.flow/sdd/2026-09-27-review-cost-cuts/` (this task's own brief/report dir) —
  nothing else pending, so proceeded.

## What I implemented
Four edits to `.claude/skills/writing-specs/SKILL.md`, exactly as the brief
specified:

1. **Frontmatter `description`** — appended the split-mode trigger and
   reworded the "not for amending" clause so the check's `hasnt` (forbidding
   the original contiguous phrase "Not for amending an existing spec —
   brainstorming does that per change.") still passes while keeping the same
   meaning: "...or an existing spec has passed 40 KB and needs splitting into
   docs/. Otherwise this skill does not amend an existing spec —
   brainstorming does that per change."
2. **New bullet** after "Number the sections and keep the numbers stable":
   "**Cite code by path and symbol, never by line.**" with the exact example
   and the harmonia (411 line citations) rationale from the brief.
3. **`## Scale to the project`** — added one sentence after the table:
   "40 KB, not the line count, is what triggers a split — see `##
   Splitting a spec past 40 KB` below."
4. **New section `## Splitting a spec past 40 KB`**, placed directly before
   `## What does not belong in it`, with all eight rules from the brief
   (When / Why / Shape / Decisions and open points / Numbering stays global /
   Choosing topics / The act / Scope), numbers and phrasing preserved
   verbatim where the brief gave them (40 KB, 302 KB, 330–342K context,
   3–5×, 72 KB, D1).

Interface terms Task 5 depends on are present verbatim: the heading
`## Splitting a spec past 40 KB`, and the terms "index" (spec.md becomes the
index / index's next free D number / index flags it), "topic file" (used
throughout: "topic file that holds the section it governs", "topic file
that would pass 40 KB splits again"), and "next free D number" (both in the
Shape bullet and the Numbering-stays-global rule).

## TDD evidence

**RED** — wrote `$S/check-task4.sh` (the preamble + brief's exact assertions)
and ran it before touching SKILL.md:

```
$ bash /tmp/.../scratchpad/check-task4.sh; echo EXIT:$?
MISSING in skills/writing-specs/SKILL.md: ## Splitting a spec past 40 KB
MISSING in skills/writing-specs/SKILL.md: or an existing spec has passed 40 KB and needs splitting into docs/
MISSING in skills/writing-specs/SKILL.md: Cite code by path and symbol, never by line.
MISSING in skills/writing-specs/SKILL.md: `docs/<topic>.md`
MISSING in skills/writing-specs/SKILL.md: numbering stays global
MISSING in skills/writing-specs/SKILL.md: the decision table and the open-points section are dissolved
MISSING in skills/writing-specs/SKILL.md: next free D number
MISSING in skills/writing-specs/SKILL.md: splits at its `###` headings
MISSING in skills/writing-specs/SKILL.md: flags it as over the limit
MISSING in skills/writing-specs/SKILL.md: moved, not rewritten
MISSING in skills/writing-specs/SKILL.md: 40 KB, not the line count, is what triggers a split
STILL PRESENT in skills/writing-specs/SKILL.md: Not for amending an existing spec — brainstorming does that per change.
ORDER: split section must precede What does not belong in it
EXIT:1
```

This matches the brief's expected RED exactly: eleven `MISSING` lines, one
`STILL PRESENT`, one `ORDER`, exit 1 — confirming the check fails for the
right reason (the content genuinely does not exist yet) before any edit was
made.

**GREEN** — after all four edits:

```
$ bash /tmp/.../scratchpad/check-task4.sh; echo EXIT:$?
PASS
EXIT:0
```

**Full suite:**

```
$ bash .claude/hooks/flow-guard-test | tail -1
124 passed, 0 failed
```

## Files changed
- `.claude/skills/writing-specs/SKILL.md` (+51/-1 lines)
- Check script (scratchpad, not committed):
  `/tmp/claude-1000/-home-m-dotfiles--claude/5f991275-cf7e-4ff1-863c-1e81c88f255f/scratchpad/check-task4.sh`

## Self-review
- All four edits present, in the right locations, surgical (no other lines
  touched).
- Section order verified programmatically: `## Splitting a spec past 40 KB`
  precedes `## What does not belong in it`.
- Numbers/phrases the brief gave verbatim (40 KB, 302 KB, 330–342K, 3–5×,
  72 KB, D1, the `store.py` example) are reproduced exactly.
- Voice matches the brief's instruction ("rule, then why, then numbers"):
  each sub-rule leads with a bold label and a one-line rule, then rationale,
  then the concrete numbers, mirroring `## Scale to the project`'s pattern of
  table/rule first and justifying prose after.
- The one deviation from the brief's literal suggested wording is the
  "Otherwise this skill does not amend an existing spec" phrasing in the
  description (brief's own prose sample would have left the forbidden
  contiguous string intact) — reworded to satisfy the `hasnt` check while
  preserving the same meaning; flagging this as a judgment call rather than
  a silent deviation.
- No unrelated formatting, heading-style, or line-wrap changes elsewhere in
  the file.

## Concerns
None. Check script and flow-guard-test both pass; no scope creep.
