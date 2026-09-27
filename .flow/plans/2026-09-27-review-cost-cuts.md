# Review and Spec Cost Cuts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cut fix loops and context size:
- paperwork findings drop to Minor;
- no fixer after an all-Minor Approved review;
- a red-team with only minor objections says PROCEED;
- a spec past 40 KB splits into `docs/` topic files that the pipeline reads and writes one at a time.

**Architecture:** Prose changes to skills and agent definitions under `/home/m/dotfiles/.claude`, which is deployed to `~/.claude` as symlinks. No hooks or scripts change. Each task gets a grep check for the phrases it must add and remove. After Task 5, the controller replays historical reviews and red-team reports against the new rules (`## Verification`).

**Tech Stack:** Markdown skill files, agent definitions, bash and python checks.

**Spec:** none. The dotfiles have no living `spec.md`, so there is no spec-sync task either.

**Design record:** `/home/m/dotfiles/.flow/specs/2026-09-27-review-cost-cuts-design.md` (D1 spec split, D2 reviewer rubric, D3 fix loops, D4 red-team verdict). Replay fixtures: `/home/m/dotfiles/.flow/specs/2026-09-27-review-cost-cuts-evidence/` (its README gives where each fixture came from).

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

### Task 1: task-reviewer — unverifiable TDD evidence is Important, missing paperwork is Minor (D2)

**Controller:** the text is given in full, so dispatch with `model: "haiku"`.

**Files:**
- Modify: `.claude/agents/task-reviewer.md`:
  - the last paragraph of `## Tests`, which starts "Check the TDD evidence exists";
  - the living-spec paragraph in `## Part 1`, which ends "A spec that lies is worse than one that is thin.";
  - the first paragraph of `## Calibration`.

**Interfaces:** none.

- [ ] **Step 1: Write the failing check.** Save as `$S/check-task1.sh`: the preamble, then:

```bash
f=agents/task-reviewer.md
has   $f 'the reviewer can say from the diff why the test fails on BASE'
has   $f '"TDD evidence unverifiable"'
has   $f 'A test that **could not have been RED**'
has   $f 'The test is the evidence; the transcript is paperwork about it.'
has   $f 'Outside such a task, a stale citation'
has   $f 'a missing RED transcript for a test whose RED the diff explains are **Minor**'
hasnt $f 'Missing RED output, or a RED that would have failed'
```

- [ ] **Step 2: Run it.** Run `bash $S/check-task1.sh`. Expected: exit 1 with six `MISSING` lines and one `STILL PRESENT`.

- [ ] **Step 3: Implement.** Apply these three edits exactly.

1. Replace the `## Tests` paragraph that starts "Check the TDD evidence exists before trusting it." with:

```
Check the TDD evidence exists before trusting it. For every new behaviour in this
diff the report must show a RED command whose output fails for the stated reason,
then a GREEN one. A test that **could not have been RED** — it passes on BASE, or
it never reaches the code the change touches — is an **Important** finding: "TDD
evidence unsound", with the test's file:line. RED output that is missing, or a
RED that failed for an unrelated reason (import error, syntax), is **Minor** only
when the reviewer can say from the diff why the test fails on BASE: it calls a
symbol this diff adds, or asserts output a hunk at file:line introduces. Name
that reason in the finding. If you cannot, it is **Important**: "TDD evidence
unverifiable". The test is the evidence; the transcript is paperwork about it.
```

2. Append to the paragraph that ends "A spec that lies is worse than one that is thin.":

```
Outside such a task, a stale citation (a `file:line` that moved) or drift in docs
that state no behaviour is **Minor**; a doc that states wrong behaviour is not.
```

3. In `## Calibration`, replace `"Coverage could be broader" and polish are **Minor**.` with:

```
"Coverage could be broader", polish, a stale citation and a missing RED
transcript for a test whose RED the diff explains are **Minor**.
```

- [ ] **Step 4: Verify.** Run `bash $S/check-task1.sh && bash .claude/hooks/flow-guard-test | tail -1`. Expected: `PASS`, then `124 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add .claude/agents/task-reviewer.md
git commit -m "task-reviewer: missing RED transcript Minor when the diff explains it, stale citations Minor"
```

---

### Task 2: Fix loops — no fixer after an all-Minor Approved review; bounded fixes after the branch review (D3)

**Files:**
- Modify: `.claude/skills/requesting-code-review/SKILL.md`. Step 4, "Act on it", becomes the one place where the rule for branch-review fixes is written.
- Modify: `.claude/skills/subagent-driven-development/SKILL.md`:
  - loop step 7;
  - the "After the last task" paragraph;
  - `## Never`.

**Interfaces:** Produces the phrase "the re-review covers only the fix range", which lives in requesting-code-review. SDD refers to that step and does not restate the rule.

- [ ] **Step 1: Write the failing check.** Save as `$S/check-task2.sh`: the preamble, then:

```bash
s=skills/subagent-driven-development/SKILL.md; r=skills/requesting-code-review/SKILL.md
has   $r 'the re-review covers only the fix range'
has   $r 'fixbase='
has   $r 'whose brief is the finding list'
has   $r 'full suite green'
has   $r 'with no re-review'
hasnt $r 'Critical and Important findings go to ONE fix subagent with the complete list; Minor findings get recorded'
has   $s 'An Approved review whose findings are all Minor, with every ⚠️ resolved, ends the task'
has   $s 'Dispatch a fixer after an Approved task review whose findings are all Minor.'
has   $s 'requesting-code-review, step 4'
hasnt $s 'the re-review covers only the fix range'
```

- [ ] **Step 2: Run it.** Run `bash $S/check-task2.sh`. Expected: exit 1 with eight `MISSING` lines and one `STILL PRESENT`. The final `hasnt` passes already, because SDD must never gain that phrase: it guards against the rule being duplicated there.

- [ ] **Step 3: Implement.** Three edits, each covering lines of the check.

1. **requesting-code-review, step 4.** Replace its first sentence ("Critical and Important findings go to ONE fix subagent with the complete list; Minor findings get recorded, not silently dropped.") with the rule below. Keep the rest of step 4 as it is.
   - *Before any fixer.* Record the pre-fix HEAD so a compaction cannot lose it: `flow-state task branch-review started "fixbase=$(git rev-parse --short HEAD)"`. Outside a run, note it in your reply.
   - *Critical or Important present.* Those findings, plus any Minor you decide to keep, go to ONE fix subagent with the complete list. The re-review covers only the fix range (`<fixbase>..HEAD`). It is a `task-reviewer` whose brief is the finding list, handed the fixer's report. That agent already has the re-review semantics. A branch-reviewer given a two-commit diff would report every planned requirement as missing.
   - *Kept Minor findings only.* One fixer whose report shows the full suite green, with no re-review.
   - *Minor findings you do not keep.* Record them; do not drop them silently.
   - *Why.* 34 of 147 historical fixers ran after a branch review, and a full-branch re-review re-reads work that was already approved task by task.
2. **SDD, step 7.** After "Minor findings go into the ledger note and get handed to the final review to triage.", add a sentence that contains `An Approved review whose findings are all Minor, with every ⚠️ resolved, ends the task`: its Minor findings go to the ledger, never to a fixer. Why: 15 of 147 fixers ran after an Approved review.
3. **SDD, after-last-task and Never.**
   - After-last-task: after "pass it the Minor findings you accumulated.", add one sentence saying that acting on its findings follows requesting-code-review, step 4.
   - Never: add `- Dispatch a fixer after an Approved task review whose findings are all Minor.` directly after the bullet "Move to the next task with unfixed…". In that bullet, qualify "or skip the re-review after a fix" with its one exception: a Minor-only fix after the branch review (requesting-code-review, step 4).

Follow the voice SDD step 7 already has: a rule, then a short "why" backed by history.

- [ ] **Step 4: Verify.** Run `bash $S/check-task2.sh && bash .claude/hooks/flow-guard-test | tail -1`. Expected: `PASS`, then `124 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/subagent-driven-development/SKILL.md .claude/skills/requesting-code-review/SKILL.md
git commit -m "review: no fixer after all-Minor Approved, branch-review fixes re-reviewed over the fix range"
```

---

### Task 3: plan-red-team — the most severe objection decides the verdict (D4)

**Controller:** the text is given in full, so dispatch with `model: "haiku"`.

**Files:**
- Modify: `.claude/agents/plan-red-team.md`: item 3 of `## Output`.
- Modify: `.claude/skills/writing-plans/red-team.md`: `## After the pass`.

**Interfaces:** none.

- [ ] **Step 1: Write the failing check.** Save as `$S/check-task3.sh`: the preamble, then:

```bash
a=agents/plan-red-team.md; r=skills/writing-plans/red-team.md
has   $a 'Any blocking or serious objection rules out PROCEED'
has   $a 'with minor objections only, the verdict is PROCEED'
has   $r 'Branch on the most severe objection in the report, not on its label'
has   $r 'apply the minor list to the plan yourself'
has   $r 'needs a decision from the user'
has   $r 'name what changed in one line at the plan gate'
hasnt $r 'If the verdict is PROCEED with no blocking objections, say so in one line and'
```

- [ ] **Step 2: Run it.** Run `bash $S/check-task3.sh`. Expected: exit 1 with six `MISSING` lines and one `STILL PRESENT`.

- [ ] **Step 3: Implement.** Apply exactly.

In `agents/plan-red-team.md`, replace `3. One-line verdict: PROCEED / PROCEED WITH CHANGES / RETHINK` with:

```
3. One-line verdict: PROCEED / PROCEED WITH CHANGES / RETHINK. Any blocking or
   serious objection rules out PROCEED; with minor objections only, the verdict
   is PROCEED and the minor ones are listed under it as edits to apply.
```

In `skills/writing-plans/red-team.md`, under `## After the pass`, insert this paragraph first, before "Surface the ranked objections…":

```
Branch on the most severe objection in the report, not on its label — a
PROCEED carrying a serious objection, or a report with no verdict line, is
decided by the same rule. Any blocking or serious objection: surface as below.
```

Then replace the last paragraph ("If the verdict is PROCEED with no blocking objections, … Do not stage a debate the plan does not need.") with:

```
Minor objections only: apply the minor list to the plan yourself — no gate, no
debate — commit the amended plan, and name what changed in one line at the plan
gate. Skip an item you disagree with and say which and why in that line; an item
that needs a decision from the user goes to the plan gate as a question instead.
```

- [ ] **Step 4: Verify.** Run `bash $S/check-task3.sh && bash .claude/hooks/flow-guard-test | tail -1`. Expected: `PASS`, then `124 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add .claude/agents/plan-red-team.md .claude/skills/writing-plans/red-team.md
git commit -m "red-team: the most severe objection decides; minor-only gives PROCEED, applied without a gate"
```

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

## Verification

These steps are run by the controller after Task 5 and before the branch review. Agent definitions load from the main checkout, so each replay gives a `general-purpose` agent the **worktree** files as its rules. `$E` is `/home/m/dotfiles/.flow/specs/2026-09-27-review-cost-cuts-evidence`. Verdict lines are already stripped from its fixtures.

1. **D2 + D4 replay.** One `general-purpose` dispatch with `model: "sonnet"`.
   - *The rules it reads, from the worktree:* `agents/task-reviewer.md` (`## Tests`, `## Calibration`) and `agents/plan-red-team.md` (`## Rules`, `## Output`).
   - *What it classifies:* each finding in `$E/review-a.md`, `review-b.md` and `review-c.md` as Important or Minor, quoting the rule it applied. It also gives a verdict for `$E/redteam-minor-only.md` and for `redteam-serious.md`.

   Expected results:

   | Fixture | Expected |
   |---|---|
   | review-a | Minor |
   | review-b | Minor |
   | review-c | Important |
   | redteam-minor-only | PROCEED plus the M-list |
   | redteam-serious | PROCEED WITH CHANGES |

   Any other result means the wording of Task 1 or Task 3 is wrong. Send a fixer to that task, then replay.
2. **D1 dry split.** One `general-purpose` dispatch with `model: "sonnet"`.
   - *Input:* it follows the worktree's writing-specs section "Splitting a spec past 40 KB" on `git -C ~/projects/harmonia show 056c1d3:spec.md > $S/split-dry/source.md`.
   - *Output, all into `$S/split-dry/`:*
     - the index `spec.md`;
     - `map.md`, one line per topic file in the exact format `docs/<name>.md | sections: 3, 7 | decisions: D1, D5 | flag: over-limit` (omit the flag field when there is none);
     - one full topic file, the one that holds §9, since §9 is the largest section and has no `###` headings.
   - *Why only one topic file:* the real split is its own harmonia session.

   Then run this check and expect `PASS`:

```python
import re, sys, os
d = os.environ["S"] + "/split-dry/"
src = open(d + "source.md").read().splitlines(keepends=True)
sec, cur, drow = {}, None, {}
for l in src:
    m = re.match(r"## (\d+)\.", l)
    if m: cur = int(m.group(1))
    if cur is not None: sec[cur] = sec.get(cur, 0) + len(l.encode())
    m = re.match(r"\| D(\d+)[ (|]", l)
    if m: drow[int(m.group(1))] = len(l.encode())
fail, seen_s, seen_d = [], {}, {}
for line in open(d + "map.md"):
    if not line.startswith("docs/"): continue
    f = dict(p.strip().split(": ", 1) for p in line.split("|")[1:] if ": " in p)
    path = line.split("|")[0].strip()
    ss = [int(x) for x in re.findall(r"\d+", f.get("sections", ""))]
    ds = [int(x) for x in re.findall(r"\d+", f.get("decisions", ""))]
    for s in ss: seen_s[s] = seen_s.get(s, 0) + 1
    for x in ds: seen_d[x] = seen_d.get(x, 0) + 1
    size = sum(sec.get(s, 0) for s in ss) + sum(drow.get(x, 0) for x in ds)
    if size > 40960 and not (f.get("flag") == "over-limit" and len(ss) == 1):
        fail.append(f"{path}: {size} B over 40 KB, unflagged")
for s in sec:
    if s in (14, 16): continue
    if seen_s.get(s) != 1: fail.append(f"§{s} in {seen_s.get(s, 0)} files")
for x in drow:
    if seen_d.get(x) != 1: fail.append(f"D{x} in {seen_d.get(x, 0)} files")
nine = [p for p in os.listdir(d + "docs") if "## 9." in open(d + "docs/" + p).read()]
if len(nine) != 1: fail.append("no single topic file holds §9")
else:
    t = open(d + "docs/" + nine[0]).read()
    if re.search(r"\.(py|md|ts|js|html|yaml|toml):\d", t): fail.append("line-number citation left in §9 file")
if "D" not in open(d + "spec.md").read(): fail.append("index names no next free D")
print("\n".join(fail) or "PASS"); sys.exit(1 if fail else 0)
```

   Save the check as `$S/check-split.py` and run it with `S=$S python3 $S/check-split.py`. Open points are not checked mechanically, because harmonia numbers them inconsistently. Read the §9 file's open points by eye. A failure means the skill text leaves a decision open: send a fixer for Task 4, then run the split again.

Record the outcome with `flow-state task verification done "<result>"`.
