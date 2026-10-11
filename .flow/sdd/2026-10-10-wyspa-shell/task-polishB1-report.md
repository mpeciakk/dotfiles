# polishB1 report

Commit: d07f349 `quickshell: polish launcher, osd sink gate, toast, centre image hints` (config/quickshell only).
Node: `node --test 'tests/*.test.mjs'` 215/215 (11 of them new, `tests/polish.test.mjs`). Smokes 04, 06, 08, 11-series, 15, 12, 11-toast all exit 0, no unlisted WARN/ERROR; `qs list --all` empty after each. Live shots used: 3 (15, 12, 11-toast).

## TDD evidence
RED (before any production edit): `node --test tests/polish.test.mjs` -> `ℹ pass 0 / ℹ fail 11`, all 11 new tests failed
(`storedSource` missing: `N.storedSource is not a function`; the guards fail because the code is not there yet; regex-extraction guards fail on `null[0]`, i.e. the expected construct does not exist).
GREEN: same command after the edits, and the full suite: `ℹ tests 215 / ℹ pass 215 / ℹ fail 0`.

Smoke RED attempt for item 1 (copy of 15-launcher without `shot`): the new final assertion `expect island launcherResult ""` after close already PASSED before the fix: when `active` flips off, `rows` becomes `[]` first, so the still-bound `launcherResult` takes `""`. So item 1 is not observable as a bug in the smoke; the explicit reset makes it independent of binding order. RED for item 1 is the source guard only. The smoke assertion stays as a regression check.

## Per item
1. `launcherResult` reset in `onActiveChanged` else-branch (`Launcher.qml`). Guard test + smoke assertion in 15 (see above, smoke could not go RED).
2. `ListView { onModelChanged: list.positionViewAtIndex(root.selected, ListView.Contain) }` (on the list, not `onRowsChanged`: the model reset happens when the list's model is replaced). Not drivable without a keyboard, so verified by a throwaway experiment (reverted, `grep TMP` = 0): temp Timer set `selected = 8` (contentY 384), then a rows rebuild with different content. Without the fix: `TMP y1=384 ... modelChanged y=0 ... y2=0` (reset to top reproduced). With the fix: `y1=384, y2=384`. Note: a rebuild that yields an equal array does NOT reset the view (no modelChanged), only a changed content does. Guard test pins the line.
3. `launcherMenu()`: `if (root.request("launcher")) root.launcherMenuRequest = id;`. Not testable end to end: `launcher` has the top priority (5), so `request("launcher")` never refuses today. Guard test pins the shape; smoke 15 still covers the granted path (`launcherMenu vpn` -> mode `menu`, still passes).
4. `textFormat: Text.PlainText` on the sub `Text` in Launcher. Guard test.
5. `if (row.command === "") return;` at the start of the `item` branch (nothing runs, no close, no refresh). Guard test (needs a real Enter/click on an empty-command menu row).
6. `Timer { id: osdGate ... }` (the existing startup timer gets an id) and `Connections { target: Audio; function onSinkChanged() { osdReady = false; osdGate.restart(); } }`. Not testable live: this machine has a single sink (`wpctl status`: only Arctis Nova 7), changing the real default sink would be a side effect I will not make, and Pipewire cannot be faked in the test instance. Guard test pins it. Caveat: it relies on the new sink's volume arriving after `sinkChanged` is handled (the sink's `audio` binds asynchronously via the PwObjectTracker, so very likely, but unverified without a second sink).
7. `Toast.qml`: `property int shownMore` + `Binding { when: root.more >= 0; restoreMode: Binding.RestoreNone }`, the chip uses `shownMore`. The fade-out is not readable over IPC; guard test; the shot of 11-toast shows the `+1` chip still renders through `shownMore`.
8. App line is `[appName, body].filter(s => s !== "").join(" · ")`; also covers an empty app name. Guard test; shot shows `Wyspa · x` unchanged for a non-empty body.
9. `sourceSize.width/height: root.spec.iconImage` on the toast `Image`, still synchronous (guard asserts no `asynchronous`). The same token as the Launcher's `iconImage` pattern.
10. New `lib/notifs.js` `storedSource(snap, iconPath)`: drops `image` only when it starts with `image://qsimage/`, then `iconSource`. Center cards call it with `{ image, appIcon }`. Unit test (RED: not a function) covers `image://icon/...`, file path, `file://`, `image://qsimage/` with and without appIcon fallback. A real notification carrying a non-qsimage image is not injectable over IPC (`inject` has `image: ""`), so no smoke.

## Files
`IslandState.qml`, `lib/notifs.js`, `states/Center.qml`, `states/Launcher.qml`, `states/Toast.qml`, `tests/smoke/15-launcher.sh`, new `tests/polish.test.mjs`.

## Self-review / concerns
- Most QML items are pinned only by source-grep guards (regex), which prove the construct exists, not the behaviour; reasons per item above (no pointer/keyboard/second sink/fade readback).
- Item 6 ordering caveat (above).
- Not done, adjacent: Toast summary/body `Text` and Center card texts also show external strings with the default `Text.AutoText` (rich text possible); brief item 4 named only the Launcher.
- `tests/polish.test.mjs` regexes depend on formatting of the touched QML (e.g. 4/8-space indents); a reformat will break them loudly, not silently.

## Fix round 1

Commit 3bdb0b1 "quickshell: osd sink gate inside the value handlers, centre card image sourceSize".

### IMPORTANT 1 - OSD sink gate (IslandState.qml, tests/polish.test.mjs)
- Test first: rewrote the guard "a default sink change shuts the OSD gate inside the value handlers, not after them";
  RED (`TypeError: Cannot read properties of null (reading '0')` - `sinkSettling` did not exist).
- Fix: `property var osdSink: null` and `function sinkSettling(): bool` (returns true, and shuts the gate again, when
  `Audio.sink !== osdSink`); `onVolumeChanged` / `onMutedChanged` return early on it before `showOsd`. Startup path untouched
  (osdGate timer `running: true`).
- DEVIATION from the suggestion: `onSinkChanged` is kept, reduced to `root.sinkSettling()`. Without it a sink switch that
  leaves volume and mute unchanged (0.5 -> 0.5) emits neither signal, `osdSink` stays stale, and the user's NEXT real
  volume key press would be swallowed as "settling". The call is idempotent with the handlers.
- No pure helper in lib/: the check is a single `!==`; pinned by a source guard (function shape and all three handlers).
  The signal ordering itself cannot be exercised under node or in the test instance (no second sink).
- `node --test 'tests/*.test.mjs'` -> tests 216, pass 216, fail 0.
- `10-osd.sh`: no OSD at startup (`current = rest` at 1.8 s), wpctl 2%+ raises osd, contentState osd. The unmodified smoke then
  FAILED on its last line (`island.current expected 'rest' got 'toast'`): niri's screenshot notification from the `shot osd`
  line reaches the toast (CLAUDE.md gotcha 7; the smoke has commands after the shot). Not caused by this change. Re-run as a
  /tmp copy without the `shot` line (no extra screenshot): 4x ok, last `ok: island.current = rest`. Shots for 10-osd: 1.

### IMPORTANT 2 - centre card image (states/Center.qml)
- Test first: new guard "the centre card image decodes at the icon box size, not the file's"; RED (no `sourceSize.width`).
- Fix: `sourceSize.width/height: root.spec.cardIconImage` (same token as width/height). Still synchronous.
- `12-center.sh` (1 shot): all ok, ends `ok: notifs.count = 0`.

### MINOR - CLAUDE.md trap 6
Reworded: stored snapshots drop only `image://qsimage/` (`storedSource()`), keep file-path and `image://icon` images, else `appIcon`.

### Other smokes
04-state, 06-content, 08-notifs: all ok, no FAIL. `qs list --all` -> "No running instances." after every run.

### Concern (not fixed, not on the list)
`tests/smoke/10-osd.sh` has commands after `shot osd`, so it is flaky against niri's screenshot toast (gotcha 7). Move the
shot to the end or drop the final `expect island current rest`.
