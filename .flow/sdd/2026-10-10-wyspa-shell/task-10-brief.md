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

### Task 10: Brightness service + OSD state

**Files:** Create `services/Brightness.qml`, `states/Osd.qml`, `tests/smoke/10-osd.sh`; Modify `IslandContent.qml` (`sources.osd`), `IslandState.qml` (triggers), `lib/theme.js` (`layout.osd`)

Reference: §3.2, §4.1 (volume), §7 R31; DESIGN W10.

**Interfaces:**
- Produces (`services/Brightness.qml`): `available: bool` (a directory exists under `/sys/class/backlight/`), `value: real` (0..1, read from `brightness`/`max_brightness` via `FileView` with `watchChanges`), `function set(v: real): void` (`Quickshell.execDetached(["brightnessctl", "set", Math.round(v*100) + "%"])`). On `pc` `available` is false.
- Produces (`IslandState`): `osdKind: string`, `osdValue: real`, `osdMuted: bool`; changes of `Audio.volume`/`Audio.muted` and `Brightness.value` call `request("osd")` with the right kind — but only after a `ready` gate (ignore the values settling during the first `Theme.motion.osdTimeoutMs` after startup, like the old `modules/Osd.qml` did).
- `states/Osd.qml`: icon (`volume-x|volume-1|volume-2` by level/mute, `sun` for brightness), track `Theme.track` with accent fill animating width `Theme.motion.osdBarMs` (`enterCurve`), mono value.

- [ ] **Step 1: Write the check** — `tests/smoke/10-osd.sh`:

```bash
wait_ms 1800
wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+
wait_ms 200
expect island current osd
wait_ms 500
shot osd
wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-
wait_ms 1700
expect island current rest
```

- [ ] **Step 2: Run** → FAIL (`current` stays `rest`).
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** all → PASS; Read `osd.png` (300×44 with icon, bar, value).
- [ ] **Step 5: Commit** — `quickshell: OSD for volume and brightness`

**— USER GATE 4 —** test: volume keys → OSD on the focused monitor, timer restarts while holding the key, mute icon; on `laptop` brightness keys (needs `brightnessctl` installed there).

---
