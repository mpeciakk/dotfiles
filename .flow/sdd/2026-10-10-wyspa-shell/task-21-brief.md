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
