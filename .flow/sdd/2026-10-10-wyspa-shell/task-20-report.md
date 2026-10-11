# Task 20 report: fullscreen detection + line mode

Status: DONE_WITH_CONCERNS. Commits: e49dd84 `quickshell: line mode on fullscreen and on demand`, 0e3e623 `quickshell: line mode, the body keeps the hover and lineRequested names the strut's question`.

## Implemented
- `lib/fullscreen.js` `fullscreenOutputs(toplevels, windows, activeByOutput)`: fullscreen toplevels joined to niri windows on title + appId; an output counts when a matching window sits on that output's ACTIVE workspace (any twin wins). Deduped, discovery order. Guards for null inputs, null entries, missing `screens`, output without an active workspace (`active[name] != null`).
- `services/Fullscreen.qml`: `outputs` (readonly binding over `ToplevelManager.toplevels.values`, reading `fullscreen/title/appId/screens[].name` inside the binding so per-toplevel changes re-evaluate, plus `Niri.windowList` and `Niri.activeByOutput`), `on(name)`. Referenced in `shell.qml` (`Fullscreen.outputs;`) so detection is live from start. Property names verified in the installed qmltypes (`Toplevel`: `appId`, `title`, `screens`, `fullscreen`).
- `IslandState.qml`: `lineByOutput` + `reportLine()`, readonly `lineOn` (sorted, comma-joined) exposed on the island IPC; `lineRequested(output)` = `Fullscreen.on(output) || hidden`.
- `Island.qml`: `effState` split into `baseState` (old derivation), `lineWanted` (`lineRequested && baseState === "rest"`), `line` (`lineWanted && !hovered`), `effState = line ? "line" : baseState` (so geometry/lineMode/blur/content target all follow the existing "line" wiring). `hovered` is set by a HoverHandler on a 400x28 `hoverZone` (top centre, `Theme.geom.hoverZone`) OR a second HoverHandler on the body; the pointer leaving both ends `hovered` after `Theme.motion.lineLeaveDelayMs`. Mask: parent Region `modalHere ? stage : shape.body`, child Region `lineWanted ? hoverZone : shape.body` (union). In line this is zone only (56x5 body lies inside the 400x28 zone); everywhere else the screen stays click-through.
- `Strut.qml`: `exclusiveZone` 0 when `IslandState.lineRequested(this screen)`.
- `tests/smoke/20-line.sh`: baseline `lineOn` read first; after `hide` it must equal the sorted `niri msg -j outputs` names; after un-hide + `island close` it must equal the baseline again.

## TDD evidence
1. First run, no `lib/fullscreen.js`: ERROR at load ("test failed", ENOENT), not a RED; discarded as evidence.
2. RED: stub `fullscreenOutputs` returning `[]`: `node --test tests/fullscreen.test.mjs` -> 4 pass, 6 fail (the six tests that expect an output or the dedupe/several-screens behaviour; the four "expects []" tests pass trivially). Expected: the feature is missing.
3. GREEN: implementation -> 10/10.
4. Added test "window without workspace_id does not match an output without an active workspace": RED (`undefined === undefined` matched; 10 pass / 1 fail) -> fixed with `active[name] != null` -> GREEN 11/11.
5. Full suite `node --test 'tests/*.test.mjs'`: 186/186 (after both commits).
6. QML has no unit-test harness; its checks are the smokes below.

## Live verification (read-only, no window titles)
- Temporary probe in shell.qml (removed; `git diff` shows only the `Fullscreen.outputs;` line + comment): after ~2 s `ToplevelManager` listed n=8 toplevels, fs=1 (`steam_app_275850`, on DP-2), `Fullscreen.outputs=["DP-2"]`, `lineOn=DP-2`. `niri msg -j windows`: 8 windows, the same app_id on workspace 4, and active workspaces were {DP-2: 4, HDMI-A-1: 3}; consistent. (Earlier in the session DP-2's active workspace was 1 and the game on 4; the output followed when the user switched workspace, but I did not observe the transition itself.)
- `tests/smoke.sh tests/smoke/20-line.sh` PASS: `hidden true`, `lineOn = DP-2,HDMI-A-1`, shot, `hidden false`, `lineOn = DP-2` (baseline, the real game). Log clean (no allowed-warnings additions). `00-start`, `04-state`, `05a-surface` PASS. After the second commit's hover edit: no-shot variant of 20-line (hide / lineOn / hide / lineOn) PASS, `04-state` PASS. `qs list --all` empty after every run.
- Shot `line.png` (DP-2, scale 1.5, 600x234 crop, taken over the running fullscreen game): a light rounded bar at top centre about 84x8 px = 56x5 logical, flat against the game; no ears, ring, gloss or shadow visible. Matches §2.6.
- Finding while debugging: in the first 20-line run `lineOn` after un-hide was empty. Cause: niri's screenshot notification arrives at the test instance (it is the notification daemon) and shows as a toast on the focused output, and a toast is not rest, so the island correctly leaves line. Proof the "toast over a fullscreen game" rule works. Fix: `call island close` before the final assertion. The first `lineOn "$OUTPUTS"` assertion is before the shot, so unaffected.
- Screenshot budget: 3/3 used (`line`, plus `surface-rest`/`surface-launcher` from 05a).

## Could NOT verify
- The line-mode input mask itself: `maskMode` still reports `"shape"`/`"full"` and there is no readable for the actual region. Verified from code only: `shape.body` plus `hoverZone`, body 56x5 inside 400x28.
- Why no `"line"` maskMode value: `reportMask` publishes only for `IslandState.output`'s island; with the game fullscreen on the focused output `05a-surface`'s `expect island maskMode shape` would read `"line"` and fail on this machine. Left unchanged.
- Hover enter/leave and the `lineLeaveDelayMs` collapse: no input injection, never exercised.
- Reactivity to a fullscreen transition (window entering/leaving fullscreen live): the probe was a static snapshot. The binding reads toplevel properties inside `.map`, so QML tracks them, but not observed.

## Files changed (config/quickshell)
Created: `lib/fullscreen.js`, `services/Fullscreen.qml`, `tests/fullscreen.test.mjs`, `tests/smoke/20-line.sh`. Modified: `Island.qml`, `IslandState.qml`, `Strut.qml`, `shell.qml`.

## Self-review / concerns
- Environment dependence: smokes asserting rest (`09-rest`: `contentState rest`, `restLoaded true`, `shot rest`) fail while a fullscreen window sits on the focused output, since the island is legitimately in line there. Not run (shot budget). Out of scope, but the suite is now sensitive to the user's live session.
- `hide` now sets `exclusiveZone` 0 on both outputs: every smoke `hide` reflows the user's live tiled windows (per the brief).
- `Island.lineWanted` (adds rest check) vs `IslandState.lineRequested(output)` (no rest check): renamed in the second commit to avoid same-name confusion.
- Child mask Region duplicates the parent (`shape.body` twice) when not in line; harmless.
- Hover edge fixed in the second commit: the rest body is 36 px, the zone 28 px, so a pointer on the body's lower 8 px was outside the zone; a second HoverHandler on the body now counts.
- `lineByOutput` keeps a stale entry if a screen is unplugged (IPC readout only; Strut/Island use their own state).
- Task 5b's note (`lineMode` flips instantly, so ring/gloss/shadow pop at morph start) left as is.
- Title+appId matching is ambiguous by nature; two windows with the same pair on different outputs' active workspaces can yield a false positive. Accepted by design.
