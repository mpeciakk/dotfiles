# Wyspa (Quickshell island shell) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current Quickshell config (left bar + drawers) with "Wyspa": one glass island at the top edge of each monitor that morphs between rest / osd / media / toast / center / launcher / control / power / powerDone / lock / line, dark + light themes, three glass levels.

**Architecture:** Pure logic lives in `lib/*.js` (QML `.pragma library`, unit-tested with `node --test`). Two root singletons: `Theme.qml` (tokens = `lib/theme.js` defaults deep-merged with the `island` key of `~/.config/dotfiles/config.json`, animated colour mirrors) and `IslandState.qml` (state machine + `IpcHandler "island"`). Per screen: `Island.qml` (full-screen overlay layer surface, mask = shape, blur region = shape) drawing `IslandShape.qml` and hosting `IslandContent.qml`, which cross-fades one `states/*.qml` layer per state; `Strut.qml` reserves the 36 px exclusive zone. Integration is verified by `tests/smoke.sh` (starts the config as its own instance, drives it over IPC, asserts IPC props, fails on any logged warning) and by screenshots read by the implementer.

**Tech Stack:** Quickshell 0.3.2 (Arch), Qt 6.12 (QtQuick, QtQuick.Shapes, QtQuick.Effects), niri 26.04 (biri fork), node 26 (`node:test`), bash, python3 + PIL (screenshot crop).

**Spec:** `/home/m/dotfiles/config/quickshell/docs/DESIGN.md` — decisions W1–W10 (§2 "Decyzje wdrożeniowe"), §3a light theme, §3b glass levels.

**Design record / measurements:** `/home/m/dotfiles/.flow/specs/2026-10-10-wyspa-reference.md` — every px/colour/ms per state (§1–§5) and the binding resolutions R1–R35 (§7). Each task names the sections it implements; read only those.

**User gates:** the user tests by hand after each group. The controller STOPS after tasks **2, 6, 9, 10, 12, 15, 17, 18, 19, 22** and, with the user's OK: `systemctl --user stop quickshell` (the old shell), `QSG_RENDER_LOOP=threaded qs -p <wt>/config/quickshell -d`, reports what to test, waits; after the gate: `qs kill -p <wt>/config/quickshell; systemctl --user start quickshell`. Before each autonomous stretch the controller asks the user to keep the session unlocked (the old shell idle-locks after 300 s and `tests/shot.sh` refuses to shoot a locked session).

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

---

## Group 1 — Theme (gate after Task 2)

### Task 1: Clean slate + test harness

**Files:**
- Delete: `modules/` (all), `components/` (all), `services/Colours.qml`, `services/Appearance.qml`, `services/Config.qml`, `services/Vpn.qml` (only the deleted VPN indicator used it; the VPN launcher menu uses `menus/vpn.sh`), `shell.qml` contents (rewritten)
- Keep untouched: `services/{Apps,Audio,Battery,Menus,Network,Niri,Notifs,Players,Time}.qml`, `menus/`, `assets/pam.d/passwd`, `docs/`
- Create: `shell.qml`, `tests/qmljs.mjs`, `tests/no-magic.test.mjs`, `tests/smoke.sh`, `tests/shot.sh`, `tests/niri-validate.sh`, `tests/smoke/00-start.sh`, `tests/smoke/allowed-warnings.txt`, `tests/fixtures/config.json`

**Interfaces:**
- Produces: `load(rel: string, extra?: object) → vm context` and `plain(x) → JSON-roundtripped x` from `tests/qmljs.mjs`; `tests/smoke.sh <check-file>` providing `call <target> <fn> [args…]`, `expect <target> <prop> <value>`, `wait_ms <n>`, `shot <name>`, `$DIR`, `$CFG` (the temp config copy) to the sourced check file; `tests/shot.sh <name>` → prints `/tmp/wyspa-shots/<name>.png`; `tests/niri-validate.sh` → exit 0 iff niri accepts the repo's niri config.

- [ ] **Step 1: Write the guard test** — `tests/no-magic.test.mjs`:

```js
import { test } from "node:test";
import assert from "node:assert/strict";
import { readdirSync, readFileSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const ALLOWED = new Set(["0", "1", "2", "0.5"]);

function uiFiles() {
    const files = readdirSync(root).filter(f => f.endsWith(".qml") && f !== "Theme.qml");
    for (const d of ["states", "components", "modules"]) {
        const p = join(root, d);
        if (existsSync(p))
            for (const f of readdirSync(p))
                if (f.endsWith(".qml")) files.push(join(d, f));
    }
    return files;
}

const strip = src => src.replace(/\/\*[\s\S]*?\*\//g, "").replace(/\/\/.*$/gm, "");

test("UI QML takes colours, sizes and times only from Theme", () => {
    const offenders = [];
    for (const f of uiFiles()) {
        strip(readFileSync(join(root, f), "utf8")).split("\n").forEach((line, i) => {
            if (/^\s*import\s/.test(line)) return;
            if (/#[0-9a-fA-F]{3,8}\b|rgba?\(|Qt\.rgba|Qt\.hsla/.test(line))
                offenders.push(`${f}:${i + 1}: colour literal: ${line.trim()}`);
            const code = line.replace(/"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'|`(?:[^`\\]|\\.)*`/g, '""');
            for (const m of code.matchAll(/(?<![\w.$#])\d+(?:\.\d+)?(?![\w.])/g))
                if (!ALLOWED.has(m[0])) offenders.push(`${f}:${i + 1}: number ${m[0]}: ${line.trim()}`);
        });
    }
    assert.deepEqual(offenders, []);
});
```

- [ ] **Step 2: Run it against the old tree** — `node --test 'tests/*.test.mjs'`
  Expected: FAIL — the assertion lists offenders in `modules/*.qml` / `components/*.qml` (old UI has literals).

- [ ] **Step 3: Write the loader** — `tests/qmljs.mjs`:

```js
import { readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import vm from "node:vm";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");

// Loads a QML JS library (`.pragma library`) into a fresh context. Top-level
// `function`s and `var`s become properties of the returned context.
export function load(rel, extra = {}) {
    const file = join(root, rel);
    const src = readFileSync(file, "utf8").replace(/^\s*\.pragma\s+library\s*$/m, "");
    const ctx = vm.createContext({ console, ...extra });
    vm.runInContext(src, ctx, { filename: file });
    return ctx;
}

// Objects from the vm context have a foreign prototype; normalise before deepStrictEqual.
export const plain = x => JSON.parse(JSON.stringify(x));
```

- [ ] **Step 4: Write the smoke runner** — `tests/smoke.sh` (chmod +x):

```bash
#!/usr/bin/env bash
# Usage: tests/smoke.sh <check-file>
# Starts this config as its own quickshell instance in test mode, sources the
# check file (call / expect / wait_ms / shot, $DIR, $CFG), fails on any logged
# warning or error not listed in tests/smoke/allowed-warnings.txt, and always
# kills the instance.
set -uo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
FAILED=0
export WYSPA_TEST=1 QSG_RENDER_LOOP=threaded
CFG="$(mktemp /tmp/wyspa-config.XXXXXX.json)"
cp "$DIR/tests/fixtures/config.json" "$CFG"
export WYSPA_CONFIG="$CFG"
trap 'qs kill -p "$DIR" >/dev/null 2>&1; rm -f "$CFG"' EXIT

call() { qs ipc -p "$DIR" call "$@" >/dev/null 2>&1 || { echo "FAIL: call $*"; FAILED=1; }; }
expect() {
    local got
    got="$(qs ipc -p "$DIR" prop get "$1" "$2" 2>&1)"
    if [ "$got" == "$3" ]; then echo "ok: $1.$2 = $3"; else echo "FAIL: $1.$2 expected '$3' got '$got'"; FAILED=1; fi
}
wait_ms() { sleep "$(awk "BEGIN{print $1/1000}")"; }
shot() { "$DIR/tests/shot.sh" "$1" || FAILED=1; }

qs kill -p "$DIR" >/dev/null 2>&1
qs -p "$DIR" -d >/dev/null 2>&1
sleep 2
# shellcheck source=/dev/null
source "$1"
LOG="$(qs log -p "$DIR" 2>&1)"
BAD="$(printf '%s\n' "$LOG" | grep -E '\b(WARN|ERROR|FATAL|CRIT)' | grep -v -E -f <(grep -v -E '^\s*(#|$)' "$DIR/tests/smoke/allowed-warnings.txt") || true)"
if [ -n "$BAD" ]; then echo "FAIL: instance logged:"; echo "$BAD"; FAILED=1; fi
exit $FAILED
```

  `tests/smoke/allowed-warnings.txt` (environment noise on `pc`, not shell bugs):

```
# IPC property change signals are reported as warnings by qs ipc.
Signal detected
# Quickshell.Networking without NetworkManager (pc has none running).
Could not find an available backend
# Quickshell.Bluetooth without BlueZ (pc has none running).
Failed to create DBusObjectManagerInterface for "org\.bluez"
# The user's running shell owns org.freedesktop.Notifications during development.
Could not register notification server
# Themed icon names absent from the icon theme (menu rows, some apps).
Could not load icon
# No xdg-desktop-portal host registration for this instance.
Failed to register with host portal
```

  (When the notification server warning turns out to be two lines in Task 8, add the second line's exact text there, with a comment.)

  `tests/fixtures/config.json`:

```json
{
  "wallpaper": "~/.config/dotfiles/wp2.jpg",
  "lock": { "timeout": 0 }
}
```

- [ ] **Step 5: Write the screenshot and niri helpers** — `tests/shot.sh` (chmod +x):

```bash
#!/usr/bin/env bash
# Usage: tests/shot.sh <name> — crop around the island on the focused monitor.
# niri also copies the screenshot to the clipboard. Refuses while the user's
# session is locked (the old shell's lock target answers "true").
set -euo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
if [ "$(qs ipc call lock isLocked 2>/dev/null || true)" == "true" ]; then echo "shot: session locked — ask the user to unlock"; exit 1; fi
mkdir -p /tmp/wyspa-shots
RAW="/tmp/wyspa-shots/$1-full.png"
W="$(qs ipc -p "$DIR" prop get island targetW 2>/dev/null || echo 800)"
H="$(qs ipc -p "$DIR" prop get island targetH 2>/dev/null || echo 500)"
[[ "$W" =~ ^[0-9]+$ ]] || W=800
[[ "$H" =~ ^[0-9]+$ ]] || H=500
SCALE="$(niri msg -j focused-output | python3 -I -c 'import json,sys; print(json.load(sys.stdin)["logical"]["scale"])')"
niri msg action screenshot-screen --show-pointer false --path "$RAW" >/dev/null
sleep 0.5
python3 -I - "$RAW" "/tmp/wyspa-shots/$1.png" "$W" "$H" "$SCALE" <<'PY'
import sys
from PIL import Image
raw, out, w, h, scale = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), float(sys.argv[5])
im = Image.open(raw); iw, ih = im.size
cw = min(iw, int((w + 200) * scale)); ch = min(ih, int((h + 120) * scale))
im.crop(((iw - cw) // 2, 0, (iw + cw) // 2, ch)).save(out)
PY
echo "/tmp/wyspa-shots/$1.png"
```

  `tests/niri-validate.sh` (chmod +x):

```bash
#!/usr/bin/env bash
# Validates the repo's niri config with this host's output.kdl in place.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cp "$REPO"/config/niri/*.kdl "$TMP"/
cp "$REPO/hosts/pc/niri-output.kdl" "$TMP/output.kdl"
niri validate -c "$TMP/config.kdl"
```

- [ ] **Step 6: Delete the old UI and write the empty shell** — remove the files listed above; `shell.qml`:

```qml
import QtQuick
import Quickshell

ShellRoot {
    settings.watchFiles: true
}
```

`tests/smoke/00-start.sh` (a check file is plain bash sourced by the runner):

```bash
# The config starts and logs nothing bad (the runner checks the log).
true
```

- [ ] **Step 7: Verify the runner really catches warnings and cleans up** — temporarily add `Component.onCompleted: console.warn("probe")` to `ShellRoot`, run `tests/smoke.sh tests/smoke/00-start.sh`.
  Expected: exit 1 and the `probe` line printed under "FAIL: instance logged:". If the probe is not caught, look at the real `qs log -p .` output and fix the level pattern in `smoke.sh` until it is. Remove the probe. Then make a check file with an unbound variable (`echo $NOPE`), run it, and confirm `qs list` shows no instance for this path afterwards (the EXIT trap). Run `tests/niri-validate.sh` → exit 0.

- [ ] **Step 8: Run everything green**
  Run: `node --test 'tests/*.test.mjs' && tests/smoke.sh tests/smoke/00-start.sh`
  Expected: both PASS (exit 0).

- [ ] **Step 9: Commit** — `git add -A . && git commit -m "quickshell: clean slate for Wyspa + node/smoke test harness"`

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

## Group 2 — Island (gate after Task 6)

### Task 3: Island geometry + priority logic

**Files:** Create `lib/island.js`, `tests/island.test.mjs`

Reference: DESIGN §4, §7 R17, R27.

**Interfaces:**
- Produces: `var PRIORITY` (`{rest:0, media:1, osd:2, toast:3, control:4, power:4, center:4, powerDone:4, launcher:5}`); `function accepts(current: string, next: string) → bool`; `function isModal(state: string) → bool`; `function radiusFor(h: number, cap: number) → number`; `function geometry(state: string, geom: object, ctx: {badge?: bool, centerHeight?: number}) → {w, h, r, ears: bool}`.

- [ ] **Step 1: Write the failing test** — `tests/island.test.mjs`:

```js
import { test } from "node:test";
import assert from "node:assert/strict";
import { load, plain } from "./qmljs.mjs";

const I = load("lib/island.js");
const G = {
    line: { w: 56, h: 5, r: 3 }, rest: { w: 200, h: 36, r: 18 }, restBadge: { w: 252, h: 36, r: 18 },
    osd: { w: 300, h: 44, r: 22 }, media: { w: 380, h: 56, r: 28 }, toast: { w: 420, h: 76, r: 30 },
    control: { w: 520, h: 440, r: 30 }, launcher: { w: 680, h: 356, r: 30 }, power: { w: 540, h: 180, r: 30 },
    powerDone: { w: 340, h: 56, r: 28 }, center: { w: 440, hMin: 170, hMax: 620, r: 30 }, ear: 16,
};

test("geometry: table states", () => {
    assert.deepStrictEqual(plain(I.geometry("launcher", G, {})), { w: 680, h: 356, r: 30, ears: true });
    assert.deepStrictEqual(plain(I.geometry("osd", G, {})), { w: 300, h: 44, r: 22, ears: true });
    assert.deepStrictEqual(plain(I.geometry("powerDone", G, {})), { w: 340, h: 56, r: 28, ears: true });
});

test("geometry: rest widens with the badge", () => {
    assert.deepStrictEqual(plain(I.geometry("rest", G, { badge: false })), { w: 200, h: 36, r: 18, ears: true });
    assert.deepStrictEqual(plain(I.geometry("rest", G, { badge: true })), { w: 252, h: 36, r: 18, ears: true });
});

test("geometry: line has no ears", () => {
    assert.deepStrictEqual(plain(I.geometry("line", G, {})), { w: 56, h: 5, r: 3, ears: false });
});

test("geometry: center height clamps and radius follows min(h/2, r)", () => {
    assert.deepStrictEqual(plain(I.geometry("center", G, { centerHeight: 900 })), { w: 440, h: 620, r: 30, ears: true });
    assert.deepStrictEqual(plain(I.geometry("center", G, { centerHeight: 100 })), { w: 440, h: 170, r: 30, ears: true });
    assert.deepStrictEqual(plain(I.geometry("center", G, { centerHeight: 333 })), { w: 440, h: 333, r: 30, ears: true });
});

test("geometry: unknown state falls back to rest", () => {
    assert.deepStrictEqual(plain(I.geometry("bogus", G, {})), { w: 200, h: 36, r: 18, ears: true });
});

test("radiusFor", () => {
    assert.equal(I.radiusFor(36, 30), 18);
    assert.equal(I.radiusFor(440, 30), 30);
});

test("accepts(): priority", () => {
    assert.equal(I.accepts("rest", "toast"), true);
    assert.equal(I.accepts("launcher", "toast"), false);
    assert.equal(I.accepts("toast", "osd"), false);
    assert.equal(I.accepts("osd", "toast"), true);
    assert.equal(I.accepts("media", "osd"), true);
    assert.equal(I.accepts("control", "launcher"), true);
    assert.equal(I.accepts("launcher", "control"), false);
    assert.equal(I.accepts("control", "power"), true);
    assert.equal(I.accepts("toast", "rest"), true);
    assert.equal(I.accepts("rest", "bogus"), false);
});

test("isModal()", () => {
    for (const s of ["launcher", "control", "power", "center"]) assert.equal(I.isModal(s), true, s);
    for (const s of ["rest", "osd", "media", "toast", "powerDone", "line"]) assert.equal(I.isModal(s), false, s);
});
```

- [ ] **Step 2: Run** — create `lib/island.js` with `.pragma library` only, run `node --test tests/island.test.mjs` → Expected: FAIL with `I.geometry is not a function`-type TypeErrors on every test (stub exists; behaviour missing).
- [ ] **Step 3: Implement** — `geometry`: `rest` picks `restBadge` when `ctx.badge`; `center` clamps `ctx.centerHeight` into `[hMin, hMax]` and uses `radiusFor(h, center.r)`; other known states copy the table; `ears = state !== "line"`. `accepts`: `next === "rest"` → true; unknown `next` → false; else `PRIORITY[next] >= PRIORITY[current]`.
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** — `quickshell: island geometry and priority logic`

### Task 4: IslandState singleton + IPC

**Files:** Create `IslandState.qml`, `tests/smoke/04-state.sh`; Modify `shell.qml` (instantiate nothing — singletons load on first use; reference `IslandState` once from `shell.qml`, e.g. `Component.onCompleted: IslandState.current`, so the IPC handler registers at startup).

**Interfaces:**
- Consumes: `lib/island.js` (`accepts`, `isModal`, `geometry`), `Theme.geom`, `Theme.motion`, `Niri.focusedOutput` (`services/Niri.qml`).
- Produces (singleton `IslandState`): `current: string`, `output: string` (screen name the non-rest state shows on), `hidden: bool`, `modal: bool`, `centerHeight: int` (writable, Center sets it), `badge: bool` (writable for now; Task 8 binds it), `osdKind: string` ("volume"|"brightness"), `function request(s: string): bool`, `function close(): void`, `function toggle(s: string): void`, `function toggleHidden(): void`, `function geometryFor(s: string): var`. Per-state timers: `osd` → `Theme.motion.osdTimeoutMs`, `toast` → `toastTimeoutMs`, `powerDone` → `powerDoneMs`; a repeated `request` of the same timed state restarts its timer; on expiry `close()` only if still in that state. `IpcHandler { target: "island" }`: `open(s: string): void`, `toggle(s: string): void`, `close(): void`, `hide(): void`; readable `current: string`, `output: string`, `hidden: bool`, `targetW: int`, `targetH: int` (geometry of `current` with live ctx).

- [ ] **Step 1: Write the check** — `tests/smoke/04-state.sh`:

```bash
expect island current rest
expect island targetW 200
call island open launcher
expect island current launcher
expect island targetW 680
expect island targetH 356
call island open toast
expect island current launcher
call island close
expect island current rest
call island open osd
expect island current osd
wait_ms 1000
call island open osd
wait_ms 1000
expect island current osd
wait_ms 800
expect island current rest
call island toggle control
expect island current control
call island toggle control
expect island current rest
call island open bogus
expect island current rest
call island hide
expect island hidden true
call island hide
expect island hidden false
```

- [ ] **Step 2: Run** — `tests/smoke.sh tests/smoke/04-state.sh` → Expected: FAIL (`island` target unknown).
- [ ] **Step 3: Implement** `IslandState.qml` (`pragma Singleton`, `import "lib/island.js" as L`, `import "services"`). `output` is set to `Niri.focusedOutput` on every accepted non-rest request.
- [ ] **Step 4: Run** `node --test 'tests/*.test.mjs' && tests/smoke.sh tests/smoke/04-state.sh` → PASS.
- [ ] **Step 5: Commit** — `quickshell: IslandState machine with island IPC`

### Task 5a: Island surface, morphing shape, strut, mask, focus

**Files:**
- Create: `Island.qml`, `IslandShape.qml`, `Strut.qml`, `tests/smoke/05a-surface.sh`
- Modify: `shell.qml` (per screen: `Wallpaper`, `Strut`, `Island`), `IslandState.qml` (readable `maskMode: string` = "shape"|"full" for the island on `output`, reported by Island like `contentState` in Task 6 — add `reportMask(output: string, m: string)`), `lib/theme.js` (new tokens), `config/niri/layout.kdl` (`../niri/layout.kdl` from here: delete the whole `struts { … }` block — it compensated the old Border)

Reference: §2.1–§2.3, §2.6–§2.7, §2.9, §7 R13, R20, R25; DESIGN W3.

**Interfaces:**
- Consumes: `IslandState.current/output/hidden/modal/geometryFor/close`, `Theme.*`.
- Produces: `IslandShape.qml` properties `w: real`, `h: real`, `r: real`, `ears: bool`, `fillColor: color`, `lineMode: bool`, readonly `body: Item` (an Item whose own `x/y/width/height` follow the animated shape — Regions track only an item's own geometry), readonly `animW/animH/animR/animEar: real`, default property alias `content` (a `clip: true` item of size `animW × animH`). `Island.qml`: `required property var modelData` (ShellScreen), readonly `effState: string` (`IslandState.current` if `IslandState.output === screen.name` or current is `rest`, else `rest`; the `line` override comes in Task 20), keyboard focus `WlrKeyboardFocus.Exclusive` iff `IslandState.modal && IslandState.output === screen.name && Quickshell.env("WYSPA_TEST") !== "1"`, else `None`. `Strut.qml`: `required property var modelData`, `exclusiveZone: Theme.geom.exclusive` (Task 20 makes it 0 in line mode).

- [ ] **Step 1: Write the check** — `tests/smoke/05a-surface.sh`:

```bash
expect island maskMode shape
shot surface-rest
call island open launcher
wait_ms 700
expect island maskMode full
shot surface-launcher
call island close
wait_ms 700
expect island maskMode shape
call island open toast
wait_ms 700
expect island maskMode shape
call island close
```

- [ ] **Step 2: Run** `tests/smoke.sh tests/smoke/05a-surface.sh` → FAIL (`maskMode` not found; shots show no island).
- [ ] **Step 3: Implement**
  - `Island.qml`: `PanelWindow`, `screen: modelData`, anchors all four edges, `color: "transparent"`, `exclusionMode: ExclusionMode.Ignore`, `WlrLayershell.layer: WlrLayer.Overlay`, `WlrLayershell.namespace: "wyspa"`. Shape centred horizontally at `y = 0`. `mask: Region { item: modal-on-this-screen ? fullItem : shape.body }`. A full-size `MouseArea` below the shape, enabled only when modal on this screen, calls `IslandState.close()` (R20). `Keys.onEscapePressed: IslandState.close()` on a focus scope focused while keyboard focus is Exclusive.
  - `IslandShape.qml`: `w/h/r` each with `Behavior { NumberAnimation { duration: Theme.reducedMotion ? 0 : Theme.motion.morphMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.morphCurve } }`. Fill = ONE `Shape` (`preferredRendererType: Shape.CurveRenderer`) with one `ShapePath` following §2.3 (concave ear arcs, convex bottom corners) — no seams. The ear radius is its own animated value `animEar` = `ears ? min(Theme.geom.ear, animH - animR) : 0` (clamped, so the path stays valid during line↔rest morphs — §2.3 warns `h − r ≥ e`), animated over `Theme.motion.earFadeMs`. Fill colour `lineMode ? Theme.line : Theme.islandBg`, `ColorAnimation` `Theme.motion.bgColorMs`.
  - `Strut.qml`: `PanelWindow` anchored top/left/right, `implicitHeight: Theme.geom.exclusive`, `exclusionMode: ExclusionMode.Normal`, `exclusiveZone: Theme.geom.exclusive`, transparent, `mask: Region {}`, `WlrLayershell.layer: WlrLayer.Bottom`, namespace `wyspa-strut`.
- [ ] **Step 4: Run** `tests/smoke.sh tests/smoke/05a-surface.sh`, `node --test 'tests/*.test.mjs'`, `tests/niri-validate.sh`; Read the PNGs → rest 200×36 with ears at top centre, launcher 680×356; all PASS.
- [ ] **Step 5: Commit** — `git add -A . ../niri` — `quickshell: island surface, morphing shape, strut`

### Task 5b: Island material — blur region, shadow, ring, gloss + niri rule

**Files:**
- Create: `tests/smoke/05b-material.sh`
- Modify: `Island.qml`, `IslandShape.qml`, `lib/theme.js` (`sizes.sheenGlow 30`, shadow padding token), `config/niri/window_rules.kdl`, `config/niri/config.kdl`

Reference: §2.4, §2.5, §2a, §7 R2, R11, R13, R16, R23; DESIGN W1, W2.

**Interfaces:**
- Consumes: `IslandShape.body/animW/animH/animR/animEar/lineMode`, `Theme` material keys.
- Produces: nothing new for later tasks (visual only).

- [ ] **Step 1: Write the check** — `tests/smoke/05b-material.sh`:

```bash
call island open control
wait_ms 700
shot material-glass
printf '{"wallpaper":"~/.config/dotfiles/wp2.jpg","lock":{"timeout":0},"island":{"glass":false}}' > "$CFG"
wait_ms 900
shot material-solid
call island close
```

- [ ] **Step 2: Run**; Read both PNGs → RED: flat fill, no gloss/ring/shadow; identical shots.
- [ ] **Step 3: Implement**
  - Blur (W1): `BackgroundEffect.blurRegion` (from `Quickshell.Wayland`) set **only** when `Theme.glass && !lineMode`, else `null`. Region = `Region { Region { item: body; bottomLeftRadius: animR; bottomRightRadius: animR } <left ear> <right ear> }`, ear = `Region { x: body.x - e; y: 0; width: e; height: e }` followed by `Region { shape: RegionShape.Ellipse; intersection: Intersection.Subtract; x: body.x - 2*e; y: 0; width: 2*e; height: 2*e }` (mirror for the right), `e = animEar`; no ear regions when `animEar` is 0.
  - Shadow (W2): drawn only *outside* the shape — `MultiEffect` with `shadowEnabled`, `shadowColor: Theme.shadowColor`, `shadowVerticalOffset: Theme.shadowY`, `blurMax: Theme.shadowBlur`, `shadowBlur: 1`, applied to an opaque copy of the path and masked with `maskEnabled + maskInverted` by the same path, so the translucent interior is not darkened. The effect's source item is sized to the shape bounds plus `Theme.shadowBlur + Theme.shadowY` padding — never the full-screen window (a 3840×2160 FBO per morph frame on DP-2).
  - Ring (R13): a `Rectangle` the size of `body`, `color: "transparent"`, `border.color: Theme.ring`, `border.width: Theme.sizes.ringWidth`, bottom radii `animR`.
  - Gloss (§2a, R23): above content, clipped to body, `opacity: Theme.sheen`: vertical `Gradient` stops `0 → Theme.sheenTop`, `0.45 → Theme.sheenMid`, `1 → transparent`; 1 px outline `Theme.sheenOutline`; 1 px bottom-edge highlight `Theme.sheenEdge` following the bottom radius; inner glow `Theme.sheenGlow` with blur radius `Theme.sizes.sheenGlow`. Ring, gloss and shadow hidden when `lineMode` (R16).
  - niri: append to `config/niri/window_rules.kdl` (no `blur true` — the client region alone enables blur; a rule-level `blur true` would blur the whole full-screen surface whenever no region is set):

```kdl
layer-rule {
    match namespace="^wyspa$"
    background-effect {
        xray false
        saturation 2.0
    }
}
```

    and at top level of `config/niri/config.kdl` (check there is no `blur {}` yet): `blur { passes 3; offset 5; }`. Live niri sees this only after merge (or earlier if the user lands it on main — plan-gate decision).
- [ ] **Step 4: Run** `tests/smoke.sh tests/smoke/05b-material.sh`, `node --test 'tests/*.test.mjs'`, `tests/niri-validate.sh`; Read PNGs → glass shot: translucent fill, gloss gradient brighter at the top, 1 px ring, soft shadow outside only (no dark halo inside); solid shot: opaque fill, no gloss, and the area around the island NOT blurred. All PASS.
- [ ] **Step 5: Commit** — `git add -A . ../niri` — `quickshell: island glass material; niri layer rule`

### Task 6: Content host with enter/exit choreography

**Files:** Create `IslandContent.qml`, `tests/smoke/06-content.sh`; Modify `Island.qml`, `IslandShape.qml` (host goes into `content`), `IslandState.qml` (readable `contentState` for tests).

Reference: §2.2, §2.8, §4.6 row "state change", §7 R25.

**Interfaces:**
- Consumes: `Island.effState`, `Theme.motion.*`, `IslandState.geometryFor(s)`.
- Produces: `IslandContent.qml` with `property string target` (bound to `effState`; not `state`, which would shadow `Item.state`), `property string output` (screen name), `readonly property string shown` (the state whose layer is fully entered, "" during transition), and `property var sources: ({})` — map state → `Qt.resolvedUrl("states/X.qml")`; **each later state task adds exactly one entry**. Every state component gets `property bool active` (true while its layer is "on") and `property string output` set by the host; it must size itself from `Theme.geom.<state>` (target width from the start, never reflowing). `IslandState` gains IPC-readable `contentState: string` = the `shown` value of the island on `IslandState.output`, or on `Niri.focusedOutput` while `current === "rest"` (Island registers it via `IslandState.reportShown(output: string, s: string)`).

- [ ] **Step 1: Write the check** — `tests/smoke/06-content.sh`:

```bash
expect island contentState rest
call island open launcher
expect island contentState ""
wait_ms 600
expect island contentState launcher
call island close
wait_ms 600
expect island contentState rest
```

- [ ] **Step 2: Run** → FAIL (`contentState` property not found).
- [ ] **Step 3: Implement** — one layer `Item` per entry in `sources` (all `Loader`s stay active — prototypes keep every layer mounted), width/height = that state's geometry, centred, `y: 0`, `transformOrigin: Item.Center`. On/off values per §2.8: opacity 0→1 (`enterOpacityMs`, `enterCurve`, delay `enterOpacityDelayMs`) / →0 (`exitOpacityMs`, `easeCurve`); scale `contentScaleFrom`→1 (`enterScaleMs`, delay `enterScaleDelayMs`) / →`contentScaleFrom` (`exitScaleMs`); blur `contentBlur`→0 via `MultiEffect` (`layer.enabled` only while blur > 0). Use `Behavior { SequentialAnimation { PauseAnimation { duration: on ? delay : 0 } NumberAnimation { … } } }`. Off layers: `enabled: false`. Reduced motion: opacity only, `reducedFadeMs`, no scale/blur, no delay. `shown` = the state whose layer has finished its enter animation; for states with no entry in `sources` the host still reports `shown` after `enterOpacityDelayMs + enterOpacityMs`.
- [ ] **Step 4: Run** all tests → PASS.
- [ ] **Step 5: Commit** — `quickshell: island content host with enter/exit choreography`

**— USER GATE 2 —** test: morph between states via `qs ipc -p … call island open launcher|control|toast|osd|media|power|center`, `close`; interrupt a morph mid-way; Esc/click-outside closes launcher/control (gate instance runs without `WYSPA_TEST`, so it has keyboard focus); exclusive zone (windows shift down) on every monitor; glass/gloss/ring look; `"island": {"glass": false}` in the gate's `WYSPA_CONFIG` copy → solid, nothing blurred around. Unless the niri rule was landed on main at the plan gate, blur over windows (xray off) and the 44 px window offset appear only after merge.

---

## Group 3 — Rest (gate after Task 9)

### Task 7: Line icons

**Files:** Create `lib/icons.js`, `components/Icon.qml`, `tests/icons.test.mjs`

Reference: §5 (prototype path data where given, Lucide otherwise; `<circle>`/`<rect>` converted to path `d` strings), §7 R31, R33.

**Interfaces:**
- Produces: `var paths` (name → SVG path `d` string on the 24 grid). `components/Icon.qml`: `property string name`, `property color color: Theme.fg`, `property real size`; a `Shape` scaled by `size / 24` with one `ShapePath { strokeColor: root.color; strokeWidth: Theme.sizes.iconStroke; fillColor: "transparent"; capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin; PathSvg { path: I.paths[root.name] ?? "" } }` (stroke width must not scale — compensate by `Theme.sizes.iconStroke * 24 / size` if the scale transform affects it, verify on screen). Colour animates for free with `Theme.fg`.

- [ ] **Step 1: Write the failing test** — `tests/icons.test.mjs`:

```js
import { test } from "node:test";
import assert from "node:assert/strict";
import { load } from "./qmljs.mjs";

const I = load("lib/icons.js");
const NAMES = ["bell", "moon", "volume-x", "volume-1", "volume-2", "sun", "sun-moon", "wifi", "bluetooth",
    "play", "pause", "skip-back", "skip-forward", "power", "lock", "log-out", "rotate-ccw", "search",
    "calculator", "terminal", "app-window", "x", "check", "arrow-right", "battery", "battery-charging",
    "chevron-down", "chevron-up"];

test("every icon the shell uses is a path d string", () => {
    for (const n of NAMES) {
        assert.equal(typeof I.paths[n], "string", n);
        assert.match(I.paths[n], /^[MmLlHhVvCcSsQqTtAaZz0-9 ,.\-]+$/, n);
        assert.match(I.paths[n], /^[Mm]/, n);
    }
});

test("prototype paths are kept verbatim", () => {
    assert.ok(I.paths.bell.includes("M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"));
    assert.ok(I.paths.power.includes("M12 2v10"));
    assert.ok(I.paths.check.includes("M20 6 9 17l-5-5"));
});
```

- [ ] **Step 2: Run** (stub with `.pragma library` + `var paths = {};`) → FAIL (`undefined !== 'string'` for `bell`).
- [ ] **Step 3: Implement** `lib/icons.js` and `components/Icon.qml`.
- [ ] **Step 4: Run** → PASS. Verify rendering for real: temporarily put `Icon { name: "bell"; size: 48; color: Theme.accent }` into the rest area, run `tests/smoke.sh tests/smoke/05a-surface.sh`, Read `surface-rest.png` — a crisp accent bell with ~1.6 px strokes at 24 px scale. Remove the probe.
- [ ] **Step 5: Commit** — `quickshell: line icons drawn with Shape paths`

### Task 8: Notification service for the island

**Files:** Create `lib/notifs.js`, `tests/notifs.test.mjs`; Modify `services/Notifs.qml`, `IslandState.qml` (bind `badge: Notifs.unread > 0`)

Reference: §4.3, §3.5 (height formula), §7 R26, R28, R30.

**Interfaces:**
- Produces (`lib/notifs.js`): `function group(items: array) → [{app: string, items: array}]` (items newest-first; groups ordered by their newest item); `function centerHeight(groups, expanded: object, L: object) → number` (formula of §3.5/§4.3 with bottom term 16, `L` = the `layout.center` tokens); `function appColor(appName: string, colors: array) → string` (stable hash → one of `colors`); `function initial(appName: string) → string` (first letter, uppercase, "?" if empty).
- Produces (`services/Notifs.qml`): `history: var` (snapshots `{id, appName, summary, body, appIcon, image, time}` newest first, max 50), `groups: var` (= `group(history)`), `unread: int`, `dnd: bool`, `latest: var` (newest snapshot or null), `series: int` (notifications since the toast opened), `signal arrived(var snap)`, `function markRead(): void`, `function dismiss(id: int): void`, `function dismissApp(app: string): void`, `function clearAll(): void`, `function resetSeries(): void`, `function push(snap: var): void` (the single arrival path, used by the server and by IPC). `IpcHandler { target: "notifs" }`: `inject(app: string, summary: string, body: string): void` (builds a snapshot and calls `push` — tests use it because the user's running shell owns the D-Bus notification name), `dnd(on: bool): void`, `clear(): void`, readable `count: int`, `unread: int`, `dndOn: bool`. Popups are no longer tracked (`n.tracked` stays false after the snapshot is taken); `unread` increments on each arrival (also in DND); `series` increments unless DND.

- [ ] **Step 1: Write the failing test** — `tests/notifs.test.mjs`:

```js
import { test } from "node:test";
import assert from "node:assert/strict";
import { load, plain } from "./qmljs.mjs";

const N = load("lib/notifs.js");
const it = (id, appName) => ({ id, appName, summary: "s" + id });

test("group(): groups by app, newest group first, items newest first", () => {
    const g = plain(N.group([it(5, "a"), it(4, "b"), it(3, "a"), it(2, "c"), it(1, "b")]));
    assert.deepStrictEqual(g.map(x => x.app), ["a", "b", "c"]);
    assert.deepStrictEqual(g[0].items.map(x => x.id), [5, 3]);
    assert.deepStrictEqual(g[1].items.map(x => x.id), [4, 1]);
});

test("group(): empty", () => {
    assert.deepStrictEqual(plain(N.group([])), []);
});

test("appColor(): stable and within the palette", () => {
    const cols = ["#1", "#2", "#3", "#4"];
    assert.equal(N.appColor("firefox", cols), N.appColor("firefox", cols));
    assert.ok(cols.includes(N.appColor("firefox", cols)));
    assert.ok(cols.includes(N.appColor("", cols)));
});

test("initial()", () => {
    assert.equal(N.initial("firefox"), "F");
    assert.equal(N.initial(""), "?");
});
```

  Add to this file one `centerHeight` test whose expected numbers you compute by hand from the §3.5 formula for: (a) no groups → `hMin` (170); (b) one collapsed group of 3; (c) the same group expanded. Write the three expected values as literals with the arithmetic in a comment.

- [ ] **Step 2: Run** (stub file) → FAIL on assertions.
- [ ] **Step 3: Implement** `lib/notifs.js`, add `layout.center` tokens (§3.5) to `lib/theme.js`, update `services/Notifs.qml` per Interfaces.
- [ ] **Step 4: Run** `node --test 'tests/*.test.mjs' && tests/smoke.sh tests/smoke/04-state.sh` → PASS. Then `tests/smoke/08-notifs.sh` (`expect island targetW 200`, `call notifs dnd true`, `call notifs inject test hello x`, `wait_ms 300`, `expect notifs unread 1`, `expect island targetW 252`, `call notifs dnd false`) through `tests/smoke.sh` → PASS (write it before the QML change and see it FAIL first; DND keeps the toast from Task 11 out of this check). If the "notification server already registered" warning is two lines, add the second exact line to `allowed-warnings.txt` with a comment.
- [ ] **Step 5: Commit** — `quickshell: notification history, groups, unread badge`

### Task 9: Rest state

**Files:** Create `states/Rest.qml`, `tests/smoke/09-rest.sh`; Modify `IslandContent.qml` (`sources.rest`), `lib/theme.js` (`layout.rest`)

Reference: §3.1, DESIGN §6 "Spoczynek", §7 R19, R27.

**Interfaces:**
- Consumes: `Niri.workspaces`, `Niri.activeByOutput`, `Time` (`services/Time.qml`), `Players.active`, `Notifs.unread`, `Notifs.dnd`, `IslandState.request`, `components/Icon.qml`.
- Produces: `states/Rest.qml` (`property bool active`, `property string output`).

- [ ] **Step 1: Write the check** — `tests/smoke/09-rest.sh`:

```bash
wait_ms 600
shot rest
expect island contentState rest
```

- [ ] **Step 2: Run**; Read `rest.png` → Expected RED: empty pill (no dots, no clock).
- [ ] **Step 3: Implement** per §3.1: workspace dots for this output (active = pill 14×5 accent, others 5×5 `Theme.dotInactive`, animated width/colour), mono clock 13 px, 3-bar equaliser animating (`Theme.motion.eqMs`) only while `Players.active?.isPlaying`, badge (pill `Theme.accentSoft` + `bell` or `moon` when DND + count) only when `Notifs.unread > 0`. Click badge → `IslandState.request("center")`; click elsewhere → `request("control")`.
- [ ] **Step 4: Run** `node --test 'tests/*.test.mjs' && tests/smoke.sh tests/smoke/09-rest.sh`; Read `rest.png` → dots + clock visible, matching §3.1 spacing.
- [ ] **Step 5: Commit** — `quickshell: rest state (workspaces, clock, music, badge)`

**— USER GATE 3 —** test: dots follow workspace switches per monitor; clock; music bars with a playing player; `notify-send` → badge (252 px), DND moon (`call notifs dnd true`); click → control (empty), badge click → center (empty).

---

## Group 4 — OSD (gate after Task 10)

### Task 10: Brightness service + OSD state

**Files:** Create `services/Brightness.qml`, `states/Osd.qml`, `tests/smoke/10-osd.sh`; Modify `IslandContent.qml` (`sources.osd`), `IslandState.qml` (triggers), `lib/theme.js` (`layout.osd`)

Reference: §3.2, §4.1 (volume), §7 R31; DESIGN W10.

**Interfaces:**
- Produces (`services/Brightness.qml`): `available: bool` (a directory exists under `/sys/class/backlight/`), `value: real` (0..1, read from `brightness`/`max_brightness` via `FileView` with `watchChanges`), `function set(v: real): void` (`Quickshell.execDetached(["brightnessctl", "set", Math.round(v*100) + "%"])`). On `pc` `available` is false.
- Produces (`IslandState`): `osdKind: string`, `osdValue: real`, `osdMuted: bool`; changes of `Audio.volume`/`Audio.muted` and `Brightness.value` call `request("osd")` with the right kind — but only after a `ready` gate (ignore the values settling during the first `Theme.motion.osdTimeoutMs` after startup, like the old `modules/Osd.qml` did).
- `states/Osd.qml`: icon (`volume-x|volume-1|volume-2` by level/mute, `sun` for brightness), track `Theme.track` with accent fill animating width `Theme.motion.osdBarMs` (`enterCurve`), mono value.

- [ ] **Step 1: Write the check** — `tests/smoke/10-osd.sh`:

```bash
wait_ms 1800
wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+
wait_ms 200
expect island current osd
wait_ms 500
shot osd
wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-
wait_ms 1700
expect island current rest
```

- [ ] **Step 2: Run** → FAIL (`current` stays `rest`).
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** all → PASS; Read `osd.png` (300×44 with icon, bar, value).
- [ ] **Step 5: Commit** — `quickshell: OSD for volume and brightness`

**— USER GATE 4 —** test: volume keys → OSD on the focused monitor, timer restarts while holding the key, mute icon; on `laptop` brightness keys (needs `brightnessctl` installed there).

---

## Group 5 — Toast / Center (gate after Task 12)

### Task 11: Toast state

**Files:** Create `states/Toast.qml`, `tests/smoke/11-toast.sh`; Modify `IslandContent.qml` (`sources.toast`), `IslandState.qml` (on `Notifs.arrived` → `request("toast")` unless DND or current is `center`; toast close → `Notifs.resetSeries()`), `lib/theme.js` (`layout.toast`)

Reference: §3.4, §4.3, §7 R26, R30.

**Interfaces:**
- Consumes: `Notifs.latest`, `Notifs.series`, `Notifs.dnd`, `lib/notifs.js` (`appColor`, `initial`).
- Produces: `states/Toast.qml`; click anywhere on it → `IslandState.request("center")`.

- [ ] **Step 1: Write the check** — `tests/smoke/11-toast.sh`:

```bash
call notifs inject Wyspa pierwsze x
wait_ms 300
expect island current toast
call notifs inject Wyspa drugie x
wait_ms 600
shot toast-series
wait_ms 3300
expect island current rest
```

- [ ] **Step 2: Run** → FAIL (`current` is `rest`).
- [ ] **Step 3: Implement** per §3.4 + R26: app icon (image/appIcon via `Quickshell.iconPath`, else initial on `appColor`), "app · body" line, summary, `+N` chip when `series > 1` (N = series − 1), 2 px progress bar (`Theme.motion.toastBarMs` linear, starts after `toastBarDelayMs`, restarts on each new arrival).
- [ ] **Step 4: Run** all → PASS; Read `toast-series.png` (shows `+1`).
- [ ] **Step 5: Commit** — `quickshell: notification toast`

### Task 12: Notification center

**Files:** Create `states/Center.qml`, `tests/smoke/12-center.sh`; Modify `IslandContent.qml` (`sources.center`), `IslandState.qml` (opening center → `Notifs.markRead()`; `centerHeight` bound from Center), `lib/theme.js` (`layout.center` completes)

Reference: §3.5, §4.3, §7 R4, R6, R28, R30. (The `notifs` IPC target exists since Task 8.)

**Interfaces:**
- Consumes: `Notifs.groups/dismiss/dismissApp/clearAll/dnd/markRead`, `lib/notifs.js` `centerHeight`.
- Produces: `states/Center.qml` exposing `readonly property int wantedHeight` (= `centerHeight(...)`), which `IslandState.centerHeight` follows while center is the current state.

- [ ] **Step 1: Write the check** — `tests/smoke/12-center.sh`:

```bash
call notifs inject appA A1 x
call notifs inject appA A2 x
call notifs inject appB B1 x
wait_ms 400
expect notifs count 3
call island open center
wait_ms 700
expect notifs unread 0
shot center
call notifs dnd true
expect notifs dndOn true
call notifs clear
expect notifs count 0
call island close
call notifs dnd false
```

- [ ] **Step 2: Run** → FAIL (`notifs.unread` stays 3 — center does not mark read yet).
- [ ] **Step 3: Implement** per §3.5: header (count, DND switch, "Wyczyść"), groups newest first, collapsed group = top card + `stack1`/`stack2` layers (offsets and paddings from §3.5, `stackPadMs`), "Pokaż N"/"Zwiń", per-card dismiss `x`, per-group clear, scroll above `hMax`. Island height follows `wantedHeight` through the normal morph.
- [ ] **Step 4: Run** all → PASS; Read `center.png` (appA collapsed with one stack layer, appB single card).
- [ ] **Step 5: Commit** — `quickshell: notification center with grouping and DND`

**— USER GATE 5 —** (the user's old shell must be stopped so the worktree instance owns notifications) test: series of `notify-send` → toast + `+N`, click toast → center; expand/collapse; dismiss one/group/all; DND → no toasts, badge with moon; long list scrolls at 620 px.

---

## Group 6 — Launcher (gate after Task 15)

### Task 13: Calculator + fuzzy match with highlight ranges

**Files:** Create `lib/calc.js`, `lib/fuzzy.js`, `tests/calc.test.mjs`, `tests/fuzzy.test.mjs`; Modify `services/Apps.qml` (use `lib/fuzzy.js` for scoring; `query(search: string)` now returns `[{entry: DesktopEntry, ranges: [[start, end)]}]` — `DesktopEntry` objects cannot carry extra JS props)

**Interfaces:**
- Produces: `function evaluate(expr: string) → number|null` (`+ - * / ^ %`, parentheses, unary minus, decimals with `.` or `,`, `sqrt sin cos tan ln log abs round floor ceil`, `pi e`; anything else → null; never uses `eval`/`Function`); `function format(n: number) → string` (max 10 significant digits, no trailing zeros, `,` decimal separator); `function match(query: string, text: string) → {score: number, ranges: [[start, end)]} | null` (case-insensitive; prefix > word-start > subsequence; ranges are merged contiguous runs).

- [ ] **Step 1: Write the failing tests** — `tests/calc.test.mjs`:

```js
import { test } from "node:test";
import assert from "node:assert/strict";
import { load } from "./qmljs.mjs";

const C = load("lib/calc.js");

test("arithmetic and precedence", () => {
    assert.equal(C.evaluate("2+3*4"), 14);
    assert.equal(C.evaluate("(2+3)*4"), 20);
    assert.equal(C.evaluate("2^3^2"), 512);
    assert.equal(C.evaluate("-3+5"), 2);
    assert.equal(C.evaluate("7 % 4"), 3);
    assert.equal(C.evaluate("1,5*2"), 3);
});

test("functions and constants", () => {
    assert.equal(C.evaluate("sqrt(16)"), 4);
    assert.ok(Math.abs(C.evaluate("sin(pi/2)") - 1) < 1e-12);
    assert.ok(Math.abs(C.evaluate("ln(e)") - 1) < 1e-12);
    assert.equal(C.evaluate("log(1000)"), 3);
});

test("invalid input is null, never throws", () => {
    for (const s of ["", "2+", "foo(2)", "alert(1)", "2**", "(1", "1)", "constructor"]) assert.equal(C.evaluate(s), null, s);
});

test("format()", () => {
    assert.equal(C.format(3), "3");
    assert.equal(C.format(0.1 + 0.2), "0,3");
    assert.equal(C.format(1 / 3), "0,3333333333");
});
```

  `tests/fuzzy.test.mjs`:

```js
import { test } from "node:test";
import assert from "node:assert/strict";
import { load, plain } from "./qmljs.mjs";

const F = load("lib/fuzzy.js");

test("prefix beats word start beats subsequence", () => {
    const p = F.match("fi", "Firefox").score, w = F.match("fo", "Files Folder").score, s = F.match("fx", "Firefox").score;
    assert.ok(p > s && w > s);
    assert.ok(F.match("fi", "Firefox").score > F.match("fi", "Wifi Files").score);
});

test("ranges mark matched characters, merged", () => {
    assert.deepStrictEqual(plain(F.match("fire", "Firefox").ranges), [[0, 4]]);
    assert.deepStrictEqual(plain(F.match("ffx", "Firefox").ranges), [[0, 1], [4, 5], [6, 7]]);
});

test("no match is null; empty query matches everything with no ranges", () => {
    assert.equal(F.match("zz", "Firefox"), null);
    assert.deepStrictEqual(plain(F.match("", "Firefox")), { score: 0, ranges: [] });
});
```

- [ ] **Step 2: Run** (stubs) → FAIL on assertions.
- [ ] **Step 3: Implement** (calc: tokenizer + shunting-yard/recursive descent; `^` right-associative).
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** — `quickshell: calculator and fuzzy matcher`

### Task 14: niri windows in the Niri service

**Files:** Create `lib/niri.js`, `tests/niri.test.mjs`; Modify `services/Niri.qml`

**Interfaces:**
- Produces (`lib/niri.js`): `function reduceWindows(windows: object, ev: object) → object` (map id → window; handles `WindowsChanged {windows}`, `WindowOpenedOrChanged {window}`, `WindowClosed {id}`, `WindowFocusChanged {id}` — sets `is_focused`; other events return the same object). (`services/Niri.qml`): `windows: var` (map), `windowList: var` (array sorted by `focus_timestamp` desc), `function focusWindow(id: int): void` (`niri msg action focus-window --id <id>`).

- [ ] **Step 1: Write the failing test** — `tests/niri.test.mjs`:

```js
import { test } from "node:test";
import assert from "node:assert/strict";
import { load, plain } from "./qmljs.mjs";

const N = load("lib/niri.js");
const w = (id, extra = {}) => ({ id, title: "t" + id, app_id: "a", workspace_id: 1, is_focused: false, ...extra });

test("WindowsChanged replaces the map", () => {
    const s = plain(N.reduceWindows({ 9: w(9) }, { WindowsChanged: { windows: [w(1), w(2)] } }));
    assert.deepStrictEqual(Object.keys(s), ["1", "2"]);
});

test("open/change, close, focus", () => {
    let s = N.reduceWindows({}, { WindowOpenedOrChanged: { window: w(1) } });
    s = N.reduceWindows(s, { WindowOpenedOrChanged: { window: w(2, { title: "x" }) } });
    s = N.reduceWindows(s, { WindowFocusChanged: { id: 2 } });
    assert.equal(s[2].is_focused, true);
    assert.equal(s[1].is_focused, false);
    s = N.reduceWindows(s, { WindowClosed: { id: 1 } });
    assert.deepStrictEqual(Object.keys(plain(s)), ["2"]);
});

test("unrelated events return the same object", () => {
    const s = { 1: w(1) };
    assert.equal(N.reduceWindows(s, { WorkspaceActivated: { id: 3 } }), s);
});
```

- [ ] **Step 2: Run** (stub) → FAIL.
- [ ] **Step 3: Implement**; `Niri.applyEvent` feeds every event to `reduceWindows` (pattern: existing `applyEvent` in `services/Niri.qml`).
- [ ] **Step 4: Run** `node --test 'tests/*.test.mjs' && tests/smoke.sh tests/smoke/00-start.sh` → PASS.
- [ ] **Step 5: Commit** — `quickshell: track niri windows`

### Task 15: Launcher state

**Files:** Create `states/Launcher.qml`, `tests/smoke/15-launcher.sh`; Modify `IslandContent.qml` (`sources.launcher`), `IslandState.qml` (IPC `launcherMenu(id: string): void` = open launcher straight into a menu), `lib/theme.js` (`layout.launcher`), `services/Menus.qml` (per-menu `closeOnRun: bool` — `clipboard: true`, `vpn: false`), `menus/cliphist.sh` (drop the trailing `; qs ipc call launcher close` from the emitted command — the launcher now closes itself when `closeOnRun`)

Reference: §3.6, DESIGN §6 "Launcher", §7 R29, W8. Menu script format: `menus/*.sh list` prints `<active 1|0>\t<label>\t<sublabel>\t<command>` per line (see `services/Menus.qml` header comment); the old launcher logic is in `git show ff1f02d:config/quickshell/modules/Launcher.qml` (`kindOf`, `run`, menu drill-in, Esc backs out of a menu first).

**Interfaces:**
- Consumes: `Apps.query`, `Apps.launch`, `Menus.list/get`, `Niri.windowList/focusWindow`, `lib/calc.js`, `lib/fuzzy.js`, `Icon`.
- Produces: `states/Launcher.qml`; when `active` becomes true it clears the field and takes focus; on `island`: IPC `launcherSetQuery(q: string): void` and readable `launcherQuery: string`, `launcherCount: int` (rows in the current list), `launcherMode: string` ("apps"|"calc"|"command"|"windows"|"menu"), `launcherResult: string` (label of the selected row).

- [ ] **Step 1: Write the check** — `tests/smoke/15-launcher.sh`:

```bash
call island open launcher
wait_ms 600
expect island launcherMode apps
call island launcherSetQuery "=2+3*4"
wait_ms 200
expect island launcherMode calc
expect island launcherResult 14
shot launcher-calc
call island launcherSetQuery "@"
expect island launcherMode windows
call island close
```

  (No `wtype` on `pc`: real keyboard input is checked by the user at the gate.)
- [ ] **Step 2: Run** → FAIL (`launcherMode` not found).
- [ ] **Step 3: Implement** per §3.6 + R29: search pill 48 px with caret/prefix in accent; chips `=` `>` `@` (active chip `Theme.chip`); list of 3 visible rows (40 px icon, name with `ranges` in accent, description), selected row `Theme.sel` + `↵` kbd; ↑/↓, Enter, `Ctrl+1…9`; footer with key hints and `Theme.divider`. Modes: default = menus (VPN, clipboard rows) + apps; `=` shows one result row with `format(evaluate())` (Enter copies it with `wl-copy`); `>` one row "Uruchom: …" (Enter → `sh -c` detached); `@` = `Niri.windowList` fuzzy-filtered (Enter → `focusWindow`); menu drill-in as before. Esc: menu → back, else close.
- [ ] **Step 4: Run** all → PASS; Read `launcher-calc.png` (result 14).
- [ ] **Step 5: Commit** — `quickshell: launcher (apps, calculator, command, windows, menus)`

**— USER GATE 6 —** test: `call island open launcher`, typing, highlight, Ctrl+1–9, `=`, `>`, `@`, VPN and clipboard menus, Esc behaviour; keyboard focus returns to the window after close.

---

## Group 7 — Control + Media (gate after Task 17)

### Task 16: Control panel

**Files:** Create `states/Control.qml`, `components/MiniPlayer.qml`, `tests/smoke/16-control.sh`; Modify `IslandContent.qml` (`sources.control`), `lib/theme.js` (`layout.control`, `layout.miniPlayer`)

Reference: §3.7, DESIGN §6 "Panel", §7 R24, W10; services `Network`, `Battery` (existing), `Quickshell.Bluetooth`, `Audio`, `Brightness`, `Players`, `Notifs.dnd`, `Theme.setMode`.

**Interfaces:**
- Produces: `components/MiniPlayer.qml` (`property var player`, art + title/artist + prev/play-pause/next; reused by Media and Lock); `states/Control.qml`. Toggles: DND (`Notifs.dnd`), Motyw (`Theme.setMode(Theme.mode === "dark" ? "light" : "dark")`), Zasilanie (`IslandState.request("power")`). Wi-Fi tile hidden unless `Network.available`; Bluetooth tile hidden unless `Bluetooth.defaultAdapter`; brightness slider hidden unless `Brightness.available`; when both tiles are hidden the row is removed and the panel content stays top-aligned (island height stays 440).

- [ ] **Step 1: Write the check** — `tests/smoke/16-control.sh`:

```bash
call island open control
wait_ms 700
shot control-dark
call theme setMode light
wait_ms 800
shot control-light
call theme setMode dark
call island close
```

- [ ] **Step 2: Run**; Read shots → RED: empty 520×440 island.
- [ ] **Step 3: Implement** per §3.7 (header clock 44 px mono with letter-spacing token + date, tiles, sliders card with `Theme.track`/`Theme.sliderFill`, round toggles, mini player). Sliders: drag + wheel set `Audio.setVolume` / `Brightness.set`.
- [ ] **Step 4: Run** all → PASS; Read both shots (light one matches `JasnyMotyw` panel).
- [ ] **Step 5: Commit** — `quickshell: control panel`

### Task 17: Media state

**Files:** Create `states/Media.qml`, `tests/smoke/17-media.sh`; Modify `IslandContent.qml` (`sources.media`), `states/Rest.qml` (hover while `Players.active?.isPlaying` → `request("media")`), `Island.qml` (leaving the shape while in `media` → `close()` after `Theme.motion.mediaLeaveMs`), `lib/theme.js` (`layout.media`)

Reference: §3.3, §7 R31.

- [ ] **Step 1: Write the check** — `tests/smoke/17-media.sh`:

```bash
call island open media
wait_ms 700
expect island current media
shot media
call island close
```

- [ ] **Step 2: Run**; Read `media.png` → RED: empty 380×56.
- [ ] **Step 3: Implement** per §3.3 using `MiniPlayer` layout tokens where they coincide; nothing playing → "Nic nie gra" placeholder in `Theme.fgMuted`.
- [ ] **Step 4: Run** all → PASS.
- [ ] **Step 5: Commit** — `quickshell: media state`

**— USER GATE 7 —** test: click rest → control; tiles/sliders/toggles; Motyw toggle crossfades 600 ms; mini player controls; hover rest while music plays → media, leave → rest.

---

## Group 8 — Power (gate after Task 18)

### Task 18: Power menu + powerDone

**Files:** Create `states/Power.qml`, `states/PowerDone.qml`, `tests/smoke/18-power.sh`; Modify `IslandContent.qml` (`sources.power`, `sources.powerDone`), `Island.qml` (dim layer `Theme.scrimDim`, opacity animated `Theme.motion.dimMs`, visible only in `power`), `IslandState.qml` (`powerLabel: string`), `lib/theme.js` (`layout.power`, `layout.powerDone`, `power.commands`)

Reference: §3.8, §3.9, §4.4, DESIGN §6 "Menu zasilania", §7 R18, R22.

**Interfaces:**
- Produces: `Theme.tokens.power.commands` = `{ suspend: ["systemctl", "suspend"], logout: ["niri", "msg", "action", "quit", "--skip-confirmation"], reboot: ["systemctl", "reboot"], poweroff: ["systemctl", "poweroff"] }` (overridable); Lock action calls `Lock.lock()` (Task 19 — until then `IslandState.lockRequested()` signal, connected in Task 19). Labels: "Blokowanie…", "Usypianie…", "Wylogowywanie…", "Ponowne uruchamianie…", "Wyłączanie…". On finish the state becomes `powerDone` with the label and the command runs immediately (in test mode it is only logged with `console.info`); `powerDone` auto-returns to `rest` after `Theme.motion.powerDoneMs` (R22).

- [ ] **Step 1: Write the check** — `tests/smoke/18-power.sh` (never presses a button):

```bash
call island open power
wait_ms 700
expect island current power
shot power
call island close
wait_ms 500
expect island current rest
```

- [ ] **Step 2: Run**; Read `power.png` → RED: empty 540×180, no dim.
- [ ] **Step 3: Implement** per §3.8: 5 round 60 px buttons, `danger` for Wyłącz, hold ring (`Shape` arc, progress over `Theme.motion.holdMs`, rewind `holdCancelMs`), release early cancels, L/S immediate, O/R/P hold; keyboard ←/→ + Enter hold + letters (R22); hover `Theme.hover` (R18).
- [ ] **Step 4: Run** all → PASS; Read `power.png`.
- [ ] **Step 5: Commit** — `quickshell: power menu with hold-to-confirm`

**— USER GATE 8 —** test: `call island open power`; hold ring fills/rewinds; Esc/click-outside; dim. The user tries Wyloguj/Restart/Wyłącz only if they want to.

---

## Group 9 — Lock (gate after Task 19)

### Task 19: Session lock

**Files:** Create `Lock.qml`, `states/LockCard.qml`, `tests/preview/LockPreview.qml`, `tests/smoke/19-lock-preview.sh`; Modify `shell.qml` (instantiate `Lock`), `IslandState.qml` (IPC `lock(): void`, `unlock(): void` recovery hatch without PAM — reachable only by processes of this user), `lib/theme.js` (`layout.lock`, `lock.timeoutDefault 300`)

Reference: §3.10, §4.5, §4.6 (lock/unlock rows), DESIGN §6 "Blokada", §7 R3, R10, R21, R32. PAM: `PamContext { config: "passwd"; configDirectory: Quickshell.shellDir + "/assets/pam.d" }` — the previous working implementation is `git show ff1f02d:config/quickshell/modules/Lock.qml` (follow its PAM flow, idle monitor and IPC). On PAM success keep `WlSessionLock.locked = true` until the reverse morph (`Theme.motion.lockMorphMs`) has finished, then unlock (DESIGN §6 "Sukces: odwrotny morfing do rest"). In test mode `lock()` only logs.

**Interfaces:**
- Produces: `states/LockCard.qml` — the card (clock 88 px, date, avatar initial + password field + →, status line, bottom row battery/Wi-Fi/notification count only), properties `property bool failed`, `property bool busy`, `signal submitted(string password)`, `function shake(): void`; usable outside a lock surface. `Lock.qml` — `WlSessionLock` with a surface per screen: wallpaper with `MultiEffect` blur/saturation/brightness/scale from `Theme.lockWallpaper` animated over `Theme.motion.wallpaperMs`, the card entering from the rest geometry (`lockMorphMs`), `MiniPlayer` at the bottom, Uśpij (immediate) / Wyłącz (hold, R32) bottom-right. `IdleMonitor { timeout: host lock.timeout ?? 300; respectInhibitors: true }`.
- `tests/preview/LockPreview.qml`: a `ShellRoot` with one `FloatingWindow` showing `LockCard` over the blurred wallpaper — for screenshots without locking.

- [ ] **Step 1: Write the check** — `tests/smoke/19-lock-preview.sh` (runs the preview file, NOT the real lock):

```bash
qs kill -p "$DIR" >/dev/null 2>&1
qs -p "$DIR/tests/preview/LockPreview.qml" -d >/dev/null 2>&1
sleep 2
shot lock-preview
qs kill -p "$DIR/tests/preview/LockPreview.qml" >/dev/null 2>&1
```

- [ ] **Step 2: Run** → RED: the preview fails to load (`LockCard` missing) — `shot` shows no card.
- [ ] **Step 3: Implement.** Do NOT call `island lock` from any test.
- [ ] **Step 4: Run** `node --test 'tests/*.test.mjs' && tests/smoke.sh tests/smoke/19-lock-preview.sh && tests/smoke.sh tests/smoke/00-start.sh`; Read `lock-preview.png` (card per §3.10).
- [ ] **Step 5: Commit** — `quickshell: session lock with PAM`

**— USER GATE 9 —** before testing tell the user the recovery path: from a TTY `loginctl unlock-session`, or `qs ipc -p <wt>/config/quickshell call island unlock`. Test: `call island lock`, wrong password → shake + danger ring, right password → unlock morph; idle lock after `lock.timeout`.

---

## Group 10 — Line mode, auto theme, binds, docs (gate after Task 22)

### Task 20: Fullscreen detection + line mode

**Files:** Create `lib/fullscreen.js`, `tests/fullscreen.test.mjs`, `services/Fullscreen.qml`, `tests/smoke/20-line.sh`; Modify `Island.qml` (line override + hover zone), `Strut.qml` (`exclusiveZone` 0 in line), `IslandState.qml` (IPC-readable `lineOn: string` — comma-joined screen names currently in line)

Reference: §2.6, DESIGN §2 + §4 `line`, W4, R16.

**Interfaces:**
- Produces (`lib/fullscreen.js`): `function fullscreenOutputs(toplevels: array<{fullscreen, title, appId, screens: array<string>}>, windows: array<{title, app_id, workspace_id}>, activeByOutput: object) → array<string>` — an output is fullscreen iff some toplevel with `fullscreen` on that screen matches (title + appId) a niri window whose `workspace_id` is the active workspace of that output. (`services/Fullscreen.qml`): `outputs: var` (array), `function on(name: string): bool`. Island: `line` = `(Fullscreen.on(screen) || IslandState.hidden) && effState === "rest" && !hovered`; hover zone `Theme.geom.hoverZone` at top centre added to the mask while in line; leave delay `lineLeaveDelayMs`.

- [ ] **Step 1: Write the failing test** — `tests/fullscreen.test.mjs`:

```js
import { test } from "node:test";
import assert from "node:assert/strict";
import { load, plain } from "./qmljs.mjs";

const F = load("lib/fullscreen.js");
const tl = (title, screens, fullscreen = true) => ({ title, appId: "mpv", screens, fullscreen });
const win = (title, workspace_id) => ({ title, app_id: "mpv", workspace_id });

test("fullscreen window on the active workspace marks its output", () => {
    assert.deepStrictEqual(plain(F.fullscreenOutputs([tl("film", ["DP-2"])], [win("film", 1)], { "DP-2": 1 })), ["DP-2"]);
});

test("fullscreen window on an inactive workspace does not", () => {
    assert.deepStrictEqual(plain(F.fullscreenOutputs([tl("film", ["DP-2"])], [win("film", 2)], { "DP-2": 1 })), []);
});

test("non-fullscreen and other outputs", () => {
    assert.deepStrictEqual(plain(F.fullscreenOutputs([tl("a", ["DP-2"], false)], [win("a", 1)], { "DP-2": 1 })), []);
    assert.deepStrictEqual(plain(F.fullscreenOutputs([tl("b", ["HDMI-A-1"])], [win("b", 5)], { "DP-2": 1, "HDMI-A-1": 5 })), ["HDMI-A-1"]);
});
```

- [ ] **Step 2: Run** (stub) → FAIL.
- [ ] **Step 3: Implement** (bind to `ToplevelManager.toplevels.values` — it fills lazily; map `screens` to names).
- [ ] **Step 4: Write and run** `tests/smoke/20-line.sh`:

```bash
call island hide
wait_ms 700
expect island hidden true
shot line
call island hide
wait_ms 700
expect island hidden false
```

  → PASS; Read `line.png` (56×5 light bar, no ears/ring/gloss/shadow). Also `node --test 'tests/*.test.mjs'` → PASS.
- [ ] **Step 5: Commit** — `quickshell: line mode on fullscreen and on demand`

### Task 21: Automatic theme mode + legibility boost

**Files:** Create `lib/autotheme.js`, `tests/autotheme.test.mjs`, `services/AutoTheme.qml`; Modify `shell.qml` (reference `AutoTheme` so it runs), `lib/theme.js` (tokens already present from Task 2: `modeSource`, `location`, `wallpaperLight/Dark`, `legibility`), `Theme.qml` (`islandBg` alpha + `legibility.boost` when `AutoTheme.boost`)

Reference: §2b, §7 R34.

**Interfaces:**
- Produces (`lib/autotheme.js`): `function sunTimes(date: Date, lat: number, lon: number) → {sunrise: Date, sunset: Date} | null` (NOAA approximation; null for polar day/night); `function luminance(r, g, b) → number` (0..1, Rec. 709 on sRGB-linearised channels); `function nextMode(current: string, lum: number, lightAbove: number, darkBelow: number) → string` (hysteresis). (`services/AutoTheme.qml`): sets `Theme.autoMode` for `modeSource` `sun` (re-evaluated every minute; no location → "") and `wallpaper` (mean colour of `Theme.wallpaper` from Quickshell's `ColorQuantizer { source; depth: 0; rescaleSize }` — a hidden `Canvas` would never paint); `boost: bool` = dark mode and luminance of the wallpaper's top-centre region (`ColorQuantizer.imageRect` = screen-proportional crop under the island) > `legibility.threshold`.

- [ ] **Step 1: Write the failing test** — `tests/autotheme.test.mjs`:

```js
import { test } from "node:test";
import assert from "node:assert/strict";
import { load } from "./qmljs.mjs";

const A = load("lib/autotheme.js", { Date });

test("sunTimes(): equator at the March equinox is ~06:00/18:00 UTC", () => {
    const t = A.sunTimes(new Date(Date.UTC(2026, 2, 20, 12)), 0, 0);
    const h = d => d.getUTCHours() + d.getUTCMinutes() / 60;
    assert.ok(h(t.sunrise) > 5.9 && h(t.sunrise) < 6.25, String(t.sunrise));
    assert.ok(h(t.sunset) > 17.95 && h(t.sunset) < 18.3, String(t.sunset));
});

test("sunTimes(): polar day is null", () => {
    assert.equal(A.sunTimes(new Date(Date.UTC(2026, 5, 21, 12)), 78, 15), null);
});

test("luminance()", () => {
    assert.equal(A.luminance(0, 0, 0), 0);
    assert.ok(Math.abs(A.luminance(255, 255, 255) - 1) < 1e-9);
    assert.ok(A.luminance(0, 255, 0) > A.luminance(255, 0, 0));
});

test("nextMode(): hysteresis", () => {
    assert.equal(A.nextMode("dark", 0.55, 0.6, 0.5), "dark");
    assert.equal(A.nextMode("dark", 0.65, 0.6, 0.5), "light");
    assert.equal(A.nextMode("light", 0.55, 0.6, 0.5), "light");
    assert.equal(A.nextMode("light", 0.45, 0.6, 0.5), "dark");
});
```

- [ ] **Step 2: Run** (stub) → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `node --test 'tests/*.test.mjs' && tests/smoke.sh tests/smoke/02-theme.sh` → PASS (manual mode unaffected). Then `tests/smoke/21-auto.sh` (write it before the QML service and see it FAIL first):

```bash
python3 -I -c 'from PIL import Image; Image.new("RGB", (64, 64), (250, 250, 250)).save("/tmp/wyspa-bright.png")'
expect theme mode dark
printf '{"wallpaper":"/tmp/wyspa-bright.png","lock":{"timeout":0},"island":{"modeSource":"wallpaper"}}' > "$CFG"
wait_ms 1500
expect theme mode light
```

  → PASS.
- [ ] **Step 5: Commit** — `quickshell: automatic theme mode (sun, wallpaper) and legibility boost`

### Task 22: niri binds, CLAUDE.md, spec state

**Files:** Modify `config/niri/bindings.kdl` (repo path), `docs/DESIGN.md` §7 (architecture → as built), `README.md` (repo root: the "Lock `unlock` IPC" note → `qs ipc call island unlock` in `config/quickshell/IslandState.qml`); Create `CLAUDE.md`

- [ ] **Step 1: Binds** — retarget the existing binds only: `Mod+Space` → `qs ipc call island toggle launcher`; `Mod+Shift+V` → `qs ipc call island launcherMenu clipboard`; `Mod+L` → `qs ipc call island lock`. Add a commented block (no active binds) listing the future ones: `// Mod+A → island toggle control`, `// Mod+N → island toggle center`, `// Mod+M → island toggle media (conflicts: edexplore macro)`, `// Mod+Shift+E → island toggle power (conflicts: screenshot)`, `// Mod+Shift+H → island hide`, brightness keys → `brightnessctl set 5%+/-`. Run `tests/niri-validate.sh` → exit 0.
- [ ] **Step 2: `CLAUDE.md`** — what this is (dotter deploys files individually into `~/.config/quickshell`, new files need `dotter deploy`), running (`qs`, `qs -p .`), tests (`node --test 'tests/*.test.mjs'`, `tests/smoke.sh tests/smoke/<x>.sh`, `tests/shot.sh`), structure (one line per root file, `lib/`, `states/`, `components/`, `services/`), conventions (Theme-only literals + guard test, how to add a state: geometry row in `lib/theme.js` + `lib/island.js` PRIORITY + `IslandContent.sources` entry + `states/X.qml`), IPC targets `island`/`theme`/`notifs` with their functions, gotchas (Region tracking, lazy ToplevelManager, typed IPC, lock recovery path, niri rule for blur).
- [ ] **Step 3: DESIGN.md** — §7 "Architektura" rewritten to the files that exist (no "propozycja"). Do not touch other sections.
- [ ] **Step 4: Verify** — `node --test 'tests/*.test.mjs'` and every `tests/smoke/*.sh` except `19-lock-preview.sh` through `tests/smoke.sh` → all PASS.
- [ ] **Step 5: Commit** — `git add -A . ../niri ../../README.md` — `quickshell: niri binds retargeted, CLAUDE.md, DESIGN architecture as built`

**— USER GATE 10 —** final manual pass, then finishing-a-development-branch (merge → `dotter deploy`, `systemctl --user restart quickshell`, niri reloads its config itself).
