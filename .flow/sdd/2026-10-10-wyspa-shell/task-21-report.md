# Task 21 report: automatic theme mode + legibility boost

Status: DONE_WITH_CONCERNS. Commit `6a80bd0` "quickshell: automatic theme mode (sun, wallpaper) and legibility boost" (branch worktree-feat+wyspa-shell).

## Implemented
- `lib/autotheme.js` (new, `.pragma library`): `sunTimes(date, lat, lon)` (NOAA approximation; the day is the local solar day, so at lon +-180 the sunrise may fall on the previous UTC day but is always < sunset; null for polar day/night, null/undefined/""/NaN/non-numeric/out-of-range lat/lon, invalid date; numeric strings accepted), `luminance(r,g,b)` (Rec. 709, sRGB-linearised, 0..255 in), `nextMode(current, lum, lightAbove, darkBelow)` (hysteresis; with no current mode the dead band splits at its middle, so the first evaluation is deterministic), and `islandCrop(imgW, imgH, scrW, scrH, regionW, regionH)` (the island's footprint in wallpaper pixels, given cover-crop of the image to the screen; needed to feed `ColorQuantizer.imageRect`).
- `services/AutoTheme.qml` (new singleton): `mode` ("sun" -> light between sunrise and sunset from a `SystemClock` with minute precision, "" with no location / polar; "wallpaper" -> `nextMode` over the mean colour of `Theme.wallpaper` from `ColorQuantizer { depth: 0; rescaleSize }`), `boost` = `Theme.mode === "dark"` and luminance of the quantized island region > `legibility.threshold`. A `Binding` writes `Theme.autoMode` and `Theme.legibilityBoost`. The region comes from a second `ColorQuantizer` with `imageRect` = `islandCrop(...)` of `geom.rest` on the first screen; a hidden `Image` (`probe`) only provides the native image size.
- `Theme.qml`: new writable `legibilityBoost` (same pattern as `autoMode`: AutoTheme writes into Theme, so Theme does not import `services/`, avoiding a Theme <-> AutoTheme import cycle); the `islandBg` mirror's input is `legibilityBoost ? T.raiseAlpha(root.c.islandBg, legibility.boost) : root.c.islandBg` (still one property + one Behavior); `islandBg` exposed read-only on the `theme` IpcHandler (the smoke needs it).
- `lib/theme.js`: `raiseAlpha(c, by)` and token `legibility.sampleSize: 64` (the rescale size; Global Constraints require tokens for values).
- `shell.qml`: `AutoTheme.mode;` in `Component.onCompleted` plus comment.
- Tests: `tests/autotheme.test.mjs` (the brief's 4 tests verbatim, plus 12 pins), 2 added to `tests/theme.test.mjs`, `tests/smoke/21-auto.sh`.

## TDD evidence
RED
- `node --test tests/autotheme.test.mjs` with a `.pragma library`-only stub: `ℹ pass 0 / ℹ fail 16`; every failure `TypeError: A.sunTimes|luminance|nextMode|islandCrop is not a function` (feature missing, as expected).
- `node --test tests/theme.test.mjs` before the edit: 2 fail (`T.raiseAlpha is not a function`; `defaults.legibility.sampleSize` undefined), 24 pass.
- `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh tests/smoke/21-auto.sh` before the service/Theme changes: `FAIL: theme.islandBg ... got 'Property not found.'` (x2), and `FAIL: theme.mode expected 'light' got 'dark'` for the brief's wallpaper step and both sun steps. `qs list --all` afterwards: no running instances.

GREEN
- `node --test 'tests/*.test.mjs'`: 204 tests, 204 pass, 0 fail (autotheme 16/16).
- `tests/smoke/21-auto.sh` (10 `ok:` lines, no FAIL, no logged warnings): dark wallpaper -> dark, islandBg `#47161224` (no boost); bright wallpaper -> light (within 1.5 s, as in the brief), islandBg `#70eae6f0` (light, unboosted); `setMode dark` over the bright wallpaper -> islandBg `#7a161224` (alpha 0x47 -> 0x7a, +0.2); bright wallpaper with a dark central column -> `#47161224` again (only the area under the island counts; shows the crop wiring); sun without location falls back to the configured mode; sun on the equator at the longitude of solar noon now / solar midnight now gives light / dark against the opposite configured mode.
- `tests/smoke/02-theme.sh`, `00-start.sh`, `16-control.sh`: all clean (manual mode unaffected, no warnings). `qs list --all` was empty after every run. 06/09 were not run (a fullscreen game may break them via line mode; not required here).

## Note on the edited Warsaw June expectation
The dispatch's extra pin said Warsaw June sunset ~20:15 CEST (18:15 UTC). That value is wrong; I changed the expectation to 21:00 CEST (19:00 UTC) after the first GREEN run failed on it (`sunset: 19 vs 18.25`). Independent check, not from my code: at 52.2 N on the June solstice the day is about 16 h 45 min (a 04:14 sunrise + 16:45 = 20:59 CEST = 18:59 UTC); the 04:15 -> 20:15 pairing would be a 16 h day, which belongs to roughly 49 N. The December pin (07:40 / 15:25 CET) was correct and passes untouched; the brief's own four tests were not edited.

## Findings from probing the ColorQuantizer API (scratch instance, since removed)
Verified against qmltypes (`/usr/lib/qt6/qml/Quickshell/quickshell-core.qmltypes`), context7 docs, and a scratch qml with a 400x200 left-white/right-black PNG: `imageRect` is in SOURCE-image pixels and crop happens before rescale (left half -> `#ffffff`, right half -> `#000000`, full -> `#808080`, 100x20 strip across the middle -> `#808080`); `colors` is `list<color>` (2^depth entries, so one at depth 0); a missing file logs `WARN quickshell.colorquantizer: Failed to load image` and gives an empty list, so AutoTheme keeps `source: ""` while a quantizer is not needed (no warning is logged for an empty source; the smoke would fail on one); `colorsChanged` fires twice per load (harmless). A hidden `Image` outside a scene reports `Ready` and the native `sourceSize` (400x200).

## Files changed
`config/quickshell/lib/autotheme.js`, `services/AutoTheme.qml`, `tests/autotheme.test.mjs`, `tests/smoke/21-auto.sh` (new); `Theme.qml`, `lib/theme.js`, `shell.qml`, `tests/theme.test.mjs` (modified).

## Self-review
- Zero-magic: services are not covered by `no-magic.test.mjs`, but all numbers still come from tokens (`sampleSize`, `geom.rest`, thresholds); the 255 in `luminanceOf` is the colour scale.
- No property or Behavior named `on<Capital>`; `Theme.islandBg` keeps its single mirror.
- The live `~/.config/dotfiles/config.json` was never touched; only `$CFG` was written. No screenshots, no notify-send, no lock, no niri actions.

## Concerns
1. The luminance is the Rec. 709 luminance of the *sRGB-space mean* colour (ColorQuantizer averages sRGB values), so mid-grey 128 gives 0.216; the 0.6/0.5 thresholds therefore trigger at an sRGB mean of about 203/188. This follows the brief literally; flagging it in case the thresholds are meant for a perceptual scale.
2. The `probe` Image decodes the wallpaper at native resolution (e.g. 4K ~33 MB) just to read `sourceSize`; QML has no cheaper way (setting `sourceSize` would report the requested size).
3. The boost uses the first screen's aspect ratio and `geom.rest` (200x36) only; it is one global bool. Other states (wider islands) and other screens are not sampled.
4. `wallpaperMode` keeps its last value when `modeSource` leaves and re-enters "wallpaper": the first evaluation then uses the stale hysteresis state (deterministic, harmless).
5. The brief says Theme.qml reads `AutoTheme.boost`; it reads `Theme.legibilityBoost`, written by AutoTheme (same reason as `autoMode`: Theme does not import services). Behaviour is as specified.
6. Polar day/night (sunTimes null) yields mode "" (falls back to `island.mode`), because null does not tell day from night.
