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

### Task 6: Content host with enter/exit choreography

**Files:** Create `IslandContent.qml`, `tests/smoke/06-content.sh`; Modify `Island.qml`, `IslandShape.qml` (host goes into `content`), `IslandState.qml` (readable `contentState` for tests).

Reference: §2.2, §2.8, §4.6 row "state change", §7 R25.

**Interfaces:**
- Consumes: `Island.effState`, `Theme.motion.*`, `IslandState.geometryFor(s)`.
- Produces: `IslandContent.qml` with `property string target` (bound to `effState`; not `state`, which would shadow `Item.state`), `property string output` (screen name), `readonly property string shown` (the state whose layer is fully entered, "" during transition), and `property var sources: ({})` — map state → `Qt.resolvedUrl("states/X.qml")`; **each later state task adds exactly one entry**. Every state component gets `property bool active` (true while its layer is "on") and `property string output` set by the host; it must size itself from `Theme.geom.<state>` (target width from the start, never reflowing). `IslandState` gains IPC-readable `contentState: string` = the `shown` value of the island on `IslandState.output`, or on `Niri.focusedOutput` while `current === "rest"` (Island registers it via `IslandState.reportShown(output: string, s: string)`).

- [ ] **Step 1: Write the check** — `tests/smoke/06-content.sh`:

```bash
expect island contentState rest
call island open launcher
expect island contentState ""
wait_ms 600
expect island contentState launcher
call island close
wait_ms 600
expect island contentState rest
```

- [ ] **Step 2: Run** → FAIL (`contentState` property not found).
- [ ] **Step 3: Implement** — one layer `Item` per entry in `sources` (all `Loader`s stay active — prototypes keep every layer mounted), width/height = that state's geometry, centred, `y: 0`, `transformOrigin: Item.Center`. On/off values per §2.8: opacity 0→1 (`enterOpacityMs`, `enterCurve`, delay `enterOpacityDelayMs`) / →0 (`exitOpacityMs`, `easeCurve`); scale `contentScaleFrom`→1 (`enterScaleMs`, delay `enterScaleDelayMs`) / →`contentScaleFrom` (`exitScaleMs`); blur `contentBlur`→0 via `MultiEffect` (`layer.enabled` only while blur > 0). Use `Behavior { SequentialAnimation { PauseAnimation { duration: on ? delay : 0 } NumberAnimation { … } } }`. Off layers: `enabled: false`. Reduced motion: opacity only, `reducedFadeMs`, no scale/blur, no delay. `shown` = the state whose layer has finished its enter animation; for states with no entry in `sources` the host still reports `shown` after `enterOpacityDelayMs + enterOpacityMs`.
- [ ] **Step 4: Run** all tests → PASS.
- [ ] **Step 5: Commit** — `quickshell: island content host with enter/exit choreography`

**— USER GATE 2 —** test: morph between states via `qs ipc -p … call island open launcher|control|toast|osd|media|power|center`, `close`; interrupt a morph mid-way; Esc/click-outside closes launcher/control (gate instance runs without `WYSPA_TEST`, so it has keyboard focus); exclusive zone (windows shift down) on every monitor; glass/gloss/ring look; `"island": {"glass": false}` in the gate's `WYSPA_CONFIG` copy → solid, nothing blurred around. The niri blur rule is live already; the 44 px window offset (struts removal) appears only after merge.

---
