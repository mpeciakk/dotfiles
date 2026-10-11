# Task 8 report: notification service for the island

Status: DONE_WITH_CONCERNS (minor). Commit 736f319 "quickshell: notification history, groups, unread badge".

## Implemented
- `lib/notifs.js`: group, centerHeight, appColor, initial.
- `lib/theme.js`: `layout.center` tokens (hMin 170, hMax 620, pad 14, header 36, gap 10, bottom 16, groupHeader 28, card 64, cardGap 6, groupGap 12, stackPad1 7, stackPad2 14).
- `services/Notifs.qml`: history (max 50), groups, latest, unread, series, dnd, arrived, push/markRead/dismiss/dismissApp/clearAll/resetSeries, IpcHandler "notifs" (inject, dnd, clear; typed count/unread/dndOn). NotificationServer kept; popups no longer tracked.
- `IslandState.qml`: `badge: Notifs.unread > 0`.
- `tests/notifs.test.mjs`, `tests/smoke/08-notifs.sh`.

## TDD evidence
RED unit (stub lib/notifs.js returning null/0/""): `node --test tests/notifs.test.mjs` -> 5 failures, e.g. `TypeError: Cannot read properties of null (reading 'map')`, `actual: '' expected: 'F'`, `actual: 0 expected: 170`.
RED smoke (before QML change): `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh tests/smoke/08-notifs.sh`:
```
ok: island.targetW = 200
FAIL: notifs.unread expected '1' got 'Target not found.'
FAIL: island.targetW expected '252' got '200'
exit=1
```
GREEN: `node --test 'tests/*.test.mjs'` -> 30 pass, 0 fail (includes no-magic). `tests/smoke.sh tests/smoke/08-notifs.sh` -> ok targetW 200, ok unread 1, ok targetW 252, exit 0. `04-state.sh` -> all ok, exit 0. After every run `qs list --all` -> "No running instances."
Extra (temp script /tmp/notifs-extra.sh, not committed): 3 injects -> count 3, unread 3, targetW 252; dnd true -> dndOn true; clear -> count 0, unread 0, targetW 200. Instance log: only the "Signal detected" warnings (already allowed); no "could not register notification server" warning, i.e. this instance owned the D-Bus name, and Notifs is instantiated at startup via the badge binding. Timing of unread->badge: stable (300 ms wait was enough; no loosening).

## centerHeight arithmetic (hand-computed; matches reference 3.5 / R28)
(a) none -> 170. (b) 3 collapsed: shown 1, stackPad 14: listH 28+64+0+14=106; 14+36+10+106+16=182. (c) expanded: 28+192+12+0=232; 76+232=308.

## Files changed
config/quickshell: IslandState.qml, lib/theme.js, lib/notifs.js (new), services/Notifs.qml, tests/notifs.test.mjs (new), tests/smoke/08-notifs.sh (new).

## Self-review / concerns
- `layout.center` duplicates hMin/hMax from `geom.center` so `centerHeight(groups, expanded, L)` takes only `L`; a config override of `geom.center.hMin/hMax` would not reach it (Task 12 caller could pass a merged object).
- `allowed-warnings.txt` unchanged: the register warning did not appear (user's shell stopped), so I could not observe whether it is one or two lines.
- Extras beyond the brief's list: `injected` counter (negative ids for IPC snapshots), `keep()` helper clamping `unread` to history length after dismiss/clear. Dismissal reduces `unread` only via clamp.
- Old `Notifs` API (`list`, `removeItem`, `clearHistory`) removed; grep found no other QML users.
- Reference R30 palette (four accent options) is for the consumer (Task 11/12); `appColor` takes the array.
