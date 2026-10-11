# Task 4 report — IslandState singleton + IPC (commit aef54bd)

## Implemented
- `config/quickshell/IslandState.qml` (pragma Singleton): current/output/hidden/modal/centerHeight (init Theme.geom.center.hMin)/badge/osdKind, request/close/toggle/toggleHidden/geometryFor, one `autoClose` Timer (interval from Theme.motion osd/toast/powerDone; restart on repeated request; any other request or close() stops it, so expiry only ever closes the state it was started for). `request` validates against `Object.keys(L.PRIORITY)` (own keys); `request("rest")` closes. `output` = Niri.focusedOutput on every accepted non-rest request. `IpcHandler target "island"` with open/toggle/close/hide and readable current/output/hidden/targetW/targetH. No property named `on<Capital>`.
- `shell.qml`: `Component.onCompleted: IslandState.current` (one reference, no window).
- `tests/smoke/04-state.sh`: brief's lines verbatim plus `open toString` / `toggle constructor` -> rest.

## TDD
RED: `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh tests/smoke/04-state.sh` before IslandState.qml existed -> 17 lines `FAIL: island.<prop> expected '<x>' got 'Target not found.'` (expected: no `island` IPC target).
GREEN: same command after implementing -> 17 `ok:` lines, no FAIL, log clean. Also: `node --test 'tests/*.test.mjs'` 21/21 pass; smoke 00-start (rc 0) and 02-theme still pass.
`qs list --all` after every run: "No running instances." (smoke trap's kill is async; instance was gone ~1 s later).

## Self-review / concerns
- Mutation check: removing the own-keys validation did NOT make the toString/constructor smoke lines fail, because `L.accepts` already returns false for them (`PRIORITY["toString"] >= n` is `function >= number` -> NaN -> false). So the validation is defense in depth per the instructions, and the new smoke lines pass with or without it (they guard the behaviour, not that specific line). Validation restored.
- `call` in smoke.sh never printed FAIL for the unknown target in RED (qs ipc call apparently exits 0 on "Target not found"); only `expect` lines catch it. Not changed (harness is out of scope).
- `hidden` does not affect `request` (brief silent).
