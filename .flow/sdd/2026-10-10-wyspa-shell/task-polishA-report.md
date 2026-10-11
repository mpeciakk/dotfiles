# polishA report

Commit 40bc67c `quickshell: smokes independent of real fullscreen windows, maskMode line, doc fixes`

## Implemented
1. `services/Fullscreen.qml`: `testMode` (`Quickshell.env("WYSPA_TEST") === "1"`, same idiom as the other components);
   `outputs` is `[]` in test mode, real detection unchanged otherwise.
2. `Island.qml`: `maskMode` = `full` (modalHere) / `line` (lineWanted) / `shape`. `IslandState.qml` comment updated
   (`"shape" | "line" | "full"`).
3. `tests/smoke/20-line.sh` rewritten: no BASE, no real-state dependency. Asserts `lineOn ""` at start (the guard
   proof; a real fullscreen window on DP-2 exists on pc right now), maskMode full (launcher) / shape / line / shape,
   modal-while-hidden = full, line mask back after closing it. `shot line` moved to the very end (see Concerns).
4. Docs: CLAUDE.md (niri-validate -> `hosts/pc/niri-output.kdl`; shot.sh crops around the island; blur region moved to
   the Island.qml row, IslandShape = path, shadow, inner glow; gotcha 10 rewritten with maskMode values),
   docs/DESIGN.md structure list (blur region on Island.qml, IslandShape "plus cień i wewnętrzna poświata").
   DESIGN.md has no line 259 for this; the matching text is at ~line 164-165.

## TDD evidence
RED (smoke rewritten first, production code untouched), `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh tests/smoke/20-line.sh`:
```
FAIL: island.lineOn expected '' got 'DP-2'          <- real fullscreen window leaks into test mode
ok: island.maskMode = full
ok: island.maskMode = shape
ok: island.hidden = true
ok: island.lineOn = DP-2,HDMI-A-1
FAIL: island.maskMode expected 'line' got 'shape'   <- no `line` value yet
```
Expected: Fullscreen had no test guard; Island.maskMode only knew full/shape.

GREEN after the two code changes + reordering the shot (same command, shot-less copy, see Concerns):
```
ok: island.lineOn =
ok: island.maskMode = full
ok: island.maskMode = shape
ok: island.hidden = true
ok: island.lineOn = DP-2,HDMI-A-1
ok: island.maskMode = line
ok: island.hidden = false
ok: island.lineOn =
ok: island.maskMode = shape
ok: island.maskMode = full
ok: island.lineOn = DP-2,HDMI-A-1
ok: island.maskMode = line
rc=0
```
Other runs (all rc=0, no WARN/ERROR, `qs list --all` = "No running instances." 2 s after each): 02-theme, 04-state,
06-content (4 ok; passes with the fullscreen window present), 08-notifs, 11-series, 21-auto.
`node --test 'tests/*.test.mjs'`: 204/204 pass.

## Concerns
- Live-shot budget exceeded: 2 real screenshots were taken (the two RED/intermediate runs of 20-line, both with the
  old placement of `shot line`), budget was 1. The final file was verified with a shot-less copy (`grep -v '^shot '`),
  so the committed `shot line` as last line was not executed after the final edit.
- Why the shot moved: niri's screenshot notification arrives as a toast in the test instance late; with the shot
  mid-script, the later `open launcher` step saw `maskMode` `line` instead of `full` (reproduced: passes without
  the shot). Gotcha 7 already says "take the shot last".
- The guard proof in the smoke is only meaningful while a fullscreen window exists; no source-grep node test was added
  (brief: only if no runtime way).
- Island's `maskMode` only reaches IslandState for the output equal to `IslandState.output`, which is "" until
  something is first opened; the smoke opens/closes the launcher first for that reason (commented in the smoke).
  Not changed (out of scope).
- A parallel run of two smokes happened once by mistake (02-theme and 06-content in one tool block); both were rerun
  sequentially and pass.

## Fix round 1

- Island.qml: mask now `item: root.maskMode === "full" ? stage : shape.body` / inner `item: root.maskMode === "line" ? hoverZone : shape.body`; `maskMode` is the single source of truth. Header comment reworded.
- tests/niri-validate.sh header: "with the pc host's niri-output.kdl as output.kdl".
- CLAUDE.md gotcha 10 and the Island.qml table row: "hover zone (plus the body while it grows)".
- Behaviour-preserving refactor: safety net is the existing smokes (20-line asserts maskMode full/shape/line).
- Evidence: `node --test 'config/quickshell/tests/*.test.mjs'` -> 204 pass, 0 fail. Smokes (QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh ...): 20-line rc=0 (last asserts `island.maskMode = line`), 06-content rc=0, 04-state rc=0, 02-theme rc=0; `qs list --all` -> "No running instances." after each.
