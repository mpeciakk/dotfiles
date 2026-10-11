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

### Task 22: niri binds, CLAUDE.md, spec state

**Files:** Modify `config/niri/bindings.kdl` (repo path), `docs/DESIGN.md` §7 (architecture → as built), `README.md` (repo root: the "Lock `unlock` IPC" note → `qs ipc call island unlock` in `config/quickshell/IslandState.qml`); Create `CLAUDE.md`

- [ ] **Step 1: Binds** — retarget the existing binds only: `Mod+Space` → `qs ipc call island toggle launcher`; `Mod+Shift+V` → `qs ipc call island launcherMenu clipboard`; `Mod+L` → `qs ipc call island lock`. Add a commented block (no active binds) listing the future ones: `// Mod+A → island toggle control`, `// Mod+N → island toggle center`, `// Mod+M → island toggle media (conflicts: edexplore macro)`, `// Mod+Shift+E → island toggle power (conflicts: screenshot)`, `// Mod+Shift+H → island hide`, brightness keys → `brightnessctl set 5%+/-`. Run `tests/niri-validate.sh` → exit 0.
- [ ] **Step 2: `CLAUDE.md`** — what this is (dotter deploys files individually into `~/.config/quickshell`, new files need `dotter deploy`), running (`qs`, `qs -p .`), tests (`node --test 'tests/*.test.mjs'`, `tests/smoke.sh tests/smoke/<x>.sh`, `tests/shot.sh`), structure (one line per root file, `lib/`, `states/`, `components/`, `services/`), conventions (Theme-only literals + guard test, how to add a state: geometry row in `lib/theme.js` + `lib/island.js` PRIORITY + `IslandContent.sources` entry + `states/X.qml`), IPC targets `island`/`theme`/`notifs` with their functions, gotchas (Region tracking, lazy ToplevelManager, typed IPC, lock recovery path, niri rule for blur).
- [ ] **Step 3: DESIGN.md** — §7 "Architektura" rewritten to the files that exist (no "propozycja"). Do not touch other sections.
- [ ] **Step 4: Verify** — `node --test 'tests/*.test.mjs'` and every `tests/smoke/*.sh` except `19-lock-preview.sh` through `tests/smoke.sh` → all PASS.
- [ ] **Step 5: Commit** — `git add -A . ../niri ../../README.md` — `quickshell: niri binds retargeted, CLAUDE.md, DESIGN architecture as built`

**— USER GATE 10 —** final manual pass, then finishing-a-development-branch (merge → `dotter deploy`, `systemctl --user restart quickshell`, niri reloads its config itself).
