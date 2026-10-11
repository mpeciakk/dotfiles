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
