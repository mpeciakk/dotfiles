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

### Task 19: Session lock

**Files:** Create `Lock.qml`, `states/LockCard.qml`, `tests/preview/LockPreview.qml`, `tests/smoke/19-lock-preview.sh`; Modify `shell.qml` (instantiate `Lock`), `IslandState.qml` (IPC `lock(): void`, `unlock(): void` recovery hatch without PAM — reachable only by processes of this user), `lib/theme.js` (`layout.lock`, `lock.timeoutDefault 300`)

Reference: §3.10, §4.5, §4.6 (lock/unlock rows), DESIGN §6 "Blokada", §7 R3, R10, R21, R32. PAM: `PamContext { config: "passwd"; configDirectory: Quickshell.shellDir + "/assets/pam.d" }` — the previous working implementation is `git show ff1f02d:config/quickshell/modules/Lock.qml` (follow its PAM flow, idle monitor and IPC). On PAM success keep `WlSessionLock.locked = true` until the reverse morph (`Theme.motion.lockMorphMs`) has finished, then unlock (DESIGN §6 "Sukces: odwrotny morfing do rest"). In test mode `lock()` only logs.

**Interfaces:**
- Produces: `states/LockCard.qml` — the card (clock 88 px, date, avatar initial + password field + →, status line, bottom row battery/Wi-Fi/notification count only), properties `property bool failed`, `property bool busy`, `signal submitted(string password)`, `function shake(): void`; usable outside a lock surface. `Lock.qml` — `WlSessionLock` with a surface per screen: wallpaper with `MultiEffect` blur/saturation/brightness/scale from `Theme.lockWallpaper` animated over `Theme.motion.wallpaperMs`, the card entering from the rest geometry (`lockMorphMs`), `MiniPlayer` at the bottom, Uśpij (immediate) / Wyłącz (hold, R32) bottom-right. `IdleMonitor { timeout: host lock.timeout ?? 300; respectInhibitors: true }`.
- `tests/preview/LockPreview.qml`: a `ShellRoot` with one `FloatingWindow` showing `LockCard` over the blurred wallpaper — for screenshots without locking.

- [ ] **Step 1: Write the check** — `tests/smoke/19-lock-preview.sh` (runs the preview file, NOT the real lock):

```bash
qs kill -p "$DIR" >/dev/null 2>&1
qs -p "$DIR/tests/preview/LockPreview.qml" -d >/dev/null 2>&1
sleep 2
shot lock-preview
qs kill -p "$DIR/tests/preview/LockPreview.qml" >/dev/null 2>&1
```

- [ ] **Step 2: Run** → RED: the preview fails to load (`LockCard` missing) — `shot` shows no card.
- [ ] **Step 3: Implement.** Do NOT call `island lock` from any test.
- [ ] **Step 4: Run** `node --test 'tests/*.test.mjs' && tests/smoke.sh tests/smoke/19-lock-preview.sh && tests/smoke.sh tests/smoke/00-start.sh`; Read `lock-preview.png` (card per §3.10).
- [ ] **Step 5: Commit** — `quickshell: session lock with PAM`

**— USER GATE 9 —** before testing tell the user the recovery path: from a TTY `loginctl unlock-session`, or `qs ipc -p <wt>/config/quickshell call island unlock`. Test: `call island lock`, wrong password → shake + danger ring, right password → unlock morph; idle lock after `lock.timeout`.

---
