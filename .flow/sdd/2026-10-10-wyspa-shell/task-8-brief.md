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
