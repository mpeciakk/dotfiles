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
