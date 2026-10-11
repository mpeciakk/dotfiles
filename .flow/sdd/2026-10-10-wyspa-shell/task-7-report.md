# Task 7 report: Line icons

Commit: 907aaac `quickshell: line icons drawn with Shape paths`

## Implemented
- `lib/icons.js`: `var paths`, 28 icons (all names the test lists), 24 grid, one `d` string each, every sub-path starts with an absolute `M`.
- `components/Icon.qml`: `name`, `color: Theme.fg`, `size` (default `Theme.sizes.iconGrid`, so no divide-by-zero). A `Shape` of 24x24, `scale: size/24`, `transformOrigin: TopLeft`, `preferredRendererType: CurveRenderer` (AA without MSAA), one `ShapePath` with round cap/join, `fillColor: "transparent"`, `PathSvg { path: I.paths[name] ?? "" }`. The Shape scale transform does scale the stroke, so `strokeWidth = Theme.sizes.iconStroke * grid / size` (the brief's compensation).
- `lib/theme.js`: new token `sizes.iconGrid: 24` (needed because `no-magic` forbids the literal 24 in components/); asserted in `tests/theme.test.mjs`.
- `components/Icon.qml` needs `import ".."` to see the `Theme` singleton (without it: `ReferenceError: Theme is not defined`, seen in the first probe run). First use of a subdirectory component in this config, so later components/ files need the same import.

## Path provenance
- Prototype (reference §5), verbatim: bell (body only, no clapper), moon, power, check, x, arrow-right, pause (as lines), skip-back, skip-forward (mirror: x -> 24-x), search (circle (11,11) r7 as arc path + `m20 20-3.5-3.5`), bluetooth, volume-1 (speaker + arc), wifi (Lucide's 3 arcs, the dot dropped per "3 arcs (no dot)").
- volume-2 / volume-x: composed, not copied: prototype speaker body + prototype inner arc + Lucide's outer arc (`M19.364 18.364a9 9 0 0 0 0-12.728`) / Lucide's x lines. Done so the speaker silhouette does not change when the OSD icon changes between volume-1/-2/-x.
- Lucide (the plan's "otherwise"): sun, sun-moon, play, lock, log-out, rotate-ccw, calculator, terminal, app-window, battery, battery-charging, chevron-down, chevron-up. Source: `lucide-static` 1.55.0 tarball from the npm registry (`https://registry.npmjs.org/lucide-static/-/lucide-static-1.55.0.tgz`, ISC licence, extracted to /tmp/lucide-pkg), `icons/<name>.svg`. No Lucide copy was installed locally. Conversions: `<circle>` and `<rect rx>` -> arc paths, `<line>` -> `M..H/V`, leading `m` -> `M`, implicit lineto after `m` -> explicit `l`. A throwaway script confirmed every Lucide `<path d>` occurs verbatim in my strings except those with an `m` -> `M`+`l` rewrite (checked by eye) and the intentional deviations above.
- The prototype gives only rough geometry for lock (rect 14x10 rx2) and battery (rect 17x10 rx2.5) with no coordinates, so I used Lucide's lock and battery rather than inventing positions.

## TDD evidence
- RED (stub `var paths = {};`): `node --test tests/icons.test.mjs` -> failures `actual: 'undefined', expected: 'string'`, `Cannot read properties of undefined (reading 'slice')`, `... (reading 'includes')`. Expected: icons not defined yet.
- RED for the token: `node --test tests/theme.test.mjs` -> `actual: undefined, expected: 24` (iconGrid missing).
- GREEN: `node --test tests/` -> `tests 24, pass 24, fail 0`, output pristine.
- Added one test beyond the brief: "sub-paths of one d string start with an absolute M" (no `m` after position 0), since a relative `m` inside a concatenated `d` would start from the previous sub-path's end.

## Visual check (2 live shots used: both of one probe check file, first one failed on the missing Theme import)
- Probe: temporary `Rectangle` (black backdrop) with `Icon` bell 24, bell 48 (both `Theme.accent`) and volume-2 96 inside Island.qml; one-off check file with a single `shot`. Read `/tmp/wyspa-shots/icon-probe.png`: crisp accent bell/speaker, round caps, and the stroke has the same thickness (~1.6 logical px) at 24, 48 and 96. Smoke run 2 logged no warnings. After every run `qs list --all` printed "No running instances". Probe and check file removed; `Island.qml` is byte-identical to HEAD.
- Only the rest area was not literally used: the island is 36 px high, too small for a 48 px probe, so the probe sat just under it on the stage.

## Files changed
`config/quickshell/lib/icons.js` (new), `components/Icon.qml` (new), `tests/icons.test.mjs` (new), `lib/theme.js` (+`iconGrid: 24`), `tests/theme.test.mjs` (+1 assertion).

## Self-review / concerns
- Stroke is constant in on-screen px (as the brief and lead require). In the prototype's plain SVG `viewBox` scaling the 1.6 stroke would scale with size (18 px icon -> 1.2 px). If the intended look is the prototype's, drop the `* grid / size` compensation; one line.
- wifi has no dot (prototype wording); if the dot is wanted, append `M12 20h.01`.
- volume-2/-x and several others differ from stock Lucide on purpose (see provenance).
- Icon.qml was not loaded by the real shell yet (only through the probe); no consumer exists until later tasks.

## Fix round 1 (review: Important lock/rotate-ccw + Minor battery)

The earlier justification ("prototype gives no coordinates for lock/battery") was wrong: reference §3.8 (~515, 518) and §5/~566 give the coordinates.

Changes in `config/quickshell/lib/icons.js`:
- `lock`: rect x5 y11 w14 h10 rx2 converted to a closed path (`M7 11H17a2 2 0 0 1 2 2V19a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V13a2 2 0 0 1 2-2z`; corner arcs checked by hand, all four end on the rect edges) + shackle `M8 11V8a4 4 0 0 1 8 0v3`.
- `rotate-ccw`: `M3 12a9 9 0 1 0 3-6.7L3 8M3 3v5h5`.
- `battery`: rect x2 y7 w17 h10 rx2.5 as a closed path + cap `M22 11v2`.
- `battery-charging` (same root cause, kept consistent): stock Lucide has a 16x12 body (y6..18, x2..18) and cap `M22 14v-4`, so swapping battery <-> battery-charging would make the body jump (1px right edge, 2px height). Rebuilt the two body halves on the new rect (y7..17, right edge x19, r2.5, same gap x-coordinates around the unchanged bolt `M11 7l-3 5h4l-3 5`) and the prototype cap `M22 11v2`. The bolt itself is stock Lucide (the reference gives none).
- `log-out` already carried the §3.8 data (reordered, `m` -> `M`); left as is, now covered by the test.

Test (`config/quickshell/tests/icons.test.mjs`): extended "prototype paths are kept verbatim" with moon, bluetooth, x, arrow-right, pause, skip-back, search; added "reference 3.8 / 5 icons carry the prototype geometry, not stock Lucide" asserting lock, log-out, rotate-ccw, battery (body + cap) and battery-charging (cap + body edge).

RED (before the icons.js edit), `cd config/quickshell && node --test 'tests/*.test.mjs'`:
```
ℹ tests 25   ℹ pass 24   ℹ fail 1
✖ reference 3.8 / 5 icons carry the prototype geometry, not stock Lucide
  assert.ok(I.paths.lock.includes("M7 11H17a2 2 0 0 1 2 2V19a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V13a2 2 0 0 1 2-2z"))
```
GREEN (after):
```
✔ every icon the shell uses is a path d string
✔ sub-paths of one d string start with an absolute M
✔ prototype paths are kept verbatim
✔ reference 3.8 / 5 icons carry the prototype geometry, not stock Lucide
ℹ tests 25   ℹ pass 25   ℹ fail 0
```
Full suite = this command (all tests/*.test.mjs): 25/25.

Concern (not changed): the `// Lucide` group comment in icons.js now sits above lock/log-out/rotate-ccw/battery*, which are prototype-derived; the grouping is slightly stale.
