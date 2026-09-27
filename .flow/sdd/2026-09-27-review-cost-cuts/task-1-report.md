# Task 1 Report: task-reviewer

## Summary

Implemented prose changes to `.claude/agents/task-reviewer.md` to clarify TDD evidence evaluation and add guidance on stale citations and missing RED transcripts.

## TDD Evidence

**RED (failing test):**
```bash
$ bash /tmp/claude-1000/-home-m-dotfiles--claude/5f991275-cf7e-4ff1-863c-1e81c88f255f/scratchpad/check-task1.sh
Exit code 1
MISSING in agents/task-reviewer.md: the reviewer can say from the diff why the test fails on BASE
MISSING in agents/task-reviewer.md: "TDD evidence unverifiable"
MISSING in agents/task-reviewer.md: A test that **could not have been RED**
MISSING in agents/task-reviewer.md: The test is the evidence; the transcript is paperwork about it.
MISSING in agents/task-reviewer.md: Outside such a task, a stale citation
MISSING in agents/task-reviewer.md: a missing RED transcript for a test whose RED the diff explains are **Minor**
STILL PRESENT in agents/task-reviewer.md: Missing RED output, or a RED that would have failed
```

Expected failure: the new text blocks are not yet in the file, and the old paragraph about TDD evidence is still present. Six `MISSING` lines and one `STILL PRESENT` as documented in the brief.

**GREEN (passing test):**
```bash
$ bash /tmp/claude-1000/-home-m-dotfiles--claude/5f991275-cf7e-4ff1-863c-1e81c88f255f/scratchpad/check-task1.sh
PASS
```

## Changes

Three surgical edits made to `.claude/agents/task-reviewer.md`:

1. **Tests section (lines 61-70):** Replaced the paragraph starting "Check the TDD evidence exists before trusting it." with expanded text that distinguishes between:
   - Tests that could not have been RED (Important finding: "TDD evidence unsound")
   - RED output missing/failed for unrelated reason (Minor when diff explains why, Important otherwise: "TDD evidence unverifiable")
   - Clarification that the test is evidence, transcript is paperwork

2. **Part 1 section (lines 96-97):** Appended paragraph on stale citations and documentation drift:
   - Stale citations (moved `file:line`) and drift in docs with no stated behaviour are Minor
   - Docs stating wrong behaviour are not Minor

3. **Calibration section (lines 123-124):** Replaced the line about Minor findings to include:
   - Previous: "Coverage could be broader" and polish
   - Updated: "Coverage could be broader", polish, stale citation, and missing RED transcript (when diff explains it)

## Test Results

- Check script: PASS
- Full suite: 124 passed, 0 failed

## Commits

```
c772ea2 task-reviewer: missing RED transcript Minor when the diff explains it, stale citations Minor
```

## Self-Review

**Complete?** All three edits applied exactly as specified in brief.

**Clean?** Surgical changes only - no extra modifications, existing voice and line wrapping preserved (~80 columns per global constraints).

**Disciplined?** Changes trace directly to brief requirements. No speculative edits or refactoring.

**Tested?** Check script written first (RED), then code changed (GREEN), full suite passes.

## Concerns

None. All requirements met, tests pass, commit includes proper attribution.
