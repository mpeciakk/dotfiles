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

### Task 4: IslandState singleton + IPC

**Files:** Create `IslandState.qml`, `tests/smoke/04-state.sh`; Modify `shell.qml` (instantiate nothing — singletons load on first use; reference `IslandState` once from `shell.qml`, e.g. `Component.onCompleted: IslandState.current`, so the IPC handler registers at startup).

**Interfaces:**
- Consumes: `lib/island.js` (`accepts`, `isModal`, `geometry`), `Theme.geom`, `Theme.motion`, `Niri.focusedOutput` (`services/Niri.qml`).
- Produces (singleton `IslandState`): `current: string`, `output: string` (screen name the non-rest state shows on), `hidden: bool`, `modal: bool`, `centerHeight: int` (writable, Center sets it), `badge: bool` (writable for now; Task 8 binds it), `osdKind: string` ("volume"|"brightness"), `function request(s: string): bool`, `function close(): void`, `function toggle(s: string): void`, `function toggleHidden(): void`, `function geometryFor(s: string): var`. Per-state timers: `osd` → `Theme.motion.osdTimeoutMs`, `toast` → `toastTimeoutMs`, `powerDone` → `powerDoneMs`; a repeated `request` of the same timed state restarts its timer; on expiry `close()` only if still in that state. `IpcHandler { target: "island" }`: `open(s: string): void`, `toggle(s: string): void`, `close(): void`, `hide(): void`; readable `current: string`, `output: string`, `hidden: bool`, `targetW: int`, `targetH: int` (geometry of `current` with live ctx).

- [ ] **Step 1: Write the check** — `tests/smoke/04-state.sh`:

```bash
expect island current rest
expect island targetW 200
call island open launcher
expect island current launcher
expect island targetW 680
expect island targetH 356
call island open toast
expect island current launcher
call island close
expect island current rest
call island open osd
expect island current osd
wait_ms 1000
call island open osd
wait_ms 1000
expect island current osd
wait_ms 800
expect island current rest
call island toggle control
expect island current control
call island toggle control
expect island current rest
call island open bogus
expect island current rest
call island hide
expect island hidden true
call island hide
expect island hidden false
```

- [ ] **Step 2: Run** — `tests/smoke.sh tests/smoke/04-state.sh` → Expected: FAIL (`island` target unknown).
- [ ] **Step 3: Implement** `IslandState.qml` (`pragma Singleton`, `import "lib/island.js" as L`, `import "services"`). `output` is set to `Niri.focusedOutput` on every accepted non-rest request.
- [ ] **Step 4: Run** `node --test 'tests/*.test.mjs' && tests/smoke.sh tests/smoke/04-state.sh` → PASS.
- [ ] **Step 5: Commit** — `quickshell: IslandState machine with island IPC`
