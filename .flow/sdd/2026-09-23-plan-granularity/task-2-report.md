# Task 2 Report: Implementer on Sonnet 5, Haiku 4.5 as the rule for surgical tasks

## What was implemented

Modified four files to establish Sonnet 5 as the default model for the implementer agent, with Haiku 4.5 as the override rule for small, surgical, or fully-specified tasks. The changes propagate this rule through:

1. `.claude/agents/implementer.md` — frontmatter model change
2. `.claude/skills/subagent-driven-development/SKILL.md` — dispatch guidance (2 locations)
3. `.claude/skills/development-workflow/SKILL.md` — model table and dispatch instructions (3 locations)
4. `.claude/README.md` — model & effort section + new paragraph on plan structure

## TDD Evidence

### RED: Failing Test

```bash
$ bash /tmp/claude-1000/-home-m-dotfiles--claude/d2fa4c06-9a89-4a4c-9ce4-5cb1963cfa32/scratchpad/check-task2.sh
```

**Output (exit 1):**
```
MISSING in agents/implementer.md: model: sonnet
MISSING in agents/implementer.md: effort: high
STILL PRESENT in agents/implementer.md: model: haiku
MISSING in skills/subagent-driven-development/SKILL.md: Haiku is the rule, not the exception
MISSING in skills/subagent-driven-development/SKILL.md: `haiku` for a small, surgical or fully-specified implementer task
MISSING in skills/development-workflow/SKILL.md: | `implementer` | agent definition | Sonnet 5 · high — override to Haiku 4.5 for every small, surgical or fully-specified task (subagent-driven-development, step 3) |
MISSING in skills/development-workflow/SKILL.md: dispatched with `model: "haiku"`
STILL PRESENT in skills/development-workflow/SKILL.md: only to override the definition for one case
MISSING in skills/subagent-driven-development/SKILL.md: model=haiku
MISSING in README.md: overridden to **Haiku 4.5** for small, surgical or
```

**Why this failure was expected:** The old definitions had Haiku 4.5 as the default for implementer, with no effort setting and no documented rule for when to override. The test correctly identified all ten missing phrases that define the new rule structure.

### GREEN: Passing Test

```bash
$ bash /tmp/claude-1000/-home-m-dotfiles--claude/d2fa4c06-9a89-4a4c-9ce4-5cb1963cfa32/scratchpad/check-task2.sh && echo "Test passed"
```

**Output (exit 0):**
```
PASS
Test passed
```

All ten required strings are now present and the previous problematic phrase is removed.

### Regression Suite

```bash
$ bash .claude/hooks/flow-guard-test | tail -1
124 passed, 0 failed
```

All flow guard tests pass, confirming no regressions were introduced.

## Files Changed

- `.claude/agents/implementer.md` — changed frontmatter from `model: haiku` to `model: sonnet` + `effort: high`
- `.claude/skills/subagent-driven-development/SKILL.md` — expanded step 3 dispatch guidance and updated Dispatching section model guidance
- `.claude/skills/development-workflow/SKILL.md` — updated model & effort section (line 87-88), model table (line 93), and Small Lane step 5
- `.claude/README.md` — updated Model & effort section and added new paragraph on plan structure

## Commit

Commit: `5c68fef` — "implementer: Sonnet 5 by default, Haiku 4.5 as the rule for surgical tasks"

## Self-Review

**Complete?** Yes — all six replacements from the brief applied exactly as specified.

**Clean?** Yes — surgical edits only; no rewording of neighboring sections. All prose maintains existing voice and formatting.

**Disciplined?** Yes — only the named passages changed; no speculative features or unrequested refactoring.

**Tested?** Yes — RED test failed with exactly ten expected failures; GREEN test passed; regression suite clean at 124/124 tests passing.

## Concerns

None. The changes are minimal, targeted, and fully validated by both the custom test and the regression suite.

---

# Branch-Review Findings Fixed

Two findings from whole-branch review applied; user decided finding 1 (narrow Haiku rule).

## Findings Applied

### Finding 1: Haiku rule narrowed (user decision)

**Changes:** Replaced "fully specified" with "paste-ready" across 4 locations, adding explicit mention that "decision code in a brief stays on Sonnet".

1. `.claude/skills/subagent-driven-development/SKILL.md:99-105` (step 3) — replaced text about "fully specified" with "paste-ready" and clarified decision code handling
2. `.claude/skills/subagent-driven-development/SKILL.md:193-194` (Dispatching section) — replaced "fully-specified" with "paste-ready"
3. `.claude/skills/development-workflow/SKILL.md:93` (implementer row) — replaced "fully-specified" with "paste-ready" and added decision code note
4. `.claude/README.md:36-37` (Model & effort) — replaced "fully-specified" with "paste-ready (decision code stays on Sonnet)"

### Finding 2: Model recorded with the base, in one ledger call

**Changes:** Updated step 2 (record base) to also record model in a single ledger call, eliminating the risk of separate calls erasing the `base=` value.

1. `.claude/skills/subagent-driven-development/SKILL.md:90-97` (step 2) — expanded documentation to show recording both `base` and `model` in one command, with explanation of why this matters (avoiding erasure on separate calls)

## Verification

### Check Script (RED → PASS)

**RED state (before fixes):**
```bash
$ bash /tmp/check.sh
# Exit 1: 10 violations detected
# - Missing: flow-state task N started "base=$BASE model=<haiku|sonnet>"
# - Missing: a second `task N` call replaces the first and drops `base=`
# - Still present: Record the model in the ledger note
# - Still present: fully-specified (2 occurrences)
# - Missing: decision code in a brief stays on Sonnet
# - Missing: paste-ready tasks (decision code stays on Sonnet)
```

**PASS state (after fixes):**
```bash
$ bash /tmp/check.sh
PASS
```

All required strings present, no prohibited strings remain.

### Regression Test

```bash
$ bash .claude/hooks/flow-guard-test | tail -1
124 passed, 0 failed
```

All tests passing, no regressions introduced.

## Commit

Commit: `e9fc07b` — "sdd: decision code stays on Sonnet; model recorded with the base"

Applies exact replacement text from branch-review-fix.md findings, with no adjacent changes.

## Files Modified

- `.claude/skills/subagent-driven-development/SKILL.md` — step 2 and step 3 guidance
- `.claude/skills/development-workflow/SKILL.md` — model table row
- `.claude/README.md` — model & effort section
