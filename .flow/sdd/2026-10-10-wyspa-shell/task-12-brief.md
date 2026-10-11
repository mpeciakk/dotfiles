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
