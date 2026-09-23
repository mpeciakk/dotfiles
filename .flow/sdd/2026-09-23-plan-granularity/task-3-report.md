# Task 3 Report: Implementation the brief leaves open — implementer and task-reviewer

## What was implemented

Inserted two paragraphs into agent files describing how implementers and reviewers handle specifications that provide approaches rather than concrete code:

1. **In `.claude/agents/implementer.md`**: Added guidance that when a brief gives an approach instead of code, the implementation is the implementer's responsibility, but they must follow the pattern named and keep tests, interfaces, and values verbatim from the brief.

2. **In `.claude/agents/task-reviewer.md`**: Added guidance that when the brief provides an approach rather than code, reviewers should judge on quality and fidelity to the pattern the brief names, not on whether the implementation matches their personal preferences.

## Test-Driven Development Evidence

### RED (Failing Test)
```bash
$ bash /tmp/claude-1000/-home-m-dotfiles--claude/d2fa4c06-9a89-4a4c-9ce4-5cb1963cfa32/scratchpad/check-task3.sh
```

**Output:**
```
MISSING in agents/implementer.md: Where the brief gives an approach instead of code, the implementation is yours
MISSING in agents/task-reviewer.md: "not how I would have done it" is not a finding
```

**Exit code:** 1

**Why this failed:** The check script searches for two specific strings in the agent files. Both strings were missing because the paragraphs had not yet been inserted.

### GREEN (Passing Test)
```bash
$ bash /tmp/claude-1000/-home-m-dotfiles--claude/d2fa4c06-9a89-4a4c-9ce4-5cb1963cfa32/scratchpad/check-task3.sh
```

**Output:**
```
PASS
```

**Exit code:** 0

After inserting both paragraphs, the check script passes because both required strings are now present in their respective files.

## Regression Test Suite
```bash
$ bash .claude/hooks/flow-guard-test | tail -1
```

**Output:**
```
124 passed, 0 failed
```

All regression tests pass, confirming no existing functionality was broken.

## Files Changed

- `.claude/agents/implementer.md` (lines 37-42): Added paragraph about implementing approaches the brief provides
- `.claude/agents/task-reviewer.md` (lines 79-82): Added paragraph about reviewing approach implementations

## Commit

```
44ece24 agents: implementation the brief leaves open is the implementer's, judged on quality
```

## Self-Review

- **Complete?** Yes. Both required paragraphs were inserted exactly as specified in the brief, at the correct locations.
- **Clean?** Yes. The text follows the existing prose style and line wrapping conventions of the files (~80 columns).
- **Disciplined?** Yes. Only the two paragraphs specified in the brief were added; no other changes were made.
- **Tested?** Yes. The failing test (RED) was created and ran first, then the implementation was applied (GREEN), and both the specific check and the full regression suite pass.

## Concerns

None. The task is complete and correct.
