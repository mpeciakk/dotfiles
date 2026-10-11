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
