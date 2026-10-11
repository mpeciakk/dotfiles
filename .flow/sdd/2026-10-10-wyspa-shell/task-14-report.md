# Task 14 report: niri windows in the Niri service

Status: DONE. Commit 5627808 "quickshell: track niri windows".

## Implemented
- `lib/niri.js`: `reduceWindows(windows, ev)` (pure; `WindowsChanged`, `WindowOpenedOrChanged`, `WindowClosed`, `WindowFocusChanged`, `WindowFocusTimestampChanged`; any other event returns the same reference) and `sortWindows(windows)` (array, focus_timestamp desc).
- `services/Niri.qml`: `windows` (map), `readonly windowList = N.sortWindows(windows)`, `focusWindow(id)` (`niri msg action focus-window --id <id>`, never called in tests/probes). `applyEvent` feeds every event to `reduceWindows` before the workspace chain (placed first because the `WorkspaceActivated` branch has an early `return`).

## Real shapes vs brief (verified on niri 26.04 with `niri msg -j event-stream` / `windows`)
- `focus_timestamp` is `{secs, nanos}` (not a number). Sort compares secs then nanos (secs*1e9 is not exact in a double after ~104 days uptime; pinned by a test).
- Missing/null timestamp sorts last; ties are broken by id ascending (pinned in a test).
- Added `WindowFocusTimestampChanged {id, focus_timestamp}` handling (needed to keep the sort right; unknown id returns the same object). This event was not in the brief and was not seen in a 3 s stream sample; it comes from niri-ipc's Event enum (not verified live).
- `WindowFocusChanged {id}` carries `id: null` when nothing is focused (niri-ipc Option; not observed live in the sample): handled, nobody focused (test).
- `WindowOpenedOrChanged` with `is_focused: true` also clears focus on the other windows (niri does not send a separate event for the one that lost focus; test). Not in the brief.
- `WindowLayoutsChanged`, `WindowUrgencyChanged` etc. fall through to "same object" (urgency is not tracked: not needed by the launcher).
- Window `is_focused` in `WindowsChanged` is taken as sent.

## TDD evidence
RED: with `lib/niri.js` stubbed to only `.pragma library`:
`node --test tests/niri.test.mjs` -> 10 tests failed, each `TypeError: N.reduceWindows is not a function` / `N.sortWindows is not a function` (feature missing, as expected).
GREEN: after implementing, `node --test tests/niri.test.mjs` -> tests 10, pass 10, fail 0.
Full suite: `node --test 'tests/*.test.mjs'` -> tests 79, pass 79, fail 0.

## Live proof (no niri actions)
Temporary `Timer` in shell.qml (removed; `git status` shows no shell.qml change) logged after 2 s:
`windows=6 list=6`, order of `app_id:id:is_focused` = mpv:32:true, kitty:4, kitty:37, kitty:35, legcord:36, kitty:22 (all false except the first).
Reference: `niri msg -j windows` gives 6 windows; sorted by (secs, nanos) desc it is the identical sequence. No titles recorded here.

## Smoke
`QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh tests/smoke/00-start.sh` exit 0, `04-state.sh` exit 0 (17 `ok` lines), no warnings; `qs list --all` -> "No running instances." after every run (including the probe run). Only the smoke script's own `qs kill -p <dir>` was used.

## Files
- Created: `config/quickshell/lib/niri.js`, `config/quickshell/tests/niri.test.mjs`
- Modified: `config/quickshell/services/Niri.qml`

## Concerns
- `windowList` is re-sorted on every window event (including title changes); trivial at this scale.
- `windowList` is a binding over `windows`; any later consumer that mutates entries in place would not trigger updates (reducer always returns new objects, so fine).
- Not covered live: `WindowFocusTimestampChanged` and `focusWindow` (the latter deliberately, since it changes live focus).
