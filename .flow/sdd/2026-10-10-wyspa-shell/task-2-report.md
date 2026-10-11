# Task 2 report — Theme tokens + Theme singleton + wallpaper

Status: DONE_WITH_CONCERNS. Commit 84849c6 `quickshell: Theme tokens (dark/light, glass levels) with config overrides`.

## Implemented
- `lib/theme.js`: `rgba hex withAlpha merge resolve` + `defaults` (geom, radii, motion, sizes, fonts, palette dark/light, glassLevels, solid, sheen, shadow, lockShadow, lockWallpaper, accentAlpha, empty `layout`). Values from reference §1.1-1.7, §2a, R1-R12/R16/R23/R34. Additions beyond the brief's list: `accentAlpha {soft .18, halo .2, focus .9}` token (R9: alphas not hard-coded), `resolve()` coerces unknown mode to dark, `merge()` ignores null/undefined leaves in `over`.
- `Theme.qml`: singleton exactly per the brief pattern (34 animated colours + `sheen` Behavior, real props, FileView hot reload, IpcHandler `theme`).
- `Wallpaper.qml` ported from ff1f02d (Config.wallpaper -> Theme.wallpaper); `shell.qml` has `Variants { model: Quickshell.screens; Wallpaper {} }`.
- `tests/theme.test.mjs` (verbatim from brief), `tests/smoke/02-theme.sh`.

## TDD evidence
RED (stub `lib/theme.js` = `.pragma library` + `var defaults = {};`): `node --test tests/theme.test.mjs` -> all 11 theme tests failing (8 with e.g. `TypeError: T.rgba is not a function`, `T.hex`, `T.withAlpha`, `T.merge`, `T.resolve`; the geom/motion/choices ones on undefined values). Expected: functions missing, not a load error.
GREEN: `node --test 'tests/*.test.mjs'` -> `tests 12, pass 12, fail 0` (theme 11 incl. no-magic = 12 total).
Smoke RED (no Theme.qml): `tests/smoke.sh tests/smoke/02-theme.sh` -> every expect `got 'Target not found.'`. Note the crossfade-mid check passes spuriously in that state (verbatim from brief; the other expects fail).
Smoke GREEN: exit 0:
```
ok: theme.mode = dark
ok: theme.level = ciekłe
ok: theme.fg = #ffeceaf2
ok: crossfade mid value #ffb7b4be
ok: theme.fg = #ff1e1b2a
ok: theme.mode = light
ok: theme.level = mocne
```
Format adjustment (once, as instructed): `qs ipc prop get` prints `#aarrggbb`; literals in 02-theme.sh changed from `#eceaf2`/`#1e1b2a` to `#ffeceaf2`/`#ff1e1b2a`.

## Deviation from the brief: `onAccent` Behavior (important)
`Behavior on onAccent { ... }` segfaults Quickshell 0.3.2 / Qt 6.12 (crash in `QQmlData::deferData` while the Theme singleton is created; QML parses `onAccent` as a signal handler). Bisected: 20 Behaviors OK, 21st (`onAccent`) crashes; removing only that one fixes it. Workaround in Theme.qml: animated helper `onAccentFade` (+ Behavior) and `readonly property color onAccent: root.onAccentFade`. `Theme.onAccent` still exists and still crossfades. Any later property/Behavior named `on<Capital>…` hits the same trap.

## Incident (needs controller attention)
The first smoke run (before the fix) crashed the test instance; Quickshell's crash handler spawned a reporter process (PID 170095, `/usr/bin/quickshell`, parent 726, still running when I handed back) that I could not kill: `kill`/`qs kill --pid` were denied by the permission classifier. It is not a registered instance (`qs list --all` shows only the user's live shell, PID 921), but it may show a crash-reporter window; the user/controller may need to close it (`kill 170095`). The live shell (921) was never touched; I only ran `qs kill -p <worktree dir>` and `-p /tmp/qsb` (scratch config for bisecting, outside the repo). Subsequent runs used `QS_DISABLE_CRASH_HANDLER=1` (exported in my shell only; smoke.sh unchanged). Recommend the harness gets this env var too (not changed here: out of scope) — without it a crashing config makes smoke.sh hang on the reporter.

## Files
`config/quickshell/`: `lib/theme.js`, `Theme.qml`, `Wallpaper.qml`, `shell.qml` (M), `tests/theme.test.mjs`, `tests/smoke/02-theme.sh`.

## Self-review / concerns
- `Wallpaper.qml` keeps `color: "black"` (named colour, passes no-magic since it only matches hex/rgba; no `Theme` token for it). Flag if it should become a token.
- Wallpaper rendering was not visually verified (no screenshots in this task); the smoke log was clean (no warnings) with the fixture's `~/.config/dotfiles/wp2.jpg` (symlink exists).
- `card` for `subtelne` is given explicitly (`#1F1E2A` dark / `#F3F1F6` light, R4) rather than falling back to `sel` (brief's "level's card or sel").
- `lockGlass` light and `lockField` light are derived (islandBg / tile) when palette lacks them (R6).
- `tests/smoke/02-theme.sh` is mode 644 like 00-start.sh (sourced, not executed).
- No new allowed-warnings patterns added.
