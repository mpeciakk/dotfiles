## Global Constraints

- Edit only under `.claude/` of the worktree you were given. Never edit through `~/.claude/…` paths: those are symlinks into the main checkout, not your worktree.
- Skill and agent prose is English. Keep each file's existing voice, heading style and line wrapping (~80 columns).
- Surgical: change only the passages each task names.
- The size threshold is written exactly `40 KB` and measured with `wc -c`.
- Check scripts live in `/tmp/claude-1000/-home-m-dotfiles--claude/5f991275-cf7e-4ff1-863c-1e81c88f255f/scratchpad/` (`$S` below), never in the repo. Create the directory if it is missing.
- After every task, `bash .claude/hooks/flow-guard-test | tail -1` still prints `124 passed, 0 failed`. The suite includes a wall-clock assertion, so a failure caused only by latency gets one re-run before it counts.

Every check script starts with this preamble. Whitespace is normalised because wrapped prose splits phrases across lines, and matching is case-insensitive so that a phrase opening a sentence still matches:

```bash
#!/usr/bin/env bash
cd "$(git rev-parse --show-toplevel)/.claude"; fail=0
flat() { tr '\n' ' ' < "$1" | tr -s ' '; }
has()   { flat "$1" | grep -qiF -- "$2" || { echo "MISSING in $1: $2"; fail=1; }; }
hasnt() { ! flat "$1" | grep -qiF -- "$2" || { echo "STILL PRESENT in $1: $2"; fail=1; }; }
```

Every script ends with `[ $fail = 0 ] && echo PASS || exit 1`.

---

### Task 5: Everything that writes the spec follows the split and the citation rule (D1)

**Files:**
- Modify: `.claude/skills/brainstorming/SKILL.md`:
  - Checklist step 1;
  - `## The Project Spec`: a new paragraph after the one that begins "Their shape varies by project", plus one sentence in item 2 of "At this gate, write both".
- Modify: `.claude/skills/writing-plans/SKILL.md`:
  - the second paragraph of `## Keeping the Living Spec True`;
  - the `**Spec:**` line of the header template.
- Modify: `.claude/skills/development-workflow/SKILL.md`: Small Lane step 1, the sentence "add the row now, at the gate".

**Interfaces:** Consumes, from Task 4, `## Splitting a spec past 40 KB` in writing-specs and its terms "index", "topic file" and "next free D number".

- [ ] **Step 1: Write the failing check.** Save as `$S/check-task5.sh`: the preamble, then:

```bash
b=skills/brainstorming/SKILL.md; p=skills/writing-plans/SKILL.md; w=skills/development-workflow/SKILL.md
has   $b '(for a split spec: the index and the topic files this change touches)'
has   $b 'read the index plus only the topic files this change touches'
has   $b 'Splitting a spec past 40 KB'
has   $b 'next free D number'
has   $b 'over 40 KB'
has   $b 'cite code by path and symbol, never by line'
has   $p 'listing each by file and heading'
has   $p 'reads those files only'
has   $p 'cite code by path and symbol, never by line'
has   $p 'the index plus the topic files this change touches'
has   $w 'for a split spec, the row goes into the topic file that owns the section'
hasnt $p 'sections**, listing them by heading,'
```

- [ ] **Step 2: Run it.** Run `bash $S/check-task5.sh`. Expected: exit 1 with eleven `MISSING` lines and one `STILL PRESENT`.

- [ ] **Step 3: Implement.** Five edits.

1. **brainstorming, step 1.** Directly after "**read the project's living spec first**", insert ` (for a split spec: the index and the topic files this change touches)`.
2. **brainstorming, The Project Spec.** Add a new paragraph after the one that begins "Their shape varies by project". It opens with a bold **A split spec** and describes `spec.md` as an index over `docs/<topic>.md`, pointing at writing-specs' "Splitting a spec past 40 KB". It then says:
   - read the index plus only the topic files this change touches;
   - the decision row and any open point go into the topic file that owns the section;
   - the D number comes from the index's next free D number, and the same commit updates that number and the file's line in the index;
   - when the file being written into is over 40 KB (`wc -c`), say so in one sentence at the design gate as a separate writing-specs job, then carry on, because it does not block this change.
3. **brainstorming, item 2 of "At this gate, write both".** Add the sentence: "In the row and anywhere else in the spec, cite code by path and symbol, never by line."
4. **writing-plans.**
   - In `## Keeping the Living Spec True`, change "listing them by heading" to "listing each by file and heading (`docs/player.md` §7.2, not "the player section")". Then add three things:
     - that task's implementer reads those files only, never the whole spec;
     - it cites code by path and symbol, never by line;
     - when a file it writes into is over 40 KB, the task says so in one line, and splitting stays a separate writing-specs job.
   - In the header template, extend the `**Spec:**` placeholder with: for a split spec, the index plus the topic files this change touches.
5. **development-workflow, Small Lane step 1.** After "add the row now, at the gate —" and its clause, add: for a split spec, the row goes into the topic file that owns the section, and the index's next free D number is updated in the same commit.

Follow the bold lead-in paragraphs brainstorming already uses in `## The Project Spec`, for example "**Sections that describe state**".

- [ ] **Step 4: Verify.** Run `bash $S/check-task5.sh && bash .claude/hooks/flow-guard-test | tail -1`. Expected: `PASS`, then `124 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/brainstorming/SKILL.md .claude/skills/writing-plans/SKILL.md .claude/skills/development-workflow/SKILL.md
git commit -m "spec writers: split specs are read and written per topic file, symbols not lines"
```

---
