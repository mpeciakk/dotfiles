# Review and Spec Cost Cuts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cut fix loops and context size: paperwork findings drop to Minor, no fixer after an Approved review, a Minor-only red-team says PROCEED, and a spec past 40 KB splits into `docs/` topic files that the pipeline reads and writes one at a time.

**Architecture:** Prose changes to skills and agent definitions under `/home/m/dotfiles/.claude` (deployed to `~/.claude` as symlinks). There are no hook or script changes. Each task gets a grep check over the exact phrases it must add and remove. After Task 5, the controller replays historical reviews and red-team reports against the new rules (`## Verification`).

**Tech Stack:** Markdown skill files, agent definitions, bash checks.

**Spec:** none — the dotfiles have no living `spec.md`, so no spec-sync task either.

**Design record:** `/home/m/dotfiles/.flow/specs/2026-09-27-review-cost-cuts-design.md` (D1 spec split, D2 reviewer rubric, D3 fix loops, D4 red-team verdict)

## Global Constraints

- Edit only under `.claude/` of the worktree you were given. Never edit through `~/.claude/…` paths: those are symlinks into the main checkout, not your worktree.
- Skill and agent prose is English. Keep each file's existing voice, heading style and line wrapping (~80 columns).
- Surgical: change only the passages each task names.
- The size threshold is written exactly `40 KB`, measured with `wc -c`.
- Check scripts live in `/tmp/claude-1000/-home-m-dotfiles--claude/5f991275-cf7e-4ff1-863c-1e81c88f255f/scratchpad/` (`$S` below), never in the repo.
- After every task, `bash .claude/hooks/flow-guard-test | tail -1` still prints `124 passed, 0 failed`. It includes a wall-clock assertion: a latency-only failure gets one re-run before it counts.

Every check script uses this preamble (whitespace is normalised because wrapped prose splits phrases across lines):

```bash
#!/usr/bin/env bash
cd "$(git rev-parse --show-toplevel)/.claude"; fail=0
flat() { tr '\n' ' ' < "$1" | tr -s ' '; }
has()   { flat "$1" | grep -qF -- "$2" || { echo "MISSING in $1: $2"; fail=1; }; }
hasnt() { ! flat "$1" | grep -qF -- "$2" || { echo "STILL PRESENT in $1: $2"; fail=1; }; }
```

and ends with `[ $fail = 0 ] && echo PASS || exit 1`.

---

### Task 1: task-reviewer — paperwork is Minor, a test that could not fail stays Important (D2)

**Controller:** the text is given in full, so dispatch with `model: "haiku"`.

**Files:**
- Modify: `.claude/agents/task-reviewer.md` — `## Tests` last paragraph (lines 61-65), the living-spec paragraph in `## Part 1` (lines 87-90), `## Calibration` first paragraph (lines 112-116)

**Interfaces:** none.

- [ ] **Step 1: Write the failing check** — save as `$S/check-task1.sh` (preamble, then):

```bash
f=agents/task-reviewer.md
has   $f 'A test that **could not have been RED**'
has   $f 'is **Minor**: "RED output missing"'
has   $f 'The test is the evidence; the transcript is paperwork about it.'
has   $f 'Outside such a task, a stale citation'
has   $f 'a missing RED transcript for a sound test are **Minor**'
hasnt $f 'Missing RED output, or a RED that would have failed'
```

- [ ] **Step 2: Run it** — `bash $S/check-task1.sh`. Expected: exit 1, with five `MISSING` lines and one `STILL PRESENT`.

- [ ] **Step 3: Implement** — apply exactly:

Replace the `## Tests` paragraph that starts "Check the TDD evidence exists before trusting it." with:

```
Check the TDD evidence exists before trusting it. For every new behaviour in this
diff the report must show a RED command whose output fails for the stated reason,
then a GREEN one. A test that **could not have been RED** — it passed before the
change, it never reaches the code the change touches, or its RED failed for an
unrelated reason (import error, syntax) — is an **Important** finding: "TDD
evidence unsound", with the test's file:line. RED output that is merely
**missing**, for a test that exists, targets the new behaviour and passes, is
**Minor**: "RED output missing". The test is the evidence; the transcript is
paperwork about it.
```

Append to the paragraph ending "A spec that lies is worse than one that is thin.":

```
Outside such a task, a stale citation (a `file:line` that moved) or drift in docs
that state no behaviour is **Minor**; a doc that states wrong behaviour is not.
```

In `## Calibration`, replace `"Coverage could be broader" and polish are **Minor**.` with `"Coverage could be broader", polish, a stale citation and a missing RED transcript for a sound test are **Minor**.`

- [ ] **Step 4: Verify** — `bash $S/check-task1.sh && bash .claude/hooks/flow-guard-test | tail -1`. Expected: `PASS`, then `124 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add .claude/agents/task-reviewer.md
git commit -m "task-reviewer: missing RED transcript and stale citations are Minor"
```

---

### Task 2: Fix loops — no fixer after Approved, bounded branch-review fixes (D3)

**Files:**
- Modify: `.claude/skills/subagent-driven-development/SKILL.md` — loop step 7 (lines 125-130), the "After the last task" paragraph (lines 150-154), `## Never` (lines 248-259)
- Modify: `.claude/skills/requesting-code-review/SKILL.md` — step 4 "Act on it" (lines 55-58)

**Interfaces:** Produces the phrase "the re-review covers only the fix range", which both files use for the same rule.

- [ ] **Step 1: Write the failing check** — save as `$S/check-task2.sh` (preamble, then):

```bash
s=skills/subagent-driven-development/SKILL.md; r=skills/requesting-code-review/SKILL.md
has   $s 'An Approved review ends the task'
has   $s 'the re-review covers only the fix range'
has   $s 'Minor-only'
has   $s 'no re-review'
has   $s 'Dispatch a fixer after an Approved task review.'
has   $r 'the re-review covers only the fix range'
has   $r 'full suite green'
hasnt $r 'Critical and Important findings go to ONE fix subagent with the complete list; Minor findings get recorded'
```

- [ ] **Step 2: Run it** — `bash $S/check-task2.sh`. Expected: exit 1, with seven `MISSING` lines and one `STILL PRESENT`.

- [ ] **Step 3: Implement** — four edits, each covering a line of the check:

1. **SDD step 7:** add a sentence after "Minor findings go into the ledger note and get handed to the final review to triage." It must contain `An Approved review ends the task`: whatever Minor findings an Approved review lists go to the ledger and never to a fixer. Why: 15 of 147 historical fixers ran after an Approved review.
2. **SDD after-last-task:** a new paragraph right after the one that ends "Two tasks or more, or any doubt: run it." and before "Then record that the gate ran". It says how to act on the branch review:
   - Critical/Important, plus any Minor the controller keeps, go to ONE fixer. Then a branch-reviewer re-review runs, and the re-review covers only the fix range (`<pre-fix HEAD>..HEAD`), handed the findings and the fixer's report.
   - Minor-only (nothing Critical or Important kept) → one fixer whose report shows the full suite green, and no re-review.
   - Why: 34 of 147 fixers ran after branch review. A re-review of the whole branch re-reads work already approved task by task.
3. **SDD `## Never`:** add the bullet `- Dispatch a fixer after an Approved task review.` right after the "Move to the next task with unfixed…" bullet. Qualify that bullet's "or skip the re-review after a fix" with the one exception, a Minor-only fix after the branch review.
4. **requesting-code-review step 4:** replace the first sentence ("Critical and Important findings go to ONE fix subagent with the complete list; Minor findings get recorded, not silently dropped.") with the same rule for this context:
   - Critical/Important plus kept Minor → ONE fix subagent with the complete list, and the re-review covers only the fix range.
   - Kept Minor alone → one fixer whose report shows the full suite green, with no re-review.
   - Minor findings not kept get recorded, not silently dropped.
   - Keep the rest of step 4 as it is.

Follow: the existing voice of SDD step 7, a bold lead-in followed by a short history-backed "why".

- [ ] **Step 4: Verify** — `bash $S/check-task2.sh && bash .claude/hooks/flow-guard-test | tail -1`. Expected: `PASS`, then `124 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/subagent-driven-development/SKILL.md .claude/skills/requesting-code-review/SKILL.md
git commit -m "sdd: no fixer after Approved, branch-review fixes re-reviewed over the fix range only"
```

---

### Task 3: plan-red-team — WITH CHANGES needs a blocking or serious objection (D4)

**Controller:** the text is given in full, so dispatch with `model: "haiku"`.

**Files:**
- Modify: `.claude/agents/plan-red-team.md` — `## Output` item 3 (line 53)
- Modify: `.claude/skills/writing-plans/red-team.md` — `## After the pass` (lines 39-46)

**Interfaces:** none.

- [ ] **Step 1: Write the failing check** — save as `$S/check-task3.sh` (preamble, then):

```bash
a=agents/plan-red-team.md; r=skills/writing-plans/red-team.md
has   $a 'PROCEED WITH CHANGES needs at least one blocking or serious objection'
has   $a 'the verdict is PROCEED and the minor ones are listed under it'
has   $r 'For PROCEED WITH CHANGES or RETHINK, surface'
has   $r 'apply its minor list to the plan yourself'
has   $r 'name what changed in one line at the plan gate'
hasnt $r 'If the verdict is PROCEED with no blocking objections, say so in one line and'
```

- [ ] **Step 2: Run it** — `bash $S/check-task3.sh`. Expected: exit 1, with five `MISSING` lines and one `STILL PRESENT`.

- [ ] **Step 3: Implement** — apply exactly:

In `agents/plan-red-team.md`, replace `3. One-line verdict: PROCEED / PROCEED WITH CHANGES / RETHINK` with:

```
3. One-line verdict: PROCEED / PROCEED WITH CHANGES / RETHINK. PROCEED WITH
   CHANGES needs at least one blocking or serious objection; with minor
   objections only, the verdict is PROCEED and the minor ones are listed under it
   as edits to apply.
```

In `skills/writing-plans/red-team.md`, `## After the pass`:
- Change the paragraph's opening "Surface the ranked objections to the user verbatim," to "For PROCEED WITH CHANGES or RETHINK, surface the ranked objections to the user verbatim,". Leave the rest of that paragraph unchanged.
- Replace the last paragraph ("If the verdict is PROCEED with no blocking objections, … Do not stage a debate the plan does not need.") with:

```
If the verdict is PROCEED, apply its minor list to the plan yourself — no gate,
no debate — commit the amended plan, and name what changed in one line at the
plan gate. Skip an item you disagree with, and say which and why in that same
line.
```

- [ ] **Step 4: Verify** — `bash $S/check-task3.sh && bash .claude/hooks/flow-guard-test | tail -1`. Expected: `PASS`, then `124 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add .claude/agents/plan-red-team.md .claude/skills/writing-plans/red-team.md
git commit -m "red-team: minor-only objections give PROCEED, applied without a gate"
```

---

### Task 4: writing-specs — split mode past 40 KB, no line numbers (D1)

**Files:**
- Modify: `.claude/skills/writing-specs/SKILL.md` — frontmatter `description` (line 3), the "Number the sections" bullet (lines 39-41), `## Scale to the project` (after the table, ~line 124), and a new section placed directly before `## What does not belong in it`

**Interfaces:** Produces the section heading `## Splitting a spec past 40 KB`. Task 5 points brainstorming and writing-plans at it by that name.

- [ ] **Step 1: Write the failing check** — save as `$S/check-task4.sh` (preamble, then):

```bash
f=skills/writing-specs/SKILL.md
has   $f '## Splitting a spec past 40 KB'
has   $f 'or an existing spec has passed 40 KB and needs splitting into docs/'
has   $f 'Cite code by path and symbol, never by line.'
has   $f '`docs/<topic>.md`'
has   $f 'numbering stays global'
has   $f 'moved, not rewritten'
hasnt $f 'Not for amending an existing spec — brainstorming does that per change.'
a=$(grep -n '^## Splitting a spec past 40 KB' $f | cut -d: -f1); b=$(grep -n '^## What does not belong in it' $f | cut -d: -f1)
[ -n "$a" ] && [ "$a" -lt "$b" ] || { echo "ORDER: split section must precede What does not belong in it"; fail=1; }
```

- [ ] **Step 2: Run it** — `bash $S/check-task4.sh`. Expected: exit 1, with six `MISSING` lines, one `STILL PRESENT` and `ORDER: …`.

- [ ] **Step 3: Implement** — four edits:

1. **description:** replace the last sentence "Not for amending an existing spec — brainstorming does that per change." with one that says the skill is also for when an existing spec has passed 40 KB and needs splitting into docs/ (exact phrase `or an existing spec has passed 40 KB and needs splitting into docs/`), and otherwise not for amending an existing spec.
2. **New bullet** after "Number the sections and keep the numbers stable": it starts `**Cite code by path and symbol, never by line.**`, gives the example `` `src/harmonia/store.py` (`pool_upsert`) `` rather than `store.py:104-106`, and gives the why: line numbers go stale with the next unrelated edit, so every spec sync turns into a citation hunt. harmonia's spec carried 411 of them.
3. **Scale to the project:** one sentence after the table saying that past 40 KB, a band's upper end is reached in bytes rather than lines, and pointing at the new section.
4. **New section** `## Splitting a spec past 40 KB`, before `## What does not belong in it`. It must say:
   - *When:* any spec file (`spec.md` or a `docs/` topic file) over 40 KB by `wc -c`.
   - *Why:* an implementer reads the spec in full on every spec-touching task. harmonia's 302 KB spec ran spec-sync implementers at 330–342K context, 3–5× a code task.
   - *Shape:* `spec.md` becomes the index — `Cel`, `Zakres`, then one line per `docs/<topic>.md`: its path, what it holds, and the section numbers it carries. Each topic file holds its own sections, the decisions governing them, and their open points.
   - *Numbering stays global:* a moved §14 stays §14, and D-numbers continue from one sequence. The index names the next free D number.
   - *Choosing topics:* by what one change reads together, not by heading order. A topic file that would itself pass 40 KB splits again.
   - *The act:* its own commit, content moved, not rewritten. The one exception is converting `file:line` citations to path + symbol. Every original section lands in exactly one file.
   - *Scope:* this is a writing-specs job, never a side effect of a feature change.

Follow: the voice of `## Scale to the project` — a rule, then the reason it exists, then the numbers behind it.

- [ ] **Step 4: Verify** — `bash $S/check-task4.sh && bash .claude/hooks/flow-guard-test | tail -1`. Expected: `PASS`, then `124 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/writing-specs/SKILL.md
git commit -m "writing-specs: split past 40 KB into docs/ topic files, cite symbols not lines"
```

---

### Task 5: brainstorming and writing-plans read and write one topic file (D1)

**Files:**
- Modify: `.claude/skills/brainstorming/SKILL.md` — Checklist step 1 (line 44), `## The Project Spec` (a new paragraph after the "Their shape varies by project" paragraph, ~line 71)
- Modify: `.claude/skills/writing-plans/SKILL.md` — `## Keeping the Living Spec True` second paragraph (lines 69-74)

**Interfaces:** Consumes the heading `## Splitting a spec past 40 KB` from Task 4 (writing-specs).

- [ ] **Step 1: Write the failing check** — save as `$S/check-task5.sh` (preamble, then):

```bash
b=skills/brainstorming/SKILL.md; p=skills/writing-plans/SKILL.md
has   $b '(for a split spec: the index and the topic files this change touches)'
has   $b 'read the index plus only the topic files this change touches'
has   $b 'over 40 KB'
has   $b 'Splitting a spec past 40 KB'
has   $p 'listing each by file and heading'
has   $p 'reads those files only'
has   $p 'over 40 KB'
hasnt $p 'sections**, listing them by heading,'
```

- [ ] **Step 2: Run it** — `bash $S/check-task5.sh`. Expected: exit 1, with seven `MISSING` lines and one `STILL PRESENT`.

- [ ] **Step 3: Implement** — three edits:

1. **brainstorming step 1:** directly after "**read the project's living spec first**", insert ` (for a split spec: the index and the topic files this change touches)`.
2. **brainstorming, The Project Spec:** a new paragraph after the one that begins "Their shape varies by project". It opens with **A split spec** — `spec.md` as an index over `docs/<topic>.md`, per writing-specs' "Splitting a spec past 40 KB". Then it says:
   - Read the index plus only the topic files this change touches.
   - The decision row and any open point go into the topic file that owns the section, numbered from the global sequence the index names.
   - When the file being written into is over 40 KB (`wc -c`), say so in one sentence at the design gate as a separate writing-specs job, and carry on. It does not block this change.
3. **writing-plans, Keeping the Living Spec True:** in "the plan's last task updates those spec sections**, listing them by heading, alongside…", change "listing them by heading" to "listing each by file and heading (`docs/player.md` §7.2, not "the player section")". Then add:
   - that task's implementer reads those files only, never the whole spec;
   - when a file it writes into is over 40 KB, the task says so in one line, and splitting stays a separate writing-specs job.

Follow: brainstorming's existing bold lead-in paragraphs in `## The Project Spec` (e.g. "**Sections that describe state**").

- [ ] **Step 4: Verify** — `bash $S/check-task5.sh && bash .claude/hooks/flow-guard-test | tail -1`. Expected: `PASS`, then `124 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/brainstorming/SKILL.md .claude/skills/writing-plans/SKILL.md
git commit -m "brainstorming, writing-plans: split specs are read and written per topic file"
```

---

## Verification

These are controller steps after Task 5 and before the branch review. The agent definitions load from the main checkout, so the replays feed the **worktree** files to a `general-purpose` agent as its rules. The fixtures are already extracted in `$S/fixtures/`.

1. **D2 + D4 replay:** one `general-purpose` dispatch (`model: "sonnet"`). It reads the worktree's `agents/task-reviewer.md` (`## Tests`, `## Calibration`) and `agents/plan-red-team.md` (`## Rules`, `## Output`). It then classifies:
   - each finding in `review-a.md`, `review-b.md` and `review-c.md` as Important or Minor, quoting the rule it applied;
   - the verdict for `redteam-minor-only.md` and `redteam-serious.md`.

   Expected:

   | Fixture | Expected result | Historical review |
   |---|---|---|
   | `review-a` | Minor | harmonia Task 10, no RED transcript for passing tests |
   | `review-b` | Minor | forensic Task 8, RED claimed but not shown |
   | `review-c` | Important | harmonia Task 2, RED taken on the baseline where the test already passed |
   | `redteam-minor-only` | PROCEED plus the M-list | — |
   | `redteam-serious` | PROCEED WITH CHANGES | — |

   Any other result → the wording of Task 1 or Task 3 is wrong. Send a fixer to that task, then replay.
2. **D1 dry split:** one `general-purpose` dispatch (`model: "sonnet"`). It follows the worktree's `writing-specs` section "Splitting a spec past 40 KB" on `$S/fixtures/harmonia-spec.md` (302 KB) and writes to `$S/split-dry/`:
   - the new index `spec.md`;
   - `map.md`, one line per topic file with its sections and estimated bytes.

   It writes no topic files: the real split is its own harmonia session, and a full dry copy would cost the same output twice. Checks:
   - `wc -c $S/split-dry/spec.md` < 40960;
   - every `## N.` section of the source appears in exactly one `map.md` line;
   - no estimate exceeds 40 KB;
   - `grep -cE '\.(py|md|ts|js|html):[0-9]' $S/split-dry/spec.md` prints `0`.

   A failure means the skill text leaves a decision open. Fix it through a Task 4 fixer, then run the dry split again.

Record both as `flow-state task verification done "<result>"`.
