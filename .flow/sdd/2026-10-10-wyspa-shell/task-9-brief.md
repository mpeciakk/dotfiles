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

### Task 9: Rest state

**Files:** Create `states/Rest.qml`, `tests/smoke/09-rest.sh`; Modify `IslandContent.qml` (`sources.rest`), `lib/theme.js` (`layout.rest`)

Reference: §3.1, DESIGN §6 "Spoczynek", §7 R19, R27.

**Interfaces:**
- Consumes: `Niri.workspaces`, `Niri.activeByOutput`, `Time` (`services/Time.qml`), `Players.active`, `Notifs.unread`, `Notifs.dnd`, `IslandState.request`, `components/Icon.qml`.
- Produces: `states/Rest.qml` (`property bool active`, `property string output`).

- [ ] **Step 1: Write the check** — `tests/smoke/09-rest.sh`:

```bash
wait_ms 600
shot rest
expect island contentState rest
```

- [ ] **Step 2: Run**; Read `rest.png` → Expected RED: empty pill (no dots, no clock).
- [ ] **Step 3: Implement** per §3.1: workspace dots for this output (active = pill 14×5 accent, others 5×5 `Theme.dotInactive`, animated width/colour), mono clock 13 px, 3-bar equaliser animating (`Theme.motion.eqMs`) only while `Players.active?.isPlaying`, badge (pill `Theme.accentSoft` + `bell` or `moon` when DND + count) only when `Notifs.unread > 0`. Click badge → `IslandState.request("center")`; click elsewhere → `request("control")`.
- [ ] **Step 4: Run** `node --test 'tests/*.test.mjs' && tests/smoke.sh tests/smoke/09-rest.sh`; Read `rest.png` → dots + clock visible, matching §3.1 spacing.
- [ ] **Step 5: Commit** — `quickshell: rest state (workspaces, clock, music, badge)`

**— USER GATE 3 —** test: dots follow workspace switches per monitor; clock; music bars with a playing player; `notify-send` → badge (252 px), DND moon (`call notifs dnd true`); click → control (empty), badge click → center (empty).

---
