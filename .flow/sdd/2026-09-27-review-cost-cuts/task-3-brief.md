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
