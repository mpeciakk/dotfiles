# Task 6 brief — define RETHINK (D4a)

Added after Verification, approved by the user on 2026-09-27 (pc). Not in the
plan file; this brief is the single source of requirements.

## Global Constraints

- Edit only `.claude/agents/plan-red-team.md` and
  `.flow/specs/2026-09-27-review-cost-cuts-design.md` of the worktree you were
  given (the second is the one exception to "only under `.claude/`" for this
  task). Never edit through `~/.claude/…` or `/home/m/dotfiles/.flow/…` paths:
  those are the main checkout, not your worktree.
- Skill and agent prose is English. Keep each file's existing voice, heading
  style and line wrapping (~80 columns).
- Surgical: change only the passages named below.
- Check scripts live in
  `/tmp/claude-1000/-home-m-dotfiles--claude/5f991275-cf7e-4ff1-863c-1e81c88f255f/scratchpad/`
  (`$S`), never in the repo.
- After the task, `bash .claude/hooks/flow-guard-test | tail -1` still prints
  `124 passed, 0 failed`. The suite includes a wall-clock assertion, so a
  failure caused only by latency gets one re-run before it counts.

---

### Task 6: RETHINK vs PROCEED WITH CHANGES

**Files:**
- Modify: `.claude/agents/plan-red-team.md` — `## Output`, item 3
- Modify: `.flow/specs/2026-09-27-review-cost-cuts-design.md` — new section
  after `## D4 — Red-team verdict`'s **Chosen** paragraph, before
  `**Out of scope:**`

- [ ] **Step 1: Write the check** — save as `$S/check-task6.sh`:

```bash
#!/usr/bin/env bash
cd "$(git rev-parse --show-toplevel)/.claude"; fail=0
flat() { tr '\n' ' ' < "$1" | tr -s ' '; }
has()   { flat "$1" | grep -qiF -- "$2" || { echo "MISSING in $1: $2"; fail=1; }; }
hasnt() { ! flat "$1" | grep -qiF -- "$2" || { echo "STILL PRESENT in $1: $2"; fail=1; }; }
r=agents/plan-red-team.md
d=../.flow/specs/2026-09-27-review-cost-cuts-design.md
has $r 'the minor ones are listed under it as edits to apply. RETHINK when fixing a blocking objection means a different approach, not edits to this plan; otherwise PROCEED WITH CHANGES.'
has $d '## D4a — RETHINK vs PROCEED WITH CHANGES'
has $d 'plan-red-team never defined RETHINK'
[ $fail = 0 ] && echo PASS || exit 1
```

- [ ] **Step 2: Run it, expect RED:** three `MISSING` lines, exit 1.

- [ ] **Step 3: Implement**

In `plan-red-team.md` item 3, append after "…listed under it as edits to
apply." (rewrap to ~80 columns, keeping the item's 3-space continuation
indent):

> RETHINK when fixing a blocking objection means a different approach, not
> edits to this plan; otherwise PROCEED WITH CHANGES.

In the design record, insert this section (a blank line before and after):

```markdown
## D4a — RETHINK vs PROCEED WITH CHANGES

**Chosen:** RETHINK when fixing a blocking objection means a different approach,
not edits to this plan; otherwise PROCEED WITH CHANGES. Added after the
Verification replay: with D4 in place a serious-only report could not be given
either verdict, because plan-red-team never defined RETHINK.

**Rejected:** leaving it for a separate lane. D4 is what exposed the gap, and
closing it costs one sentence.
```

The design record's existing `**Out of scope:**` block belongs to the whole
record; keep it after the new section.

- [ ] **Step 4: Run the check, expect PASS;** run flow-guard-test.

- [ ] **Step 5: Commit** both files:
  `red-team: RETHINK only when a blocking fix needs a different approach`
