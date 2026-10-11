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
