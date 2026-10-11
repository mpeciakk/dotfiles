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
