# Wyspa around the MacBook notch — plan

## Goal
On an output with a notch (the `laptop`'s eDP-1, MacBook Air M2, scale 1.5) the island is drawn around the
notch instead of under it: at rest it is as tall as the notch with its content left and right of it, every other
state grows down with its content below the notch. Spec: `config/quickshell/docs/DESIGN.md`, decision W14.

## Decisions
- D1 The notch is per output in the shared host config: top-level key `notch` in `~/.config/dotfiles/config.json`
  (repo `config/dotfiles/config.json`), `{ "<output name>": { "w": <px>, "h": <px> } }`, logical px. The `laptop`
  value is `"eDP-1": { "w": 205, "h": 43 }` (measured 2026-10-12 with a ruler on `laptop`: hidden x 750–955 of 1706,
  64 physical rows at scale 1.5). eDP-1 exists only on `laptop`, so `pc` is unaffected. Hot-reloaded like the rest
  of the config. Rejected: a per-host file in `hosts/mac/` merged over config.json (second FileView and a dotter
  entry for one key; the user chose the shared key).
- D2 Rest on a notch output = "beside the notch" (user's choice): height = notch h, bottom radius = h/2, width =
  notch w + 2 × `geom.notchSide`; with the unread badge each side grows by (restBadge.w − rest.w)/2 so the island
  stays centred on the notch. Left of the notch: the workspace dots; right: clock, eq, badge. Default
  `geom.notchSide: 124` (→ 453×43, 505×43 with the badge): sized for 12 dots (113 px) on the left and clock + eq +
  a 3-digit badge (~131 px) in the 150 px badge side; `laptop` has 10 workspaces on eDP-1 today. Overflow beyond
  that is clipped by the body (`clip: true`), no reflow. Rejected: notch inside a taller island (79 px strip,
  7 % of a 1109 px screen); island pushed below the notch (ears hang in the wallpaper).
- D3 Every other state except `line` on a notch output: h = state h + notch h, content offset down by notch h
  (geometry gets a `top` field: notch h, 0 for rest and for outputs without a notch). Widths unchanged (all ≥ 300
  > 205). `center`: the hMin/hMax clamp applies to the content height, notch h is added after it.
- D4 `line` is unchanged on a notch output: the 56×5 line sits under the notch and is not visible; the hover zone
  (400×28 at the top) still brings rest back. Rejected: moving the line below the notch (a floating line in a
  fullscreen window, for no gain — the notch already marks the spot).
- D5 Exclusive zone on a notch output = notch h (43) instead of `geom.exclusive` (36), in the Strut:
  `notch ? notch.h : geom.exclusive`. Line mode on a notch output (user, 2026-10-12): hidden (`island hide`) keeps
  notch h reserved, so tiled windows never go under the notch; only a fullscreen window there (`Fullscreen.on`)
  drops it to 0. Outputs without a notch: 0 in line mode as today. Rejected: 0 on hide (window title bars under
  the camera).
- D6 `IslandState.geometryFor(s, output)` takes the output; every caller passes its own (island window, content
  slots, Strut, lock overlay, IPC `targetW/targetH`). IPC `targetW/targetH` use the same output rule as
  `contentState`: `current === "rest" ? Niri.focusedOutput : output` (`output` is `""` until the first `request()`).
  The lock's way in and back docks at the per-output rest geometry; `LockOverlay.screen` can be null during
  creation (it already guards `over.screen ? … : 0`), so the call is guarded the same way.
- D8 Precondition (spec): the notch exists in niri's coordinates only with eDP-1 at `2560x1664@60`
  (`hosts/mac/niri-output.kdl`) and the kernel parameter `appledrm.show_notch=1`; at 2560x1600 the `notch` entry
  must be removed, or rest shows an empty gap.
- D7 Out of scope: AutoTheme's wallpaper crop (`services/AutoTheme.qml`, `geom.rest` dims) stays as is — it samples
  the wallpaper image, a slightly smaller crop changes nothing visible.

## Constraints
- Theme-only literals in UI QML (`tests/no-magic.test.mjs`; allowed `0`, `1`, `2`, `0.5`); new values are tokens
  in `lib/theme.js` `defaults`.
- `lib/*.js`: `.pragma library`, no imports, only top-level `function` / `var`.
- Without a `notch` entry for an output, every geometry, the exclusive zone and the rest layout are exactly as
  today (pc must not change).
- Smokes: `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh …`; a `shot` is the last line; never `island lock` in a test;
  the fixture config has no `notch`, so existing smokes are unaffected.
- Quickshell 0.3.2: no `on<Capital>` property names (CLAUDE.md gotcha 3).
- No live reload: after `dotter deploy`, `systemctl --user restart quickshell` (only on `laptop`, by the controller).

## Verification
1. `node --test 'tests/*.test.mjs'` green; all smokes green on `laptop` (`for f in tests/smoke/*.sh; do
   QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh $f; done`).
2. New smoke `tests/smoke/22-notch.sh` sets a notch for the focused output (`niri msg -j focused-output`) in
   `$CFG` (written in place: `jq … > tmp; cat tmp > "$CFG"`, never `mv`) and checks `targetW/targetH` at rest
   (453/43), with `osd` open (300/87), and back; its last line is a rest shot.
3. Live on `laptop`, before the merge (dotter symlinks point at the main checkout): the controller stops the live
   shell (`systemctl --user stop quickshell`), runs the worktree's config as a normal instance
   (`qs -p <worktree>/config/quickshell -d`, real config with the `notch` entry), the user checks by eye: rest
   (dots left, clock right, nothing under the notch), `island open osd`, `island open launcher` (content below the
   notch — the only proof of the slot offset), dark and `theme setMode light`, a player playing with an unread
   badge (eq + badge fit), and a real `Mod+L` lock / unlock (the card leaves from and docks into the notch rest).
   Then `qs kill -p <worktree>/config/quickshell`, `systemctl --user start quickshell`.
4. Same commit tree on `pc` (user, later): rest is 200×36 there, unchanged.

## Task 1: notch geometry core
**Outcome:** with a `notch` entry for an output, the island on that output has D2/D3 geometry, its content
layers sit below the notch (except rest), the Strut reserves notch h, the lock overlay docks at the per-output
rest; without an entry nothing changes. Rest content itself is still the centred row (Task 2 splits it).
**Acceptance:**
- `lib/theme.js` `notchFor(hostNotch, output)`: `{ w, h }` for a valid entry (both positive numbers), `null`
  for a missing key, missing output, non-object, zero/negative/non-numeric values.
- `lib/island.js` `geometry(state, geom, ctx)` with `ctx.notch`: rest 453×43 r 21.5 top 0; restBadge 505×43;
  osd 300×87 top 43; center clamps content then adds 43 (hMax → 663); `line` identical with and without a notch;
  every state without `ctx.notch` returns exactly today's values plus `top: 0`.
- `Theme.notchFor(output)` reads `host.notch`; `IslandState.geometryFor(s, output)`; callers in `Island.qml`,
  `IslandContent.qml` (slot `y` = geo.top, height = geo.h − geo.top), `Strut.qml`, `LockOverlay.qml`, IPC
  `targetW/targetH` pass their output.
- IPC `targetW/targetH` at rest follow the focused output (D6).
- Strut on a notch output: `hide` keeps notch h, fullscreen gives 0 (D5); no-notch outputs as today.
- `tests/smoke/22-notch.sh` as in Verification 2; existing smokes green.
**Area:** `lib/theme.js`, `lib/island.js`, `Theme.qml`, `IslandState.qml`, `Island.qml`, `IslandContent.qml`,
`Strut.qml`, `LockOverlay.qml`, `tests/island.test.mjs`, `tests/theme.test.mjs`, `tests/smoke/22-notch.sh`.
**Context:** `L.geometry` and `IslandState.geometryFor` are the single geometry funnel; `IslandShape.qml` and the
blur region / input mask follow `shape.body`, so they need no change. Host keys like `wallpaper` and `lock` are read
from `Theme.host` the same way. Smoke helpers: `tests/smoke.sh` (`$CFG` is hot-reloaded by the `FileView`).

## Task 2: rest beside the notch, laptop config
**Outcome:** on a notch output the rest content is split: dots centred in the left side, clock + eq + badge
centred in the right side, nothing in the middle notch w; on other outputs Rest is unchanged. The repo config
carries the `laptop` notch.
**Acceptance:**
- `states/Rest.qml` uses `Theme.notchFor(root.output)`: with a notch, two groups placed in the side areas of the
  geometry from Task 1 (sides of `geom.notchSide`, wider with the badge); without, today's single centred row.
  Click (→ control), badge click (→ center) and the media hover keep working in both layouts.
- The eq + badge fit is checked live (Verification 3), not in a smoke (a smoke cannot start a player); the smoke
  shot shows the split with the badge (`notifs inject`).
- `config/dotfiles/config.json` has `"notch": { "eDP-1": { "w": 205, "h": 43 } }`.
- `22-notch.sh` ends with a rest shot that shows the split.
**Area:** `states/Rest.qml`, `lib/theme.js` (layout.rest tokens if needed), `config/dotfiles/config.json`,
`tests/smoke/22-notch.sh`, a test in `tests/`.
**Context:** Task 1's `Theme.notchFor` and the rest geometry (`IslandState.geometryFor("rest", output)`, its `w`
gives the side width). Existing Rest pieces (dots Repeater, clock Text, eq Row, badge Rectangle) are moved, not
rewritten.

## After the last task (controller, before the branch review)
State sections become true for the notch output: DESIGN.md W3 (exclusive 36/0), §4 (rest 200×36, exclusive zone),
§7 (Strut 36 px); `config/quickshell/CLAUDE.md` Strut row and a line on the top-level `notch` config key. W14
itself is written at the plan gate.
