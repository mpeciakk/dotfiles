# Task 3 report: Island geometry + priority logic

Status: DONE. Commit 7b1e2bc "quickshell: island geometry and priority logic".

## Implemented
`config/quickshell/lib/island.js` (`.pragma library`): `PRIORITY`, `accepts`, `isModal`, `radiusFor`, `geometry`.
- `accepts`: next=="rest" -> true; unknown next -> false; else PRIORITY[next] >= PRIORITY[current].
- `isModal`: launcher/control/power/center.
- `geometry`: center clamps ctx.centerHeight to [hMin,hMax], r = min(h/2, r); rest/unknown -> rest or restBadge by ctx.badge; other known states (incl. line) copied from table; ears = state !== "line".
- Internal helper `MODAL` is an extra top-level `var` (also exported by the loader, harmless).

## TDD evidence
RED: `node --test tests/island.test.mjs` with stub (`.pragma library` only) -> every test failed:
`TypeError: I.geometry is not a function` (x6), `I.accepts is not a function`, `I.isModal is not a function`, `I.radiusFor is not a function`. Expected: functions absent.
GREEN: same command -> `tests 9, pass 9, fail 0`. Full `node --test tests/` -> `tests 21, pass 21, fail 0`, output clean.

## Tests
Brief's tests verbatim plus one added assertion test: geometry over `load("lib/theme.js").defaults.geom` for rest and launcher returns the same numbers as the fixture.

## Files changed
- config/quickshell/lib/island.js (new)
- config/quickshell/tests/island.test.mjs (new)

## Self-review
Matches brief. Unknown-state detection uses `state in PRIORITY` (plus "line") rather than `state in geom`, because the real geom also holds non-state keys (ear, exclusive, hoverZone, lock).

## Concerns
- `geometry("restBadge", ...)` is treated as unknown and resolves via ctx.badge (not a real state); `geometry("lock", ...)` also falls back to rest (lock is not an island state per the brief).
- Passing `ctx` is required (reads ctx.badge / ctx.centerHeight); callers must pass `{}` at minimum. A missing centerHeight for "center" yields NaN height.
