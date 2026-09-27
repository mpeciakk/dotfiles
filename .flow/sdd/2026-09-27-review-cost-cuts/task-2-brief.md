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
