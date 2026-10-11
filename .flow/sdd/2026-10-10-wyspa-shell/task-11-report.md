# Task 11 report: Toast state

Status: DONE_WITH_CONCERNS. Commit `0101979 quickshell: notification toast`.

## Implemented
- `states/Toast.qml`: picture box (image / appIcon via `N.iconSource`, else initial on `N.appColor(app, Theme.appColors)`), title, "app · body" line, `+N` chip (N = `Notifs.series - 1`, shown when > 0), 2 px progress bar (`remaining` 1 -> 0: `toastBarDelayMs` pause, then `toastBarMs` linear; restarts on `Notifs.arrived` and when the layer becomes active). Click anywhere -> `IslandState.request("center")`.
- `IslandContent.qml`: `sources.toast`.
- `IslandState.qml`: `Connections` on `Notifs.arrived` -> `request("toast")` unless DND; `onCurrentChanged` -> `Notifs.resetSeries()` when leaving `toast` (tracked with `toastShown`; `current` is never assigned directly).
- `lib/theme.js`: `layout.toast` tokens (reference 3.4 B; `iconImage: 28` is my choice, unspecified), `palette.<mode>.accentAlternatives` (the reference's three alternatives per mode), `resolve()` -> `appColors = [accent] + alternatives` (R30: "four accent options"; follows an accent override). `Theme.qml`: `appColors` passthrough.
- `lib/notifs.js`: `iconSource(snap, iconPath)` (image, else appIcon as `/path`, `file://`, `image://` verbatim or a theme name through `iconPath`, else "").
- `Notifs.qml` NOT changed (image finding below keeps `image`).

## Deviations from the brief (for the reviewer to accept or reject)
1. Check file: brief has `wait_ms 3300` after `shot toast-series`; I use `wait_ms 5500`. Evidence: niri posts a notification for every screenshot (log: `appIcon=file:///tmp/wyspa-shots/toast-image-full.png` arriving ~2.7 s after my toast in the image run), the test instance is the daemon, so the shot's own notification restarts the 3600 ms toast; with 3300 the final `expect island current rest` failed ("got 'toast'" in that run). Cross-task trap: every future check that takes a `shot` while a toast can be up gets an extra notification and a `series` bump.
2. `onArrived`: when `request("toast")` is refused (centre, launcher, control, power up) I call `Notifs.resetSeries()`, so a toast shown later does not carry a stale `+N`. Brief says only "unless DND or current is `center`" and "reset on toast close". Note `request()` already refuses `center` (priority 4 > 3), so the brief's explicit center check is subsumed; the reset on refusal is extra logic the reviewer can reject (then drop the `if (!root.request(...)) Notifs.resetSeries()` branch).
3. Added to `11-toast.sh` a DND assertion block (not in the brief): `dnd true`, inject, `expect island current rest`, `dnd false`. It asserts no absolute `notifs` counts, so it is immune to the live-bus flake from the dispatch.

## Image finding (required open item from the Task 8 review)
Two real notifications sent with notify-send (budget 2/2), instance started by me (`qs list --all` clean after each run), DND off, temporary debug timer in Toast.qml (removed; grep for TMPDEBUG/IMGDBG is empty; it was what made `no-magic` fail in the intermediate run).
- `-h string:image-path:/tmp/wyspa-red.png` (solid red 64x64): Quickshell gives `image` = `image://icon//tmp/wyspa-red.png`; Toast `status=1` (Ready) in every 500 ms sample over ~3 s; `/tmp/wyspa-shots/toast-image.png` (the one image shot, ~2.4 s after arrival) shows the red square rendered in the icon box.
- `-h variant:image-data:(16,16,48,false,8,3,[red bytes])` (the real `qsimage` case): `image` = `image://qsimage/1/1`, `status=1`, `pictured=true` at arrival and again ~2.2 s later (t=20051, 22211, 22685).
- Conclusion: renders at arrival and while shown, so `image` stays in the snapshot (no change to `Notifs.qml`). Precision caveat: an `Image` that stays Ready only proves its loaded texture, not that the `image://qsimage/…` URL still resolves after the `Notification` object is destroyed. That suffices for the toast (loads at arrival) but NOT for the centre, which creates fresh `Image`s from old snapshots: the dangling risk is deferred to the centre task and should be tested there with a fresh `Image` (`cache: false`) on a historic snapshot. I could not test it here: the 2-notification budget was spent. If `qsimage` dangles, Toast already degrades to the initial (`pictured` requires `Image.Ready`).

## TDD evidence
RED (node): added tests to `tests/theme.test.mjs` (layout.toast, appColors x2) and `tests/notifs.test.mjs` (iconSource) before any production code. `node --test tests/`: theme tests failed with `SyntaxError: "undefined" is not valid JSON` (from `plain(undefined)`) and `TypeError: Cannot read properties of undefined (reading '0')`, i.e. they threw because the token/field is absent rather than asserting a wrong value (acceptable "feature missing" failure). The `iconSource` RED output was swallowed by my first grep and is not captured; verifiable proxy: `git show 52c1cb6:config/quickshell/lib/notifs.js | grep -c iconSource` -> 0 (function did not exist when the test was written). The later `file://` assertion has a properly captured RED: `node --test tests/notifs.test.mjs` -> `✖ iconSource(): ...`, `ℹ fail 1`, then GREEN after the regex change.
RED (smoke), run on a copy without the `shot` line to save screenshot budget (same assertions): `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh /tmp/11-red.sh` ->
```
FAIL: island.current expected 'toast' got 'rest'
FAIL: island.contentState expected 'toast' got 'rest'
ok: island.current = rest
ok: island.current = rest
```
Expected: no Toast layer, no `arrived` handler. (`qs list --all`: none running.)
GREEN: same copy after implementation: all four `ok` (toast, contentState toast, rest, rest). Final: `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh tests/smoke/11-toast.sh` -> `ok: island.current = toast`, `ok: island.contentState = toast`, `/tmp/wyspa-shots/toast-series.png`, `ok: island.current = rest`, `ok: island.current = rest`; no logged warnings. Read `toast-series.png`: green "W" tile, "drugie", "Wyspa · x", `+1` chip, bar partly run down.
Full node suite: 37/37 pass (includes `no-magic`). Non-shot smoke checks 00, 02, 04, 06, 08: all exit 0, no warnings. `qs list --all` showed "No running instances." after every run. Shots used: 2 of 3 (`toast-image`, `toast-series`); notify-send: 2 of 2.

## Files changed
`states/Toast.qml` (new), `tests/smoke/11-toast.sh` (new), `IslandContent.qml`, `IslandState.qml`, `Theme.qml`, `lib/theme.js`, `lib/notifs.js`, `tests/theme.test.mjs`, `tests/notifs.test.mjs` (all under `config/quickshell/`).

## Self-review
- Magic numbers: none (no-magic passes); weights use `Font.Medium` / `Font.DemiBold`.
- Singleton rule respected: toast trigger uses `request("toast")`; no property named `on<Capital>`.
- Toast with an empty history shows a blank snapshot (reachable only via `island open toast` in tests).

## Concerns
- `Theme.appColors` has no `Behavior`, so the app colour snaps on theme change while the rest fades.
- "app · body" renders as `"Wyspa · "` for an empty body (reference format, not special-cased).
- `iconImage: 28` (picture inside the 44 px box) is not in the reference; images are fit, not cropped to the rounded box.
- Dangling `qsimage` risk for the centre: see Image finding.
- Deviations 1 and 2 above.

## Fix round 1: series-reset assertions (Important finding)

Change: `notifs` IpcHandler gets `readonly property int series: root.series` (services/Notifs.qml); new
`tests/smoke/11-series.sh` (no `shot`, starts with `call notifs clear`, asserts `series` only):
series 1 and 2 after two injects, `series 0` after the toast times out (4500 ms wait), and a refusal case
(`island open launcher`, `expect island current launcher`, inject, `series 0`, `island close`). `11-toast.sh` untouched.

RED (file added before the property): `notifs.series expected '1' got 'Property not found.'` (all 4 series expects failed).
GREEN: `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh tests/smoke/11-series.sh` -> all 9 expects ok
(series 1, 2, 0 after close, 0 on refusal). `qs list --all`: No running instances.

Mutation checks (IslandState.qml restored byte-identical afterwards, git diff --stat shows only Notifs.qml):
- toast-close reset (line 117 call replaced by `{}`): `FAIL: notifs.series expected '0' got '2'`.
- refusal reset (line 130 call replaced by `{}`): `FAIL: notifs.series expected '0' got '1'`.
Note: with only the close reset removed, the refusal `series 0` still passes (the refusal branch resets too); each
branch is covered by its own expect, as the two runs show.

Regression: `node --test 'tests/*.test.mjs'` 37/37 pass; smoke 04-state and 08-notifs: no FAIL lines.
Shot-containing files (05a, 05b, 09, 10, 11-toast) not run, per instruction.
