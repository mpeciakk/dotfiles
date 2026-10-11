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
