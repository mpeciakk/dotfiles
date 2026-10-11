# Task 6 report: content host with enter/exit choreography

Status: DONE_WITH_CONCERNS. Commit f811f09 "quickshell: island content host with enter/exit choreography".

## Implemented
- `IslandContent.qml` (new): `target`, `output`, `sources` (default `({})`), readonly `shown`. A Repeater over `Object.keys(sources)` makes one layer per entry: width/height from `IslandState.geometryFor(state)`, centred, `y: 0`, `transformOrigin: Item.Center`, `enabled: lit`. Each layer has a `Loader` that stays mounted, with `active` and `output` pushed into the loaded item through `Binding`. Opacity, scale and blur are each `Behavior { SequentialAnimation { PauseAnimation; NumberAnimation } }`. The pause is the enter delay and 0 on exit. The values and curves are the §2.8 tokens (`enterCurve` on enter, `easeCurve` on exit). Blur goes through a `MultiEffect` inside the layer, and `layer.enabled` is on only while blur > 0. Reduced motion: opacity only, `reducedFadeMs`, no delay, scale stays 1, blur 0.
- `shown`: `""` from the moment `target` changes until `enterTimer` fires. The interval is `enterOpacityDelayMs + enterOpacityMs` (380) for a state with no `sources` entry, and the longest of the opacity/scale/blur enter ends (440) for a state with a layer. In reduced motion it is `reducedFadeMs`.
- `Island.qml`: `IslandContent` goes into `IslandShape`'s default `content`, so the layer order is unchanged. It calls `IslandState.reportShown(screen.name, shown)` on change and on completion.
- `IslandState.qml`: `shownByOutput` map, `reportShown(output, s)`, readonly `contentState` (the entry for `output`, or for `Niri.focusedOutput` while `current === "rest"`, `""` if missing; this tolerates an empty output), and an IPC `contentState` property.
- `tests/smoke/06-content.sh`: exactly the brief's check, no `shot` lines.

## TDD evidence
RED (before any production code): `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh tests/smoke/06-content.sh`
```
FAIL: island.contentState expected 'rest' got 'Property not found.'
FAIL: island.contentState expected '' got 'Property not found.'
FAIL: island.contentState expected 'launcher' got 'Property not found.'
FAIL: island.contentState expected 'rest' got 'Property not found.'
```
This is expected: the IPC property did not exist yet.

GREEN, same command after implementing:
```
ok: island.contentState = rest
ok: island.contentState = 
ok: island.contentState = launcher
ok: island.contentState = rest
```
(exit 0, no logged warnings.)

## Other verification
- `node --test tests/`: 21/21 pass (includes `no-magic`).
- Smoke 00-start, 02-theme, 04-state (17 ok), 06-content: all exit 0 with no warnings. I did not re-run 05a and 05b because they contain `shot` lines and I had no shot budget left. After every run `qs list --all` showed "No running instances".
- Choreography with a temporary probe state (an opaque magenta Rectangle with a yellow square, registered as `launcher`; probe and debug logging removed before commit, `git status` clean apart from `.flow`):
  - An `onOpacityChanged` log showed the enter's opacity starting after the delay. Scale was already moving and blur at 6 and falling. The exit started immediately (first sample 0.993, scale 0.98, blur 0.09) and ran down to opacity 0, scale 0.941, blur 6.00.
  - An interrupt (open, close, open within the transition) restarted from the current values (e.g. enter resumed at opacity 0.033, blur 5.80).
  - `contentState` was `""` during the transition and `launcher` after it.
- Reduced motion (temp config `reducedMotion: true`): `contentState` was already `launcher` 300 ms after `open launcher`. In the normal path it would still be `""` at 380 ms. So the 120 ms path works. Not committed as a check.
- Live shots taken: 2 (both of the mid-transition probe run, because I ran the probe script twice). Neither actually caught a mid-fade (IPC and screenshot latency exceeded 440 ms of transition). The second showed the probe fully entered: content over the fill, and the ring and gloss visible above it. No harness windows were opened.

## Files
- Created: `config/quickshell/IslandContent.qml`, `config/quickshell/tests/smoke/06-content.sh`
- Modified: `config/quickshell/Island.qml`, `config/quickshell/IslandState.qml`

## Self-review
- I deviated from the `reportMask` pattern on purpose. `reportMask` guards on `output === root.output`. Copied for `shown`, it would drop the report of a non-active output's island, and at rest it would go stale when the focused output changes. A per-output map with a derived `contentState` is correct in both cases.
- `sources` is empty, so no layer code runs in the committed check. The probe run is the evidence for the layers.
- Names: none is `on<Capital>…`. The layer id is `slot` because inside the inner `layer.effect` item an id called `layer` would collide with the grouped `layer` property. The item's own `blur` property sits next to `Behavior on blur`.
- No magic numbers (the no-magic test passes).

## Concerns
- Timing: `shown` is a timer rather than the animations' real end. A state with a layer reports `shown` after 440 ms (the scale end), the brief's no-entry rule gives 380 ms, and the smoke check's 600 ms wait leaves enough margin. Across 4 green runs there was no flake.
- A state with a layer whose scale delay is changed in Theme gets a new `shown` time automatically; a hidden layer's content still runs its animations while mounted (the brief says so; no opacity-0 culling was added).
- The `sources` map is the default value of the property in `IslandContent.qml`; each later task edits that line.
