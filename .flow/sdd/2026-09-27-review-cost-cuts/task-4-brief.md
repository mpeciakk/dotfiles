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

### Task 4: writing-specs — split mode past 40 KB, no line numbers (D1)

**Files:**
- Modify: `.claude/skills/writing-specs/SKILL.md`:
  - the frontmatter `description`;
  - the "Number the sections" bullet;
  - `## Scale to the project` (a sentence after the table);
  - a new section placed directly before `## What does not belong in it`.

**Interfaces:** Produces the section heading `## Splitting a spec past 40 KB` and three terms that Task 5 uses: "index", "topic file" and "next free D number".

- [ ] **Step 1: Write the failing check.** Save as `$S/check-task4.sh`: the preamble, then:

```bash
f=skills/writing-specs/SKILL.md
has   $f '## Splitting a spec past 40 KB'
has   $f 'or an existing spec has passed 40 KB and needs splitting into docs/'
has   $f 'Cite code by path and symbol, never by line.'
has   $f '`docs/<topic>.md`'
has   $f 'numbering stays global'
has   $f 'the decision table and the open-points section are dissolved'
has   $f 'next free D number'
has   $f 'splits at its `###` headings'
has   $f 'flags it as over the limit'
has   $f 'moved, not rewritten'
has   $f '40 KB, not the line count, is what triggers a split'
hasnt $f 'Not for amending an existing spec — brainstorming does that per change.'
a=$(grep -n '^## Splitting a spec past 40 KB' $f | cut -d: -f1); b=$(grep -n '^## What does not belong in it' $f | cut -d: -f1)
[ -n "$a" ] && [ "$a" -lt "$b" ] || { echo "ORDER: split section must precede What does not belong in it"; fail=1; }
```

- [ ] **Step 2: Run it.** Run `bash $S/check-task4.sh`. Expected: exit 1 with eleven `MISSING` lines, one `STILL PRESENT` and `ORDER: …`.

- [ ] **Step 3: Implement.** Four edits.

1. **`description`.** Replace the last sentence ("Not for amending an existing spec — brainstorming does that per change.") with one that says the skill is also used when an existing spec has passed 40 KB and needs splitting into docs/, and otherwise is not for amending an existing spec. It must contain the exact phrase `or an existing spec has passed 40 KB and needs splitting into docs/`.
2. **A new bullet after "Number the sections and keep the numbers stable".**
   - It starts `**Cite code by path and symbol, never by line.**`.
   - Example: `` `src/harmonia/store.py` (`pool_upsert`) `` rather than `store.py:104-106`.
   - Why: line numbers go stale with the next unrelated edit and turn every spec sync into a citation hunt. harmonia's spec carried 411 of them.
3. **`## Scale to the project`.** Add one sentence after the table. It must contain `40 KB, not the line count, is what triggers a split` and point at the new section.
4. **A new section, `## Splitting a spec past 40 KB`**, placed before `## What does not belong in it`. Its rules, with numbers exactly as given:
   - **When:** any spec file (`spec.md` or a topic file) over 40 KB by `wc -c`.
   - **Why:** an implementer reads the spec in full on every task that touches it. harmonia's 302 KB spec ran spec-sync implementers at 330–342K context, 3–5× the cost of a code task.
   - **Shape:** `spec.md` becomes the index.
     - It holds `Cel`, `Zakres`, and one line per `docs/<topic>.md`: the path, what the file holds, its section numbers and its D numbers.
     - It also holds the next free D number.
     - It keeps the headings of the decision and open-points sections as pointers to where their rows went.
   - **Decisions and open points:** the decision table and the open-points section are dissolved. Each D row and each open point moves, with its number, to the topic file that holds the section it governs. A row that governs several topics goes with its primary section and is linked from the others. The reason: one `decisions.md` would put 72 KB in front of every design gate, the option D1 rejected.
   - **Numbering stays global:** a moved §7 stays §7, and D numbers continue one sequence. Whoever adds a D row or a section updates the index's next free D number and that file's line in the same commit.
   - **Choosing topics:** group by what one change reads together, not by heading order.
     - A topic file that would pass 40 KB splits again.
     - A single section over 40 KB splits at its `###` headings.
     - A section with no `###` headings stays alone in its own file, and the index flags it as over the limit.
   - **The act:** its own commit. Content is moved, not rewritten, with one exception: `file:line` citations are converted to path + symbol. Every section except the dissolved two lands in exactly one file, and so does every D row.
   - **Scope:** this is a writing-specs job, never a side effect of a feature change.

Follow the voice of `## Scale to the project`: the rule, then why it exists, then the numbers behind it.

- [ ] **Step 4: Verify.** Run `bash $S/check-task4.sh && bash .claude/hooks/flow-guard-test | tail -1`. Expected: `PASS`, then `124 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/writing-specs/SKILL.md
git commit -m "writing-specs: split past 40 KB into docs/ topic files, cite symbols not lines"
```

---
