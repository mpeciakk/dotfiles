# Task 16 report: Control panel

Status: DONE_WITH_CONCERNS. Commit `d8e337d quickshell: control panel` (amended once to rename an id, see below).

## Implemented
- `states/Control.qml`: header (clock 44 px mono, DemiBold, letter-spacing = `clockLetterEm * clockFont` token; weekday + day/month right-aligned), Wi-Fi / Bluetooth tile row, sliders card (volume, brightness; `Theme.track` / `Theme.sliderFill`), 3 round toggles (Skupienie = `Notifs.dnd`, Motyw = `Theme.setMode(dark<->light)`, Zasilanie = `IslandState.request("power")`) centred in a 4-column grid (R24), mini player. Inline components `Tile`, `SliderRow`, `RoundToggle`.
- `components/MiniPlayer.qml`: `property var player`; art (bounded `sourceSize`, async, rounded via MultiEffect mask), title/artist (`Text.PlainText`, elided), prev / play-pause / next.
- `lib/theme.js`: `layout.control`, `layout.miniPlayer` (with node assertions in `tests/theme.test.mjs`).
- `IslandContent.qml`: `sources.control`.
- `services/Time.qml`: `weekdayStr`, `dayMonthStr` (Polish locale `pl_PL`, independent of session locale).
- `tests/smoke/16-control.sh`: the brief's lines verbatim, plus `expect island current/targetW/targetH` and `expect theme mode light`.
- Hidden-when-missing: Wi-Fi tile unless `Network.available`; Bluetooth tile unless `Bluetooth.defaultAdapter` (null-safe `?.`); brightness slider unless `Brightness.available`; mini player unless `Players.hasPlayer`; tile row `visible` = either tile visible, so with both hidden the Column drops the row and its gap. Content is a `Column` anchored top, so the island stays 440 tall.

## Test-mode choke points (code-read, never executed)
One `perform(what, action)` per file; test mode only `console.info`s.
- `Control.qml`: Wi-Fi tile toggle, Bluetooth tile toggle, volume slider (`Audio.setVolume`; drag, click, wheel), brightness slider (`Brightness.set`), Skupienie (`Notifs.dnd`), Motyw (`Theme.setMode`).
- `MiniPlayer.qml`: prev, toggle playing, next.
- Zasilanie calls `IslandState.request("power")` directly, deliberately: it is an island transition, not system state (no `power` layer exists yet, so it would show an empty island until a later task).
- No smoke or probe changed real volume / mute / brightness / player / Wi-Fi / Bluetooth state. No `notify-send`.

## TDD evidence
1. RED (tokens): `node --test tests/theme.test.mjs` after adding the two new tests, before the tokens:
   `SyntaxError: "undefined" is not valid JSON at plain (tests/qmljs.mjs:19)` for both "layout.control matches reference 3.7 and R24" and "layout.miniPlayer matches reference 3.7". Throw rather than a clean assertion diff, but the right reason: the `layout.control` / `layout.miniPlayer` groups do not exist, `plain()` cannot serialise `undefined`.
   GREEN: same command after adding tokens: `ℹ pass 21 / ℹ fail 0`; whole `node --test tests/`: `pass 82 / fail 0` (includes `no-magic.test.mjs`).
2. RED (QML): `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh /tmp/red-16.sh` (the check minus the light shot, to save budget), before `Control.qml` existed: the `expect` lines pass (island state is independent of the layer), shot `control-dark.png` shows an empty glass island, 520x440, no content, as the brief predicts.
3. GREEN: `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh tests/smoke/16-control.sh`: exit 0, `island.current = control`, `targetW = 520`, `targetH = 440`, `theme.mode = light`, both shots written, no unlisted WARN/ERROR. Before the Networking alias fix (below) the same run failed with `Unable to assign [undefined] to bool` (twice), which is how that bug surfaced. After the final `hitArea` rename the no-shot variant was re-run: clean. Also green (zero FAIL): `00-start`, `02-theme`, `04-state`, `06-content`, `08-notifs`. `qs list --all` after each run: "No running instances".
Shots used: 3 of 4 (1 RED, 2 GREEN).

## Shots against §3.7 (pc)
- No tile row (pc has neither NetworkManager nor BlueZ), brightness slider hidden (no backlight); content top-aligned, bottom of the island empty (W10 "resulting layout unspecified"; height stays 440).
- Header: 44 px mono clock, right-aligned weekday (fg) and day + month (fgMuted) in Polish.
- Sliders card: one volume row, white `sliderFill` over the chip track, value at 28 px width right-aligned.
- Toggles: 3 round buttons, centred in a 4-column grid (R24), labels fgMuted; off = tile bg.
- Mini player: tile with art and the inverse play button plus prev/next; a stopped Chromium MPRIS player exists with empty metadata, so the title/artist area is empty (checked with `playerctl`: status Stopped, metadata empty). Title/artist rendering with real metadata was therefore not seen.
- Light shot: Motyw circle is accent (checked = light), inverse play button dark, tiles light glass. The top (clock) looks washed out: the light sheen overlay is brightest at the top (existing material behaviour, not this task). I did not compare against the `JasnyMotyw` prototype beyond this.

## Not verified by execution
Drag, wheel, tile clicks, toggles, player buttons: pc has no pointer-injection tool; verified only by reading the code and left to the user gate. Also not seen: Wi-Fi / Bluetooth tiles populated (laptop), brightness slider, real title/artist text.

## Self-review
- Fixed during work: `Networking.wifiEnabled` binding warning (see Concerns 2); `"Wi‑Fi"` U+2011 replaced with ASCII hyphen (font coverage risk); slider MouseArea id `drag` renamed `hitArea` (shadowed MouseArea's `drag`).
- Fill has its own radius (as in `Osd.qml`) although §3.7 says "no own radius": a rounded-rect `clip` does not round-clip.

## Concerns
1. `services/Time.qml` is outside the brief's file list. Needed for the Polish weekday/month; the alternative was a second `SystemClock` in Control. `dateStr` (English, unused) left untouched.
2. Trap for Tasks 17-22: `import Quickshell.Networking` makes an unqualified `Network` resolve to Quickshell's `Network` type (not the `services/Network.qml` singleton), so `Network.available` evaluated to undefined. Imported `as QsNetworking` in Control.qml; `Network` still means the service.
3. Commit used `git add -A config/quickshell`, not the brief's `git add -A .`: `.flow/sdd/` is untracked dispatcher material.
4. Judgement calls the reference leaves open: Motyw is "checked" in light mode; mini player shown whenever `Players.hasPlayer` (even stopped); a lone Wi-Fi/BT tile keeps a half-width column; single stroke width (`Theme.sizes.iconStroke` 1.6): §3.7's 1.8 / 2.2 strokes need an Icon `stroke` property, not added; wheel step `0.05` and `hitH` 24 are new unspecified tokens; muted volume shows empty track and "—" (as Osd); the volume fill animates 260 ms except while dragging.
5. `MiniPlayer` carries the sizes of the panel (art 40, play 38, skip 32); Media (380x56, art 36, play 36) and Lock may need those sizes turned into properties.
6. Prev/next in MiniPlayer follow the brief's interface; §3.7 itself shows only play/pause.

## Fix round 1 (review Important 1-3)
Files: new `lib/slider.js`, `tests/slider.test.mjs`; changed `states/Control.qml`, `lib/theme.js` (+2 tokens), `tests/theme.test.mjs`.

### Important 1: wheel step (sign-only, from the displayed value)
- `lib/slider.js` `wheelFraction(current, angleDeltaY, step, min)` = `current + step * angleDeltaY / 120`, clamped to [min, 1]; null (ignore) for a zero / missing delta (horizontal tilt). Never moves against the wheel: wheel-up on a value above 1 (overamplified volume) returns null (unchanged), wheel-down from above 1 caps at 1.0; wheel-down on a value below `min` returns null. `dragFraction(x, width, min)` replaces the inline clamp.
- `SliderRow` has a new `value` property (the real level, default = `fraction`) that the wheel steps from; the volume row passes `Audio.volume`, the brightness row the coalescer's base (see 2).
- Decision (controller): muted volume. A wheel step or a click/drag on the track while muted starts from the real stored `Audio.volume` (not the displayed 0) and writes only the level; the mute state is never touched. Consequence to know: the fill stays empty and the label "—" while muted, whatever is set; the level change shows after unmuting.
- Tests (`tests/slider.test.mjs`): full notch 120, deltas 15 / 30 (1/8, 1/4 of a step), negative, zero / NaN / undefined -> null, clamp to [min, 1], floor, muted-start (caller passes 0.3), above 1.0, drag clamp / no width.

### Important 2: brightness drag storm and 0%
- Tokens `layout.control.brightnessThrottleMs: 50` and `brightnessMin: 0.05` (comment in theme.js: reference silent, floor is a safety choice, user can change both). No Theme.qml change needed (tokens read through `Theme.layout.control`).
- `lib/slider.js` coalescer (pure, state `{pending, cooling, last}`): `request` (first request sent at once, starts cooldown; later ones only keep the last pending), `tick` (send pending and keep cooling, else end cooldown), `flush` (release: send pending now), `base` (last requested value while cooling, else the real one).
- `Control.qml`: `requestBrightness` / `flushBrightness` / `brightnessTimer` (repeat Timer, interval from the token) around the state; every send still goes through `perform(...)` (test mode only logs). Brightness row: `min: brightnessMin`, `value: brightnessBase` (wheel notches while a request is cooling step from the last requested value), `onMoved -> requestBrightness`, `onSettled -> flushBrightness` (`MouseArea` `onReleased` and `onCanceled`), so the release position is always the final value sent. The volume row is not throttled (PipeWire property write, no process).
- `Brightness.set` and the OSD path untouched (OSD only reads `Brightness.value`).
- Tests: coalescer state machine (first send, pending keeps last only, tick, empty tick ends cooldown, flush, base, no mutation); theme token test updated.

### Important 3: Wi-Fi / Bluetooth tiles no longer toggle the radio
- Removed the two `onClicked` handlers (their `perform()` lambdas with it) and, now unused, `Tile`'s `MouseArea` and `signal clicked`. Tiles keep showing the actual state (incl. the off look). Comment on `Tile` says informational only.
- Test: `control panel: no code path writes the Wi-Fi or Bluetooth radio state` (source grep on `states/Control.qml`, RED before the edit, GREEN after).
- Grep proof, `grep -nE "wifiEnabled|\.enabled|adapter" states/Control.qml` now only reads: lines 24-27 (properties), 364-368 (`visible`, `sub`, `checked`); `grep -rnE "wifiEnabled\s*=[^=]|\.enabled\s*=[^=]" --include=*.qml .` -> no match (exit 1).

### Evidence
- RED (stub `lib/slider.js`, theme test with the new tokens): `node --test tests/slider.test.mjs` -> `ℹ tests 17 / ℹ pass 0 / ℹ fail 17`; `node --test tests/theme.test.mjs` -> `ℹ pass 20 / ℹ fail 1` (layout.control).
- GREEN lib only (before the Control edit): `ℹ pass 16 / ℹ fail 1` (only the radio-write source test red). After tokens: theme `ℹ pass 21 / ℹ fail 0`.
- GREEN full: `node --test 'tests/*.test.mjs'` -> `ℹ tests 99 / ℹ pass 99 / ℹ fail 0` (includes no-magic: no literals added to QML).
- Smoke (`QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh`): `00-start.sh` exit 0; `04-state.sh` exit 0, all `ok:` lines, no FAIL/WARN/ERROR (opens the control state, so Control.qml is instantiated and the log checked); `06-content.sh` exit 0, no `shot` lines. `qs list --all` after each run (2 s): "No running instances". `16-control.sh` not run, no shot taken (layout unchanged apart from the removed tile click area).
- Not verified by execution: wheel / drag / throttle in the live shell (no pointer injection on pc); the arithmetic and coalescer are covered by the node tests, the QML wiring only by load + code reading. Left to the user gate.

### Notes
- `percent` token untouched; MiniPlayer minor items not part of this round.
- Quickshell restriction kept: no `on<Capital>` names added (new members: `request`, `settled`, `value`, `min`, `brightnessQ`, `brightnessBase`, `sendBrightness`, `requestBrightness`, `flushBrightness`, `brightnessTimer`).
