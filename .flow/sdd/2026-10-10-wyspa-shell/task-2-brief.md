## Global Constraints

- All paths below are relative to `config/quickshell/` inside the worktree; run every command from that directory.
- No Caelestia or other external shell modules. Version-less imports (`import QtQuick`, `import Quickshell`).
- **Zero magic numbers / colours in UI QML** (root `*.qml` except `Theme.qml`, `states/`, `components/`): every px, ms, colour, opacity and font size comes from `Theme`. Allowed literals: `0`, `1`, `2`, `0.5`. Enforced by `tests/no-magic.test.mjs`. A value the task needs that is not yet a token → add it to `lib/theme.js` `defaults` under `layout.<state>` (state-specific) or the matching global group, with the value from the reference doc.
- Colours in `lib/theme.js` are produced as lowercase `#aarrggbb` strings (QML `color` cannot parse CSS `rgba()`).
- `lib/*.js` files start with `.pragma library`, never `.import` other files, and export only via top-level `function` and `var` (the node loader exposes only those).
- Fonts: `Theme.fonts.ui` / `Theme.fonts.mono`, default `"JetBrainsMono Nerd Font"` for both (W5).
- Icons: only via `components/Icon.qml` (Lucide-style paths in `lib/icons.js`, stroke `Theme.sizes.iconStroke` = 1.6).
- Out of scope (W8): warm light, screen recording, `/` file search, tray. Do not add niri binds except in Task 22 (W9).
- IPC: `IpcHandler` functions need typed args/returns (`string|int|bool|real|color|void`); only typed properties are readable with `qs ipc prop get`. Instance flags go before the subcommand: `qs ipc -p <dir> call|prop get …`.
- `Region { item: x }` tracks only `x`'s own geometry — animate the item itself. Regions have no concave corners: an ear = rect minus ellipse (`intersection: Intersection.Subtract`).
- **Test mode** (`Quickshell.env("WYSPA_TEST") === "1"`, exported by `tests/smoke.sh`): island keyboard focus is always `WlrKeyboardFocus.None`, power commands only `console.info` what they would run, and the lock action only logs. Every task that adds keyboard focus, a power command or a lock path implements this guard. Never trigger power actions or the session lock from a test.
- **Config path**: `Theme.qml` reads `Quickshell.env("WYSPA_CONFIG")` if set, else `~/.config/dotfiles/config.json`. Smoke runs use a fresh temp copy of `tests/fixtures/config.json` (check files may rewrite that copy; Theme hot-reloads it). Never edit the live `~/.config/dotfiles/config.json` (it is a symlink into the main checkout).
- **Allowed log warnings** live in `tests/smoke/allowed-warnings.txt` (one ERE per line, each preceded by a `#` comment saying why). Adding a pattern requires a justification in the task report; never widen the grep in `smoke.sh`.
- The pre-rewrite code is at commit `ff1f02d` — read it with `git show ff1f02d:config/quickshell/<path>` (never `HEAD~1`).
- niri config is validated only through `tests/niri-validate.sh` (the repo's `config.kdl` includes a per-host `output.kdl` that exists only after dotter deploy).
- Screenshots (`tests/shot.sh`) capture the focused monitor of the user's live session and niri also copies each one to the clipboard — take at most the ones a task asks for.
- Commit after each task with `git add -A .` (plus `../niri` when niri files changed) and a `quickshell:` prefixed message ending in the `Co-Authored-By` trailer the controller provides.


## Group 1 — Theme (gate after Task 2)

---

### Task 2: Theme tokens (dark/light × glass levels) + Theme singleton + wallpaper

**Files:**
- Create: `lib/theme.js`, `Theme.qml`, `Wallpaper.qml`, `tests/theme.test.mjs`, `tests/smoke/02-theme.sh`
- Modify: `shell.qml`

Reference: §1.1–§1.7, §2a, §2b, §7 R1–R12, R16, R23, R34 (theme parts only). DESIGN §3, §3a, §3b.

**Interfaces:**
- Produces (`lib/theme.js`): `var defaults` (token tree, see Step 3); `function rgba(r, g, b, a) → "#aarrggbb"`; `function hex(c) → "#aarrggbb"` (accepts `#rrggbb` / `#aarrggbb`); `function withAlpha(c, a) → "#aarrggbb"`; `function merge(base, over) → new object`; `function resolve(tokens, mode, level, glass) → object` with colour keys `islandBg ring shadowColor lockShadowColor tile sel hover card chip track sliderFill fg fgMuted fgDim fgSoft fgLock accent accentSoft accentHalo focusRing onAccent inverseBg inverseFg danger dotInactive line divider scrimDim lockField lockFieldRing lockGlass sheenTop sheenMid sheenEdge sheenOutline sheenGlow` and number keys `sheen shadowY shadowBlur lockShadowY lockShadowBlur` and object `lockWallpaper {blur, saturate, brightness, scale}`.
- Produces (`Theme.qml`, singleton): `tokens: var`, `host: var` (whole parsed config.json), `mode: string` ("dark"|"light"), `glassLevel: string`, `glass: bool`, `reducedMotion: bool`, `autoMode: string` (writable, "" default — Task 21 sets it), `geom: var`, `motion: var`, `radii: var`, `sizes: var`, `fonts: var`, `layout: var`, `c: var` (= resolve output, target values), one animated `color` property per colour key above (same names, e.g. `Theme.fg`, `Theme.islandBg`), plain `real` props `sheen shadowY shadowBlur lockShadowY lockShadowBlur`, `lockWallpaper: var`, `wallpaper: string` (absolute path), `function setMode(m: string): void`, `function setGlassLevel(l: string): void`. `IpcHandler { target: "theme" }` with `setMode(m: string): void`, `setLevel(l: string): void`, readable `readonly property string mode`, `readonly property string level`, `readonly property color fg`.

- [ ] **Step 1: Write the failing tests** — `tests/theme.test.mjs`:

```js
import { test } from "node:test";
import assert from "node:assert/strict";
import { load, plain } from "./qmljs.mjs";

const T = load("lib/theme.js");

test("rgba() encodes #aarrggbb with rounded alpha", () => {
    assert.equal(T.rgba(16, 14, 26, 0.62), "#9e100e1a");
    assert.equal(T.rgba(255, 255, 255, 0.07), "#12ffffff");
});

test("hex() normalises #rrggbb and #aarrggbb", () => {
    assert.equal(T.hex("#ECEAF2"), "#ffeceaf2");
    assert.equal(T.hex("#80112233"), "#80112233");
});

test("withAlpha() replaces alpha", () => {
    assert.equal(T.withAlpha("#B9A7F5", 0.18), "#2eb9a7f5");
});

test("merge() overrides leaves, keeps siblings, replaces arrays, never mutates", () => {
    const base = { a: { b: 1, c: 2 }, l: [1, 2] };
    assert.deepStrictEqual(plain(T.merge(base, { a: { c: 3 }, l: [9] })), { a: { b: 1, c: 3 }, l: [9] });
    assert.deepStrictEqual(plain(base), { a: { b: 1, c: 2 }, l: [1, 2] });
    assert.deepStrictEqual(plain(T.merge({ a: { b: 1 } }, { a: 5 })), { a: { b: 1 } });
    assert.deepStrictEqual(plain(T.merge({ a: 1 }, null)), { a: 1 });
});

test("defaults: geometry matches DESIGN §4", () => {
    const g = plain(T.defaults.geom);
    assert.deepStrictEqual(g.line, { w: 56, h: 5, r: 3 });
    assert.deepStrictEqual(g.rest, { w: 200, h: 36, r: 18 });
    assert.deepStrictEqual(g.restBadge, { w: 252, h: 36, r: 18 });
    assert.deepStrictEqual(g.osd, { w: 300, h: 44, r: 22 });
    assert.deepStrictEqual(g.media, { w: 380, h: 56, r: 28 });
    assert.deepStrictEqual(g.toast, { w: 420, h: 76, r: 30 });
    assert.deepStrictEqual(g.control, { w: 520, h: 440, r: 30 });
    assert.deepStrictEqual(g.launcher, { w: 680, h: 356, r: 30 });
    assert.deepStrictEqual(g.power, { w: 540, h: 180, r: 30 });
    assert.deepStrictEqual(g.powerDone, { w: 340, h: 56, r: 28 });
    assert.deepStrictEqual(g.center, { w: 440, hMin: 170, hMax: 620, r: 30 });
    assert.deepStrictEqual(g.lock, { w: 460, h: 360, r: 36 });
    assert.equal(g.ear, 16);
    assert.equal(g.exclusive, 36);
    assert.deepStrictEqual(g.hoverZone, { w: 400, h: 28 });
});

test("defaults: motion matches DESIGN §5", () => {
    const m = plain(T.defaults.motion);
    assert.equal(m.morphMs, 460);
    assert.deepStrictEqual(m.morphCurve, [0.32, 0.72, 0, 1, 1, 1]);
    assert.deepStrictEqual(m.enterCurve, [0.2, 0, 0, 1, 1, 1]);
    assert.deepStrictEqual(m.easeCurve, [0.25, 0.1, 0.25, 1, 1, 1]);
    assert.equal(m.lockMorphMs, 640);
    assert.equal(m.themeFadeMs, 600);
    assert.equal(m.sheenFadeMs, 300);
    assert.equal(m.osdTimeoutMs, 1600);
    assert.equal(m.toastTimeoutMs, 3600);
    assert.equal(m.holdMs, 900);
    assert.equal(m.reducedFadeMs, 120);
});

test("defaults: choices", () => {
    assert.equal(T.defaults.mode, "dark");
    assert.equal(T.defaults.modeSource, "manual");
    assert.equal(T.defaults.glassLevel, "ciekłe");
    assert.equal(T.defaults.glass, true);
    assert.equal(T.defaults.reducedMotion, false);
    assert.equal(T.defaults.fonts.ui, "JetBrainsMono Nerd Font");
    assert.equal(T.defaults.fonts.mono, "JetBrainsMono Nerd Font");
    assert.equal(T.defaults.sizes.iconStroke, 1.6);
});

test("resolve(): dark ciekłe", () => {
    const c = plain(T.resolve(T.defaults, "dark", "ciekłe", true));
    assert.equal(c.islandBg, T.rgba(22, 18, 36, 0.28));
    assert.equal(c.tile, T.rgba(255, 255, 255, 0.07));
    assert.equal(c.sel, T.rgba(255, 255, 255, 0.12));
    assert.equal(c.chip, T.rgba(255, 255, 255, 0.14));
    assert.equal(c.card, c.sel);
    assert.equal(c.hover, c.sel);
    assert.equal(c.track, c.chip);
    assert.equal(c.sliderFill, c.fg);
    assert.equal(c.sheen, 1);
    assert.equal(c.fg, T.hex("#ECEAF2"));
    assert.equal(c.fgMuted, T.hex("#A29DB3"));
    assert.equal(c.accent, T.hex("#B9A7F5"));
    assert.equal(c.accentSoft, T.withAlpha("#B9A7F5", 0.18));
    assert.equal(c.onAccent, T.hex("#121118"));
    assert.equal(c.danger, T.hex("#F2A7B8"));
    assert.equal(c.ring, T.rgba(255, 255, 255, 0.07));
    assert.equal(c.shadowColor, T.rgba(10, 6, 20, 0.5));
    assert.equal(c.shadowY, 18);
    assert.equal(c.shadowBlur, 60);
    assert.equal(c.sheenTop, T.rgba(255, 255, 255, 0.12));
    assert.equal(c.sheenMid, T.rgba(255, 255, 255, 0.02));
    assert.equal(c.sheenEdge, T.rgba(255, 255, 255, 0.22));
    assert.equal(c.sheenOutline, T.rgba(255, 255, 255, 0.1));
    assert.equal(c.sheenGlow, T.rgba(255, 255, 255, 0.06));
    assert.deepStrictEqual(c.lockWallpaper, { blur: 22, saturate: 1.2, brightness: 0.78, scale: 1.08 });
});

test("resolve(): light subtelne and light mocne", () => {
    const s = plain(T.resolve(T.defaults, "light", "subtelne", true));
    assert.equal(s.islandBg, T.rgba(230, 226, 236, 0.8));
    assert.equal(s.tile, T.hex("#EFECF3"));
    assert.equal(s.sel, T.hex("#F3F1F6"));
    assert.equal(s.card, T.hex("#F3F1F6"));
    assert.equal(s.chip, T.hex("#DDD9E5"));
    assert.equal(s.track, T.hex("#CFCADA"));
    assert.equal(s.sheen, 0);
    assert.equal(s.fg, T.hex("#1E1B2A"));
    assert.equal(s.accent, T.hex("#5E48B8"));
    assert.equal(s.onAccent, T.hex("#FFFFFF"));
    assert.equal(s.danger, T.hex("#B4405E"));
    assert.equal(s.ring, T.rgba(255, 255, 255, 0.55));
    assert.equal(s.shadowColor, T.rgba(40, 30, 70, 0.2));
    assert.equal(s.shadowBlur, 50);
    assert.equal(s.sheenGlow, T.rgba(255, 255, 255, 0));
    assert.deepStrictEqual(s.lockWallpaper, { blur: 18, saturate: 1.2, brightness: 0.92, scale: 1.08 });
    const m = plain(T.resolve(T.defaults, "light", "mocne", true));
    assert.equal(m.islandBg, T.rgba(232, 228, 238, 0.58));
    assert.equal(m.tile, T.rgba(255, 255, 255, 0.42));
    assert.equal(m.chip, T.rgba(30, 27, 42, 0.08));
    assert.equal(m.sheen, 0.5);
});

test("resolve(): solid fallback and unknown level", () => {
    const c = plain(T.resolve(T.defaults, "dark", "ciekłe", false));
    assert.equal(c.islandBg, T.rgba(16, 14, 26, 0.78));
    assert.equal(c.tile, T.hex("#17161F"));
    assert.equal(c.sel, T.hex("#1E1D28"));
    assert.equal(c.sheen, 0);
    const u = plain(T.resolve(T.defaults, "dark", "nope", true));
    assert.equal(u.islandBg, T.rgba(22, 18, 36, 0.28));
});

test("resolve(): config overrides flow through merge", () => {
    const tokens = T.merge(T.defaults, { palette: { dark: { accent: "#8FD3C1" } } });
    assert.equal(T.resolve(tokens, "dark", "ciekłe", true).accent, T.hex("#8FD3C1"));
});
```

- [ ] **Step 2: Run** — first create the stub `lib/theme.js` (`.pragma library` + `var defaults = {};`), then `node --test tests/theme.test.mjs` → Expected: FAIL in every test with TypeErrors/assertions on missing functions and values (not a load error).

- [ ] **Step 3: Implement `lib/theme.js`**

  `defaults` groups: `mode`, `modeSource` ("manual"|"sun"|"wallpaper"), `location {lat: null, lon: null}`, `wallpaperLight 0.6`, `wallpaperDark 0.5`, `legibility {threshold: 0.7, boost: 0.2}`, `glass`, `glassLevel`, `reducedMotion`, `fonts`, `sizes` (`iconStroke 1.6`, `ringWidth 1`, font sizes from §1.4 as `text10 … text88` is NOT the naming — use semantic names as they get used: start with `clockRest 13`), `geom` (Step 1 values), `radii` (§1.6), `motion` (§1.7 values incl. `enterOpacityMs 220`, `enterOpacityDelayMs 160`, `enterScaleMs 320`, `enterScaleDelayMs 120`, `exitOpacityMs 120`, `exitScaleMs 160`, `exitBlurMs 120`, `enterBlurMs 220`, `enterBlurDelayMs 160`, `contentScaleFrom 0.94`, `contentBlur 6`, `earFadeMs 160`, `bgColorMs 200`, `osdBarMs 260`, `toastBarMs 3400`, `toastBarDelayMs 60`, `lineLeaveDelayMs 250`, `mediaLeaveMs 250`, `holdCancelMs 220`, `powerDoneMs 1800`, `dimMs 400`, `stackPadMs 300`, `buttonBgMs 200`, `eqMs 900`, `shakeMs 380`, `shakeCurve [0.36,0.07,0.19,0.97,1,1]`, `wallpaperMs 700`), `palette.dark` / `palette.light` (every non-glass colour from §1.1 + R6/R8/R9 invented values, as `#rrggbb` or `rgba()` calls), `glassLevels.<level>.<mode>` = `{bg, tile, sel, chip, card?, sheen}` (§1.2 + R4), `solid.<mode>` = `{bg, tile, sel, chip, card}` (R2), `sheen.<mode>` = `{top, mid, edge, outline, glow}` (§2a + R23), `shadow.<mode>` = `{y, blur, color}`, `lockShadow.<mode>` = `{y, blur, color}` (R3), `lockWallpaper.<mode>` (R10), `layout: {}` (state tasks fill it). Accent alternatives as a comment (R7).
  `resolve()` picks `palette[mode]`, overlays `glassLevels[level][mode]` (unknown level → `ciekłe`; `glass=false` → `solid[mode]`, sheen 0), derives `card` (level's `card` or `sel`), `hover = sel` (R6), `track` (dark: `chip`; light: palette `track`), `sliderFill = fg`, `accentSoft/accentHalo/focusRing` from `accent`, and normalises every colour through `hex()`.
  `merge()`: recursive for plain objects only; arrays and primitives in `over` replace; a non-object `over` for an object node is ignored; `null`/`undefined` `over` → copy of `base`.

- [ ] **Step 4: Run** — `node --test tests/theme.test.mjs` → Expected: PASS.

- [ ] **Step 5: Write the smoke check** — `tests/smoke/02-theme.sh`:

```bash
expect theme mode dark
expect theme level ciekłe
expect theme fg "#eceaf2"
call theme setMode light
wait_ms 120
MID="$(qs ipc -p "$DIR" prop get theme fg)"
if [ "$MID" == "#eceaf2" ] || [ "$MID" == "#1e1b2a" ]; then echo "FAIL: fg did not crossfade (got $MID at 120 ms)"; FAILED=1; else echo "ok: crossfade mid value $MID"; fi
wait_ms 700
expect theme fg "#1e1b2a"
expect theme mode light
call theme setLevel mocne
expect theme level mocne
```

  (If `prop get` prints colours in another format, e.g. `#ffeceaf2`, adjust the literals in this file once to the real format and note it in the report.)

- [ ] **Step 6: Run** — `tests/smoke.sh tests/smoke/02-theme.sh` → Expected: FAIL (`theme` target not found).

- [ ] **Step 7: Implement `Theme.qml`, `Wallpaper.qml`, `shell.qml`**

  `Theme.qml` pattern (the first instance of the animated-colour mirror — follow exactly, one property + Behavior per colour key):

```qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "lib/theme.js" as T

Singleton {
    id: root

    property var host: ({})
    property string modeOverride: ""
    property string levelOverride: ""
    property string autoMode: ""

    readonly property var tokens: T.merge(T.defaults, root.host.island ?? null)
    readonly property string mode: root.modeOverride || root.autoMode || root.tokens.mode
    readonly property string glassLevel: root.levelOverride || root.tokens.glassLevel
    readonly property bool glass: root.tokens.glass
    readonly property bool reducedMotion: root.tokens.reducedMotion
    readonly property var c: T.resolve(root.tokens, root.mode, root.glassLevel, root.glass)
    readonly property var geom: root.tokens.geom
    readonly property var motion: root.tokens.motion
    readonly property var radii: root.tokens.radii
    readonly property var sizes: root.tokens.sizes
    readonly property var fonts: root.tokens.fonts
    readonly property var layout: root.tokens.layout
    readonly property var lockWallpaper: root.c.lockWallpaper
    readonly property string wallpaper: { const p = root.host.wallpaper ?? "~/.config/dotfiles/wp2.jpg"; return p.startsWith("~") ? Quickshell.env("HOME") + p.slice(1) : p; }

    function setMode(m: string): void { root.modeOverride = m; }
    function setGlassLevel(l: string): void { root.levelOverride = l; }

    property color fg: root.c.fg
    Behavior on fg { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    // … same two lines for every colour key listed in Interfaces …

    property real sheen: root.c.sheen
    Behavior on sheen { NumberAnimation { duration: root.motion.sheenFadeMs; easing.type: Easing.BezierSpline; easing.bezierCurve: root.motion.easeCurve } }
    readonly property real shadowY: root.c.shadowY
    // … shadowBlur, lockShadowY, lockShadowBlur …

    FileView {
        path: Quickshell.env("WYSPA_CONFIG") || `${Quickshell.env("HOME")}/.config/dotfiles/config.json`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { root.host = JSON.parse(text()); } catch (e) { root.host = ({}); } }
        onLoadFailed: root.host = ({})
    }

    IpcHandler {
        target: "theme"
        readonly property string mode: root.mode
        readonly property string level: root.glassLevel
        readonly property color fg: root.fg
        function setMode(m: string): void { root.setMode(m); }
        function setLevel(l: string): void { root.setGlassLevel(l); }
    }
}
```

  `Wallpaper.qml`: port `git show ff1f02d:config/quickshell/modules/Wallpaper.qml` (one `PanelWindow` per screen, `WlrLayer.Background`, namespace `quickshell-wallpaper`, click-through), source `"file://" + Theme.wallpaper`. `shell.qml`: `Variants { model: Quickshell.screens; Wallpaper {} }`.

- [ ] **Step 8: Run all** — `node --test 'tests/*.test.mjs' && tests/smoke.sh tests/smoke/02-theme.sh` → Expected: PASS.

- [ ] **Step 9: Commit** — `quickshell: Theme tokens (dark/light, glass levels) with config overrides`

**— USER GATE 1 —** test: `qs ipc -p <wt>/config/quickshell call theme setMode light|dark`, `… setLevel subtelne|mocne|ciekłe`; wallpaper shows; for the override test run the gate instance with `WYSPA_CONFIG=/tmp/wyspa-gate.json` (a copy of the live config) and add `"island": {"palette": {"dark": {"accent": "#8FD3C1"}}}` there — hot-reloads. The live config is never edited mid-branch.

---
