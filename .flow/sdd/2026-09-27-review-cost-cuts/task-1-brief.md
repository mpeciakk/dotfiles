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
