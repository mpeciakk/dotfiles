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
