# Task 9 report: Rest state

Commit: cbde96f quickshell: rest state (workspaces, clock, music, badge)

## Implemented
- `states/Rest.qml`: workspace dots for this output (active pill 14x5 accent, others 5x5 `dotInactive`, animated width/colour via `motion.bgColorMs`), mono clock 13 px / Medium, 3-bar equaliser (visible and animating only while `Players.active?.isPlaying` and the layer is active; bars share one 900 ms InOutQuad cycle with phase offsets 0/-300/-600 ms, realised as a start pause of `(eqMs + delay) % eqMs`), badge pill (`accentSoft`, `bell` or `moon` when DND, mono 11 count = `Notifs.history.length`, only when `Notifs.unread > 0`). Click on the badge -> `IslandState.request("center")`, click elsewhere -> `request("control")` (plain MouseAreas, enabled only while the layer is active; no modal handling touched).
- `lib/theme.js`: `layout.rest` tokens (no literals in QML); node assertion in `tests/theme.test.mjs`.
- `IslandContent.qml`: `sources` = `{ rest: "states/Rest.qml" }` (only change).
- `IslandState.qml`: `restLoadedByOutput`, `reportRest(output, loaded)`, and IPC `readonly property bool restLoaded` (focused output). Rest calls `reportRest` from `onReadyChanged` (`ready = active && output !== ""`). This is the strengthened check the controller asked for.
- `tests/smoke/09-rest.sh`: the brief's three lines plus `expect island restLoaded true` plus a layered-enter-duration check (below).

## TDD evidence
RED 1 (node): `node --test tests/theme.test.mjs` -> `pass 11 / fail 1` (layout.rest undefined: `T.defaults.layout.rest` is undefined, `plain(undefined)` fails) -- expected, token not yet added. GREEN after adding tokens: `pass 12 / fail 0`.

RED 2 (smoke, before any state code): `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh tests/smoke/09-rest.sh`
```
ok: island.contentState = rest
FAIL: island.restLoaded expected 'true' got 'Property not found.'
```
and `rest.png` showed an empty pill (shot 1). The `contentState = rest` line passing on an empty host confirms the controller's remark that the brief's own check proves nothing; `restLoaded` is what fails.

GREEN: `node --test 'tests/*.test.mjs'` -> tests 31, pass 31, fail 0 (incl. no-magic). Smoke:
```
/tmp/wyspa-shots/rest.png
ok: island.contentState = rest
ok: island.restLoaded = true
ok: island.contentState = 
ok: island.contentState = rest
```
No log warnings/errors; `qs list --all` -> "No running instances." after every run (also after the debug runs).

Screenshots (3 of 3 used): `rest.png` (shot 1 RED, shot 2 GREEN) and `rest-badge.png` (shot 3: `call notifs dnd true; call notifs inject test hello x`, targetW 252 confirmed).
- GREEN: 200 px pill, ten workspace dots on the focused output (the user's niri has ten), second one the accent pill, others small dim dots, clock "21:54" in mono, content centred, no equaliser (nothing playing), no badge.
- Badge variant: same dots + clock, plus a pill at the right with a crescent moon icon (DND) and "1", accent on a faint accent background, island 252 px wide, everything fits and stays centred.
- Not verified live: equaliser (no player was playing; I did not start one on the user's session) and the bell variant; both are the same code path. Click handlers not exercised (no way to click through IPC; also `control`/`center` have no layers yet).

## The stale `enterTimer.interval` question (Task 6 reviewer's warning): NOT a bug
I first saw `console.log` inside `onTargetChanged` print the OLD target's `enterMs` (e.g. target launcher -> 440, target rest -> 380) and wrote a timing smoke that failed, then rewrote `IslandContent` to compute the interval in the handler. That "RED" was bogus: it failed with the fixed code as well (the reads landed ~480 ms after, because `qs ipc call` alone takes ~50 ms and each `prop get` ~50 ms). I then built an unambiguous test (stretch `island.motion.enterScaleMs` to 1500 through the temp config so a layered enter lasts 1620 ms vs 380 ms layerless) and ran it against the ORIGINAL `IslandContent` code (HEAD + only the `sources` line): it passed (`contentState` is "" at ~1.5 s, "rest" at ~2.6 s). So the Timer picks up the updated `interval` binding after the handler (setting `interval` on a running Quick Timer re-arms it) and the logged value was just handler-time staleness. I reverted the rewrite: `IslandContent.qml` differs from HEAD only by the `sources` entry; no permitted out-of-brief edit was kept. The stretched-scale check stays in `09-rest.sh` as a characterisation test (it was green with and without the rewrite, so it is not a RED-then-GREEN pair), asserting that a layered enter really lasts scale delay + duration.

## Findings useful for later tasks
- `Icon` cannot be used unqualified from `states/`: with `import "../components"` Qt 6.12 reports `Icon is not a type` (a built-in `Icon`/`icon` type shadows it) and the whole Rest layer fails to load. Use `import "../components" as Components` and `Components.Icon { ... }` (works, no warnings). Every later state that draws icons needs this.
- `Icon` has no stroke property (always `Theme.sizes.iconStroke` 1.6); reference 3.1 says stroke 2 for the badge bell/moon. Left at 1.6, not in the brief.
- Badge count shows `Notifs.history.length` (reference: "total notifications"), the badge is shown by `Notifs.unread > 0`. If the intended count is unread, it is a one-token change in Rest.qml.

## Files changed
config/quickshell: `states/Rest.qml` (new), `tests/smoke/09-rest.sh` (new), `IslandContent.qml`, `IslandState.qml`, `lib/theme.js`, `tests/theme.test.mjs`.

## Self-review / concerns
- No numeric/colour literals beyond 0/1/2 (no-magic green); `/ 2` and `2 *` only.
- Reduced motion is not applied to the dot animations or the equaliser (R25 text covers only the layer crossfade; the brief did not ask).
- `restLoaded` adds state to `IslandState` purely so a test can see the layer; small but test-driven.
- The new smoke segment rewrites `$CFG` (allowed, same pattern as 05b) and takes ~3.5 s.

## Fix round 1 (review of Task 9)
- **Important, badge count:** `states/Rest.qml` text `Notifs.history.length` -> `Notifs.unread` (visibility and count now use the same source, as does `IslandState.badge`). Evidence: `09-rest.sh` now does `notifs dnd true`, two `notifs inject a x y`, `expect notifs unread 2`, then `shot rest`; the PNG (`/tmp/wyspa-shots/rest.png`, read) shows the moon icon and "2" in the badge pill. Output: `ok: notifs.unread = 2`, `ok: island.restLoaded = true`, `ok: island.contentState = rest` (all expects ok, no log warnings). Limit, stated plainly: the discriminating case (some read + 1 new => "1" vs "6") cannot be produced before Task 12 (no markRead/open-center IPC), so the fix rests on code reading + R30; with only unread items, history.length == unread == 2 and the shot would also pass on the old code. 1 live shot used.
- **Minor, comment:** `restLoaded` comments in `Rest.qml` and `IslandState.qml` now say "loaded and lit on its output", true from enter start, false when the island leaves rest. IPC property not renamed.
- `node --test 'tests/*.test.mjs'`: 31/31 pass. `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh tests/smoke/09-rest.sh`: passes. `qs list --all` -> "No running instances."
