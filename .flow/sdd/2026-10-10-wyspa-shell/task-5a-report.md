# Task 5a report — island surface, morphing shape, strut, mask, focus

Commit: 819c079 `quickshell: island surface, morphing shape, strut`

## Implemented
- `IslandShape.qml`: full-window Item; one `Shape` (CurveRenderer) with one `ShapePath` (concave ear arcs Clockwise, convex bottom corners Counterclockwise, per §2.3). `w/h/r` each have a `Behavior` (morphMs, morphCurve, 0 under reducedMotion). `animEar = earAmount * min(Theme.geom.ear, animH - animR)`: `earAmount` (0..1) is the animated value (earFadeMs), so the clamp tracks animH every frame instead of lagging behind it (an animated clamped target would re-trigger the Behavior on every frame). Fill = `lineMode ? Theme.line : fillColor`, ColorAnimation bgColorMs. `body` Item has its own animated x/width/height; `content` alias = clipped item of animW x animH inside body.
- `Island.qml`: PanelWindow, 4 anchors, transparent, Ignore exclusion, Overlay layer, ns `wyspa`. `effState`, `modalHere`, `maskMode`. Mask `Region { item: modalHere ? stage : shape.body }`. Click-catcher MouseArea (enabled only when modalHere) closes; `Keys.onEscapePressed` on a FocusScope. Keyboard focus Exclusive iff modalHere && WYSPA_TEST !== "1". Reports its mask mode via `IslandState.reportMask` (on change, on completed, on `IslandState.output` change).
- `Strut.qml` as specified (Bottom layer, empty mask, exclusive zone Theme.geom.exclusive).
- `IslandState.qml`: `maskMode` property + readable IPC prop, `reportMask(output, m)` (ignored unless output matches).
- `shell.qml`: Variants delegate is a `Scope` with `Wallpaper`, `Strut`, `Island`. It also references `Niri.focusedId` at startup (see Concerns: found while testing).
- `config/niri/layout.kdl`: `struts { }` block removed. No new theme tokens were needed (`geom.ear`, `geom.exclusive`, motion tokens already exist).

## TDD evidence
RED (trimmed copy of the check without `shot` lines, to avoid needless live-monitor captures; the real check file is identical otherwise):
`QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh /tmp/05a-noshot.sh` ->
```
FAIL: island.maskMode expected 'shape' got 'Property not found.'  (x4)   rc=1
```
Expected: `maskMode` did not exist yet.

Intermediate: after the first implementation `expect island maskMode full` failed (`got 'shape'`). Cause: `Niri` is a lazy singleton; the first IPC `open` loaded it and read `Niri.focusedOutput` before its event stream delivered workspaces, so `IslandState.output` was "". Fixed by referencing Niri at startup in shell.qml.

GREEN: `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh tests/smoke/05a-surface.sh` ->
```
ok: island.maskMode = shape
/tmp/wyspa-shots/surface-rest.png
ok: island.maskMode = full
/tmp/wyspa-shots/surface-launcher.png
ok: island.maskMode = shape
ok: island.maskMode = shape
rc=0
```
Log clean (no new allowed-warnings patterns). `qs list --all` -> "No running instances." after every run.

Other checks: `node --test 'tests/*.test.mjs'` 21/21 (incl. no-magic); `tests/niri-validate.sh` -> "config is valid"; smoke 00-start / 02-theme / 04-state still pass (0 FAIL); an ad-hoc stress run (open/close/open mid-morph, control->osd rejected, center, close) passed with a clean log.

## Visual verification (PNGs read)
- `/tmp/wyspa-shots/surface-rest.png` (focused monitor scale 1.5): island body 300x54 px (= 200x36) at top centre, bottom corners rounded r 18, translucent glass. Zoomed crops of both top corners show concave ears flaring out ~24 px (= 16) with no seam between ear and body; left and right mirror each other.
- `/tmp/wyspa-shots/surface-launcher.png`: body 1020x534 px (= 680x356) at top centre, bottom corners rounded r 30, ears at the top corners; the wallpaper/terminal text shows through (glass, no blur yet — blur is a later task). Strut region above windows is visible as the 54 px top strip.

## Files changed
`Island.qml`, `IslandShape.qml`, `Strut.qml`, `tests/smoke/05a-surface.sh` (new); `shell.qml`, `IslandState.qml`, `../niri/layout.kdl` (modified).

## Self-review
- Names avoid `on<Capital>` properties. No numeric/colour literals beyond allowed ones (no-magic passes).
- Mask only covers the body rect, not the ears (ears are 16 px decorative fillets; click-through there is harmless). Ring/shadow/sheen are later tasks.
- Instances: none left running; shots taken: exactly the two in the check.

## Concerns
1. `effState` follows the brief literally: with `IslandState.output === ""` (niri has no focused workspace) no screen shows any non-rest state and no mask goes full. Tolerated (no crash), but a request in that situation is silently invisible.
2. `shell.qml` now also touches `Niri` at startup (not in the brief); without it the very first `open` after startup picks output "" (real bug in the live shell, not only in tests).
3. `maskMode` is only updated for the island whose screen equals `IslandState.output`; before the first request it holds the default "shape".
4. `Behavior` durations in `IslandShape.qml` repeat the `Theme.reducedMotion ? 0 : ...` expression four times (kept inline to follow the brief's literal form).

---

# Fix round 1 (review findings, both Important)

Only `IslandShape.qml` changed (Island.qml touched temporarily for the probe, restored byte-identical: `diff` against a saved copy was empty).

## Finding 1 - content painted under the glass fill
Change: the `Shape` is now declared before `bodyItem` (later sibling paints on top), with a comment saying why. No `z` needed.
Test: no QML-level test harness exists, so a visual probe (temporary opaque `Rectangle { anchors.fill: parent; color: "magenta" }` as `content` of `IslandShape` in Island.qml; removed before commit).
- RED (old order), `PROBE=red QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh /tmp/05a-launcher-only.sh` (open launcher, one shot, close) -> `/tmp/wyspa-shots/probe-launcher-red.png`, read: the probe renders as dull purple (~#C000C0), i.e. tinted/dimmed by the glass fill painted over it; only the corner slivers outside the fill show pure magenta.
- GREEN (fixed order), same command with `PROBE=green` -> `/tmp/wyspa-shots/probe-launcher-green.png`, read: whole body is pure #FF00FF, full opacity above the fill.
Side observation (not fixed, not on the list): clipArea is a rectangular `clip: true`, so content is not clipped to the rounded bottom corners (visible in the red shot as magenta in the corners). Later tasks must account for it (rounded clip / inset padding).

## Finding 2 - clicks in the body close modal states
Change: `bodyItem` got a no-op `MouseArea { anchors.fill: parent }` declared before `clipArea`, so it sits above the glass and below content (interactive content added later still receives its events first; non-interactive body area is absorbed).
Event path verification (static only): item tree is `Island.qml` stage(FocusScope) > [catcher MouseArea, IslandShape > [Shape, bodyItem > [absorber MouseArea, clipArea]]]. The absorber is in a later sibling subtree of the catcher and is hit-tested first for any point inside `bodyItem`; Qt delivers a press to the topmost accepting MouseArea and the catcher never sees it. Outside bodyItem nothing absorbs, so the catcher still fires (click-outside). NO CLICK WAS SIMULATED - no click injection tool here; this is reasoning from the item tree, not an observed event. Note: both areas accept only the left button (Qt default), so right-clicks never closed anything and still don't.

## Evidence
- `node --test 'tests/*.test.mjs'` -> `tests 21 / pass 21 / fail 0` (includes no-magic).
- `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh tests/smoke/05a-surface.sh` (final code, no probe), rc=0:
```
ok: island.maskMode = shape
/tmp/wyspa-shots/surface-rest.png
ok: island.maskMode = full
/tmp/wyspa-shots/surface-launcher.png
ok: island.maskMode = shape
ok: island.maskMode = shape
```
- smoke 00-start, 02-theme, 04-state: rc=0 / 0 FAIL (00 and 02 were once started concurrently by mistake; both passed, 00 re-run alone rc=0).
- `qs list --all` after every run (2 s wait) -> "No running instances."
- Live-screen captures taken: 2 probe shots + the 2 in the 05a check (4 total, each reported above).
