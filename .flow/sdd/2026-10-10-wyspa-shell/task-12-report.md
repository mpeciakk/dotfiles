# Task 12 report: Notification center

Commit: abfba10 `quickshell: notification center with grouping and DND`

## Implemented
- `states/Center.qml` (new): header (count, DND switch, "Wyczyść"), empty state, groups newest first, collapsed group = top card + stack layers, "Pokaż N"/"Zwiń", per-card dismiss, per-group clear, Flickable list with thin scroll thumb in the island padding. `wantedHeight = N.centerHeight(Notifs.groups, expanded, metrics)`; a `Binding` (when active, `restoreMode: RestoreNone`) drives `IslandState.centerHeight`.
- `IslandContent.qml`: `sources.center`.
- `IslandState.qml`: opening centre -> `Notifs.markRead()` (in `onCurrentChanged`).
- `lib/theme.js`: `layout.center` completed (all tokens, comment names the unspecified ones: `cardIconImage` 24, `scrollW` 4).
- `tests/theme.test.mjs`: full `layout.center` values + parity test `layout.center.hMin/hMax == geom.center.hMin/hMax`.
- `tests/smoke/12-center.sh`.

## Carry-overs
1. **qsimage dangling: CONFIRMED, fixed.**
   - `notify-send -a Wyspa -h string:image-path:/tmp/wyspa-image.png` -> logged `notif.image = image://icon//tmp/wyspa-image.png` (NOT qsimage; icon provider, not tied to the Notification). Card showed the orange image; no warnings. So image-path does not exercise the dangling case.
   - Real image-data via `gdbus call ... Notify` with `{'image-data': <(4,4,12,false,8,3,[byte ...])>}` (parse validated first against a non-existent bus name) -> `notif.image = image://qsimage/1/1`. Opening the centre after the toast was gone: card showed the initial fallback ("W"), log: 4x `Requested image from unknown handle "1/1"` + `QML Image at @states/Center.qml[351:53]: Failed to get image from provider: image://qsimage/1/1`, smoke FAILED on them. (`/tmp/wyspa-shots/center-qsimage.png`)
   - Fix: the card picture is `N.iconSource({ appIcon: card.modelData.appIcon }, ...)`: `image` is ignored in the centre (appIcon/initial only), `Image { cache: false }`, not asynchronous. Re-run of the same check without the shot: no WARN. Consequence: image-path images also show the initial in the centre (toast still shows them).
   - The debug `console.info` in `services/Notifs.qml` was reverted (`git checkout`) before commit; one-off check files live in /tmp only (not committed: they need to own the notification daemon).
   - Notification sends in this task: 1x notify-send (image-path), 2x gdbus Notify with image-data (one with a shot, one re-run without a shot after the fix).
2. **centerHeight bounds:** `metrics = Object.assign({}, spec, {hMin: Theme.geom.center.hMin, hMax: Theme.geom.center.hMax})` + parity node test.
3. **Badge check:** `12-center.sh`: inject 3, open centre -> `unread 0`; close, inject 1 -> `unread 1` and `island targetW 252` (badge present, IslandState.badge = unread > 0). There is no cheap readable for the badge *text* (Rest renders `Notifs.unread` as a Text; no IPC property). I did not spend a shot on it (budget below); the text binding was verified in Task 9 and is unchanged.
4. **Shots:** 3 live shots total: `center-image` (image-path), `center-qsimage` (dangling proof), `center` (final 12-center.sh). In `12-center.sh` the shot is after every count-sensitive assertion and only DND/clear/relative lines follow (with a 700 ms wait for niri's own notification).

## TDD evidence
RED (node): `node --test tests/*.test.mjs` after adding the `layout.center` test: `AssertionError ... actual: { hMin: 170, hMax: 620, pad: 14, ... stackPad2: 14 }` vs expected with the new tokens (headerPadX ... scrollW). Expected: tokens did not exist yet.
RED (smoke, shot lines stripped to /tmp/12-red.sh so no shot is spent): 
```
ok: notifs.count = 3
ok: notifs.unread = 3
ok: island.current = center
FAIL: notifs.unread expected '0' got '3'
FAIL: island.targetH expected '279' got '170'
FAIL: notifs.unread expected '0' got '4'
FAIL: island.targetH expected '286' got '170'
...
FAIL: notifs.unread expected '1' got '5'
```
Expected: centre does not mark read, no Center layer / centerHeight binding.
GREEN: `node --test tests/*.test.mjs` -> 39 pass, 0 fail (incl. no-magic). Smoke `12-center.sh` (full, with shot): all `ok` incl. `targetH 279`, `286`, `170`, `620`, `unread 0/1`, `targetW 252`; no logged WARN. Also green: 04-state, 06-content, 08-notifs, 11-series. `qs list --all` -> "No running instances." after every run.

## Visual evidence and an UNVERIFIED fix (needs one shot)
The final `center.png` (before the last edit) showed appB single card and appA collapsed with the stack layer, but the layer showed THROUGH the translucent glass card (a lighter inner rectangle inside appA's card) instead of peeking out below it: the reference's cards are opaque, the glass `card` colour is not. I fixed it by clipping each layer to the sliver below the card (layer1: y 64..71, layer2: y 71..78, same absolute offsets 7/14 as the reference). The shot budget was used up, so this change is verified only by the smoke (no warnings, heights unchanged) and the arithmetic, NOT visually. One shot of `12-center.sh` is needed to confirm it.

## Deviation to name
`IslandState` `onArrived` also calls `Notifs.markRead()` while the centre is open (not in the brief; two assertions in `12-center.sh` cover it: `inject appB B2` -> `unread 0`, `targetH 286`). Rationale: otherwise whatever lands while the centre is open would show up as unread on the badge after closing. Easy to drop (one `if` + two asserts) if the reviewer disagrees.

## Concerns
- Layer clipping (above) not re-shot.
- Dismiss / dismiss-group / clear-all / expand-collapse by click and scroll by wheel are not exercised by any automated check (no IPC to click); only the data path (`clear`, heights) is. They are for the user gate.
- Cards in a collapsed group beyond the first stay mounted (hidden) so their images load.
- Whole list is rebuilt on every history change (Repeater over a new array), which also re-requests images; harmless now (appIcon only).
- Scrollbar thumb sits in the island's 14 px padding right of the list (reference gives only "thin, thumb chip").

## Files changed
config/quickshell/: `states/Center.qml` (new), `IslandContent.qml`, `IslandState.qml`, `lib/theme.js`, `tests/theme.test.mjs`, `tests/smoke/12-center.sh` (new).

## Fix round 1: stack layer visible through the card (reviewer, Important)

Verdict: NOT a code defect. The `center.png` the reviewer saw was older than the clip fix. No code change, no commit.

Evidence
- Cache: no `*.qmlc`/`*.jsc` anywhere in the worktree; `~/.cache/quickshell/qmlcache` holds two files of 688 B and 4488 B dated 09-19 / 10-08 (far too small and too old to be `Center.qml`, which was written 10-10 22:30). Nothing deleted. Stale compiled QML is ruled out.
- Timeline: `Center.qml` mtime 22:30:44, commit abfba10 at 22:31:44. The report (section above) states the final `center.png` was taken BEFORE the clip edit and the shot budget was used up. The reviewed PNG (preserved as `/tmp/wyspa-shots/center-before-fix-reviewer.png`, 960x598) shows card timestamps "22:30" and a different desktop background (terminal text) -> it was taken at 22:30, before the edit landed. It is that old file, not a post-fix shot.
- Code (`states/Center.qml:293-327`): layer-1 clip Item y=`card` (64), height `stackPad1` (7), `clip: true`; inner Rectangle `y = stackPad1 - parent.y` = stack y 7..71, so only 64..71 is visible. Layer 2 likewise 71..78. No second copy of the layer, no other item painting it, `clip` is on the right item; the only Behavior is on `stackPad` (group height), not on the clip item.
- Shot 1 (the only shot): `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh tests/smoke/12-center.sh` at HEAD abfba10, clean tree, no other instance (`qs list --all` -> "No running instances." before and after). All `ok:` lines, no WARN/FAIL. `/tmp/wyspa-shots/center.png` (640x399, cards "22:37"): the APPA ("Pokaż 2") card is a plain uniform translucent card with no inner rectangle and no rounded top corners inside it; the layer appears only as a ~7 px lighter strip below the card, inset on both sides, rounded at the bottom. Matches reference 3.5 / R6.
- `node --test 'tests/*.test.mjs'`: 39/39 pass.
- Shot 2 not taken (no change made).
