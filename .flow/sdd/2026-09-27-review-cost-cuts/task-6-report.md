# Task 6 Report — Define RETHINK in plan-red-team (D4a)

## What was implemented

Added the definition of RETHINK verdict to the plan-red-team agent and documented the decision in the design record.

### Changes

1. **`.claude/agents/plan-red-team.md`** — Updated item 3 in the `## Output` section to define RETHINK:
   - Appended: "RETHINK when fixing a blocking objection means a different approach, not edits to this plan; otherwise PROCEED WITH CHANGES."
   - Rewrapped to ~80 columns with proper 3-space continuation indent

2. **`.flow/specs/2026-09-27-review-cost-cuts-design.md`** — Added new decision record section D4a:
   - New section `## D4a — RETHINK vs PROCEED WITH CHANGES`
   - **Chosen** paragraph explaining the definition and why it was added
   - **Rejected** paragraph explaining why not handled separately
   - Placed after D4's chosen paragraph and before the Out of scope block

## TDD Evidence

### RED Command and Output

```bash
cd /home/m/dotfiles/.claude/worktrees/feat+review-cost-cuts && \
  bash /tmp/claude-1000/-home-m-dotfiles--claude/5f991275-cf7e-4ff1-863c-1e81c88f255f/scratchpad/check-task6.sh
```

**Expected failure (exit 1) with three MISSING messages:**

```
MISSING in agents/plan-red-team.md: the minor ones are listed under it as edits to apply. RETHINK when fixing a blocking objection means a different approach, not edits to this plan; otherwise PROCEED WITH CHANGES.
MISSING in ../.flow/specs/2026-09-27-review-cost-cuts-design.md: ## D4a — RETHINK vs PROCEED WITH CHANGES
MISSING in ../.flow/specs/2026-09-27-review-cost-cuts-design.md: plan-red-team never defined RETHINK
```

**Why this failure was expected:** The required text was not yet in either file.

### GREEN Command and Output

After implementing the changes, the check passed:

```bash
cd /home/m/dotfiles/.claude/worktrees/feat+review-cost-cuts && \
  bash /tmp/claude-1000/-home-m-dotfiles--claude/5f991275-cf7e-4ff1-863c-1e81c88f255f/scratchpad/check-task6.sh
```

**Output:**
```
PASS
```

Exit code 0 — all assertions satisfied.

## Test Results

### Check script verification

- RED phase: 3 assertions failed as expected (all three MISSING conditions triggered)
- GREEN phase: all 3 assertions passed (PASS exit 0)

### Flow guard test

Ran after implementation to verify no regression:

```bash
bash .claude/hooks/flow-guard-test | tail -1
```

**Result:**
```
124 passed, 0 failed
```

All existing tests remain passing.

## Files changed

- `.claude/agents/plan-red-team.md` — 4 lines added to item 3
- `.flow/specs/2026-09-27-review-cost-cuts-design.md` — 8 lines added (new D4a section)

Commit: `9484a9b` — "red-team: RETHINK only when a blocking fix needs a different approach"

## Self-review

### Completeness
- [x] RETHINK definition added to plan-red-team.md item 3
- [x] Decision record D4a added to design spec
- [x] Proper spacing and formatting (blank lines before/after section)
- [x] Text matches brief requirements exactly
- [x] Line wrapping respects ~80 column limit with 3-space indent

### Correctness
- [x] Both assertions in the check script pass
- [x] Flow guard test still passes (124 passed, 0 failed)
- [x] Commit message follows brief specification
- [x] Only the two required files were modified
- [x] No unintended changes to worktree state

### Code discipline
- [x] Surgical changes only — no reformatting or adjacent code modification
- [x] English prose preserved — existing voice and style maintained
- [x] Commit attribution line included correctly

## Concerns

None. The implementation is minimal, surgical, and all tests pass.
