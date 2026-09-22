# Task 2 Report: Wire `prompt-context` into `.claude/settings.json`

## Summary

Successfully wired the `prompt-context` hook into `.claude/settings.json` following TDD discipline:
- Added 5 new assertions to `.claude/hooks/prompt-context-test` to verify the wiring
- Modified `.claude/settings.json` to point `UserPromptSubmit` to `prompt-context` (replacing `timestamp-injector`)
- Added `prompt-context` as a third hook in the `SubagentStart` entry (preserving existing `flow-context` and `cbm-subagent-reminder`)
- All 18 test assertions passing (13 from Task 1 + 5 new wiring assertions)

## Implementation Details

### Changes Made

1. **`.claude/hooks/prompt-context-test`**: Appended wiring test section before the final summary line
   - Added `wired()` helper function to check if a hook is registered in settings.json
   - Added 5 new assertions:
     - UserPromptSubmit runs prompt-context
     - SubagentStart runs prompt-context
     - SubagentStart still runs flow-context (catches array replacement bug)
     - SubagentStart still runs cbm-subagent-reminder (catches array replacement bug)
     - No reference to the old hook name remains

2. **`.claude/settings.json`**: Two surgical edits
   - Line 55: Changed `"command": "~/.claude/hooks/timestamp-injector"` to `"command": "~/.claude/hooks/prompt-context"`
   - Lines 127-132: Appended third hook to SubagentStart array:
     ```json
     {
       "type": "command",
       "command": "~/.claude/hooks/prompt-context",
       "timeout": 5
     }
     ```

### Test Results

**RED Phase - Initial Failure (Expected)**
```
15 passed, 3 failed
- UserPromptSubmit does not run prompt-context (FAIL)
- SubagentStart does not run prompt-context (FAIL)  
- settings.json still references the old hook name (FAIL)
- SubagentStart still runs flow-context (PASS - already wired)
- SubagentStart still runs cbm-subagent-reminder (PASS - already wired)
```

**GREEN Phase - After Implementation**
```
18 passed, 0 failed
- All assertions passing
- No regressions in existing Task 1 assertions
```

### Validation

- JSON validity: `json ok` ✓
- Git commit: `5577b1b feat: run prompt-context on every prompt and subagent start` ✓
- Branch state: `worktree-feat+host-context` ✓

## Test Evidence

### RED Command (Initial failure)
```bash
cd /home/m/dotfiles/.claude/worktrees/feat+host-context && bash .claude/hooks/prompt-context-test 2>&1
```
**Output**: 15 passed, 3 failed (exit code 1)

**Failure reasons**:
- `UserPromptSubmit` still pointed to `timestamp-injector`, not `prompt-context`
- `SubagentStart` had no `prompt-context` hook entry
- `grep -q timestamp-injector` found the old hook name in settings.json

### GREEN Command (After implementation)  
```bash
cd /home/m/dotfiles/.claude/worktrees/feat+host-context && bash .claude/hooks/prompt-context-test 2>&1
```
**Output**: 18 passed, 0 failed (exit code 0)

**All assertions passing**, including:
- The two assertions about existing hooks still being present in SubagentStart (this ensures the array was appended to, not replaced)
- All 13 original Task 1 assertions remain green

## Files Changed

- `.claude/settings.json`: 2 edits (1 hook name change, 1 array append)
- `.claude/hooks/prompt-context-test`: 1 edit (test section append before summary)

## Self-Review

✓ **Complete**: All requirements from brief followed in order (Steps 1-7)
✓ **Clean**: No unnecessary changes; only the two settings.json entries modified
✓ **Disciplined**: Test-first approach; red before green; no refactoring beyond scope
✓ **Tested**: All 18 assertions passing; JSON validity verified; commit successful
✓ **Surgical edits**: Settings.json not reformatted; only the required entries touched
✓ **Append not replace**: Two assertions specifically catch if SubagentStart array was replaced instead of appended to
✓ **No new dependencies**: Uses only the `wired()` helper function defined in the test

## Expected Post-Merge Behavior

As noted in the brief, this session and any subagent will log hook-not-found errors on every prompt and subagent start because `~/.claude/hooks/prompt-context` does not exist until the branch merges and `dotter deploy` runs. This is expected and documented behavior, not a regression.

## Concerns

None. The implementation is complete, tested, and ready.
