# Task 19 — Session lock: report

**Status:** DONE_WITH_CONCERNS. The main concern: the preview file had to move from where the brief puts it (see Concerns 1).
**Commit:** `47553d9 quickshell: session lock with PAM` on `worktree-feat+wyspa-shell`.
**Machine:** pc. Nothing in any test or probe locked the session. `island lock`, `qs ipc … call lock …` and `loginctl lock-session` were never called.

## Recovery (tell the user before Gate 9)

- **The shell is running and the session is locked:** from a TTY (Ctrl+Alt+F2), log in as the same user. If `$XDG_RUNTIME_DIR` is unset, run `export XDG_RUNTIME_DIR=/run/user/1000` first, or `qs ipc` silently finds no instances. Then run
  `qs ipc -p /home/m/dotfiles/.claude/worktrees/feat+wyspa-shell/config/quickshell call island unlock`.
  This drops the lock at once, without PAM and without the morph (`Lock.qml unlockNow()`). Only this user can reach the IPC socket, because `/run/user/1000` is `drwx------ m m`.
- **`loginctl unlock-session`:** this works only if something listens for logind's Unlock signal. Neither this shell nor the old one (ff1f02d) listens for it, and I don't think niri does. Expect it to do nothing. The brief and the dispatch both list it; I am flagging it rather than promising it works.
- **The shell has died while locked:** niri keeps the screen locked and blank (Quickshell docs: "conformant compositors will leave the screen locked and painted with a solid color"). The `island unlock` hatch is gone with the process. From a TTY the user has to start a lock client that can take over a dead lock and release it. That is either a new shell instance (`island lock` and then `island unlock` on it), if niri accepts a new lock after the old client died, or another locker. I did not verify this: verifying it needs a real lock.
- **`pam_faillock`:** `assets/pam.d/passwd` (unchanged from ff1f02d) runs `pam_faillock`. Several wrong passwords in a row at Gate 9 can lock the account for some minutes (default deny=3, unlock_time=600). After that even the correct password fails until the time runs out. The `island unlock` hatch still works in that state.

## What I implemented

- **`lib/lock.js`** (`.pragma library`, no imports). It holds the pure decisions:
  - `engage(testMode, locked)` returns `{engage, message}`. Only an explicit `false` test mode can lock, and never a second time. An unset or odd value fails safe.
  - `idle(hostTimeout, default, testMode)` returns `{enabled, timeout}`. A missing timeout means the default. A positive number is used as is. 0, a negative number or a non-number disables the idle lock, and test mode always disables it. The timeout handed to the monitor stays positive even when disabled, because `IdleMonitor.timeout: 0` reports idle at once.
  - `notifCount(n)` gives the Polish plural ("2 powiadomienia", "5 powiadomień", "12 powiadomień").
  - `initial(name, user)` gives the avatar's letter.
- **`Lock.qml`** (a `Scope`, instantiated once in `shell.qml`):
  - **`engageLock(source)`** is the only place that sets `sessionLock.locked = true`. It calls `L.engage(root.testMode, sessionLock.locked)` first and returns on `!d.engage`. Three requests arrive there: the power menu's Zablokuj (`IslandState.lockRequested`, from the gate), the IPC (`IslandState.lockAsked`) and the IdleMonitor (`onIsIdleChanged: if (isIdle) root.engageLock("idle")`). `locked` is never bound declaratively.
  - **`locked = false`** is set in exactly two places: `releaseTimer` (after `lockMorphMs`, once PAM has accepted) and `unlockNow()` (the hatch).
  - **IdleMonitor:** `enabled: root.idle.enabled && !sessionLock.locked`, `timeout: root.idle.timeout`, `respectInhibitors: true`. The timeout comes from host `lock.timeout`, defaulting to `Theme.tokens.lock.timeoutDefault` (300).
  - **PAM:** `PamContext { config: "passwd"; configDirectory: Quickshell.shellDir + "/assets/pam.d" }`, following the old flow. `pam.start()` appears only in `authenticate()`, after `if (root.testMode) { console.info(…); return; }`.
    - The typed text is held in `pending` from submit until PAM asks for it, then cleared.
    - It is also cleared on completion, on error and when the lock goes.
    - Only `PamResult.Success` unlocks; any other result or an error calls `refuse()` (`failed` = true and every card shakes).
    - Logs say only "authentication failed" / "succeeded"; the text and the PAM messages are never logged.
  - **Per surface (`WlSessionLockSurface`, opaque black):**
    - the wallpaper `Image` with a `MultiEffect` (blur, saturation `saturate−1`, brightness `brightness−1`) and scale, driven by a `veil` value 0→1 over `wallpaperMs` on Curve S;
    - the `LockCard`, whose width, height, x, y and corner radii are interpolated by a `morph` value 0→1 over `lockMorphMs` on Curve S. It starts at the rest island (top centre, `geom.rest`, or `restBadge` while there is a badge, corners 0/18) and ends at the centred card (R21, 460×360, r36);
    - the extras: `MiniPlayer` at bottom 32 in `lockGlass` + ring, and the Uśpij / Wyłącz corner buttons bottom-right (48 px, r24, `lockGlass` + ring). They fade in after 520 ms and fade out at once, and take input only while locked and shown.
  - **On PAM success:** `unlocking` = true, so `shown` becomes false and everything plays in reverse. `releaseTimer` (`lockMorphMs`) then sets `locked = false`.
  - **Corner buttons:** one `Components.PowerActions { id: actions }`; the only call is `actions.perform(r.effect.kind)`.
    - Uśpij: `pointerClick` → `P.reduce` → finish `"sleep"`. The dispatch said `perform("suspend")`, but `P.item("suspend")` is `null` (the ITEMS id is `"sleep"`; `"suspend"` is the command key). `"suspend"` would also do nothing and trip the power-word guard.
    - Wyłącz: `pointerPress` → hold start → `holdTimer` (`holdMs`) → finish `"off"`, with a danger ring (R32). Release, exit or cancel stops the hold, using the existing `P.reduce` unchanged.
    - **Keyboard:** only `keyUp` is passed to the reducer, from a `Keys.onReleased` on the card's parent that never accepts the event. The intent is that any key release ends a running pointer hold (the safe side). Whether `TextInput` lets releases propagate up was not exercised, so this is unverified until Gate 9 (Concerns 5). The primary guarantee is that no keyDown ever reaches the reducer. `keyDown` is never passed, so a letter typed into the password field (P, O, R, L, S, Enter) cannot start or confirm anything. Showing or hiding the surface sends `active`, which cancels any hold.
  - **`unlockNow()`:** aborts PAM if it is running, clears `pending`, stops the release timer and sets `locked = false`. While nothing is locked it is harmless.
  - **`onLockStateChanged`** (the `notify` of `locked` in the qmltypes) calls `IslandState.reportLocked(sessionLock.locked)` and resets the state on unlock.
- **`states/LockCard.qml`:**
  - Interface: `failed`, `busy`, `signal submitted(string password)`, `shake()`. I added `topRadius`, `bottomRadius` and `revealed` (inputs for the morph and the enter/exit) and `focusField()`.
  - Material: island material (`islandBg`, ring, gloss gradient + outline at `Theme.sheen`, R3) and a `RectangularShadow` from the `lockShadow*` tokens.
  - Clock: 88 px, weight 500, −0.045 em, tabular, fixed line height 88.
  - Date: `weekdayStr, dayMonthStr` in `fgLock`.
  - Password field: 340×52, r26, `lockField` fill, 1 px `lockFieldRing` ring, which turns into a 1.5 px `danger` ring on error with a 200 ms colour fade, and a focus outline at accent@0.8, offset 3. Inside it:
    - avatar 36 px in accent with the initial in `onAccent`, weight 600;
    - `TextInput` with `echoMode: Password`, sensitive-data input hints, 0.12 em letter spacing and the "Hasło" placeholder;
    - submit button 36 px in `inverseBg` with `arrow-right`, named "Odblokuj".
  - Status line: "Niepoprawne hasło — spróbuj ponownie" in `danger`, or "Sprawdzanie…" while busy.
  - Bottom row: battery if present, Wi-Fi if connected, `bell` + count only.
  - Shake: five eased steps (−10, 8, −6, 3, 0) of `shakeMs/5` with `shakeCurve`.
  - Typing hides the error (`showError = failed && field empty`); the next submit resets `failed`.
  - Submit clears the field. The typed text is exposed only through `submitted()`.
- **`IslandState.qml`:**
  - `property bool locked` (written only by `reportLocked()`), `signal lockAsked`, `signal unlockAsked`.
  - IPC on the `island` target: `readonly property bool locked`, `lock(): void` → `lockAsked()`, `unlock(): void` → `unlockAsked()`.
  - No IPC target named `lock`. `lockRequested` stays emitted only by the gate.
- **`lib/theme.js`:** `lock: { timeoutDefault: 300 }` and `layout.lock`, with every px/ms value from §3.10 / §4.6, plus `shakeSteps`, `focusAlpha 0.8` and `percent 100`.
- **`shell.qml`:** `Lock {}`, outside the per-screen Variants.
- **`tests/shot.sh`:** the dispatch's exact line, `[ "$(qs ipc -p "$DIR" prop get island locked 2>/dev/null || true)" == "true" ]`, sits next to the old check, which I kept.
- **`LockPreview.qml`** (config root, see Concerns 1): a `ShellRoot` with one fixed-size `FloatingWindow` (twice the card) showing the `LockCard` over the wallpaper, blurred with the locked-end `Theme.lockWallpaper` values. No WlSessionLock, no PAM, no IslandState.
- **`tests/smoke/19-lock-preview.sh`:**
  - Against the running test instance: `expect island locked false`, `call island unlock`, `expect island locked false`.
  - It then chains the preview's kill in front of smoke.sh's EXIT trap (`trap -p EXIT`, stripped and prefixed, so smoke.sh's own `qs kill -p "$DIR"; rm -f "$CFG"` still runs).
  - Then: kill `$DIR`, start the preview, check the preview's own log against `allowed-warnings.txt` (smoke.sh only reads `$DIR`'s log), take one `shot lock-preview`, kill the preview.
- **Tests:**
  - New `tests/lock.test.mjs`: 9 tests for `lib/lock.js` and the defaults, and 13 source-guard tests.
  - `tests/power.test.mjs`: the callers pin is now exactly `["Lock.qml", "states/Power.qml"]`, with a comment, plus a test that Lock.qml only calls `actions.perform(` and defines no `perform`.
  - `tests/theme.test.mjs`: a `layout.lock` defaults test.

## Tests and results

- `node --test 'tests/*.test.mjs'`: **175/175 pass**, 0 fail (saved in /tmp/task19-green-node.txt).
- `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh tests/smoke/19-lock-preview.sh`: **exit 0**. Output:
  ```
  ok: island.locked = false
  ok: island.locked = false
  ok: preview loaded cleanly
  /tmp/wyspa-shots/lock-preview.png
  ```
- `tests/smoke.sh tests/smoke/00-start.sh`: exit 0, log clean. The shot-free checks 02-theme, 04-state, 06-content, 08-notifs and 11-series also exit 0, with no FAIL lines.
- `qs list --all` after every run: `No running instances.`
- **Manual test-mode instance** (`WYSPA_TEST=1 qs -p . -d`):
  - `qs ipc show` lists `function lock(): void`, `function unlock(): void` and `property locked: bool` on `island`.
  - `prop get island locked` → `false`; `call island unlock`; again `false`.
  - The log shows `lock: unlock hatch` and nothing else lock-related.
  - Killed by path afterwards.
- **Mutation check of the lock guard** (`/tmp/task19-mutate.mjs`, which mutates Lock.qml, runs tests/lock.test.mjs and restores the file). Every mutation fails the suite:

  | Mutation | Result |
  |---|---|
  | Release timer sets `!false` | fail 1 |
  | `!d.engage` return removed | fail 1 |
  | Declarative `locked:` binding added | fail 1 |
  | Idle sets `locked = true` directly | fail 2 |
  | Idle `enabled` without `L.idle` | fail 1 |
  | Logging `root.pending` | fail 1 |
  | PAM test-mode return removed | fail 1 |
  | `testMode` hard-wired to `false` | fail 1 |

  Lock.qml was restored and the suite is back to 0 fail.
- **Trap test:** a copy of the check with `return 1` right after the preview launch (`/tmp/task19-trapcheck.sh`, run offscreen so no window appeared and no shot was taken). It printed `preview alive before return: 1`. Afterwards `qs list --all` showed `No running instances.` and the temp config `/tmp/wyspa-config.*.json` was gone, so the preview was killed and smoke.sh's own trap ran too. (The offscreen main instance itself fails to load with "No PanelWindow backend", which is expected offscreen and irrelevant to this test.)

## TDD evidence

- **RED 1 (node).** Command: `node --test tests/lock.test.mjs`, run with only the test file present (no `lib/lock.js`, no `Lock.qml`, IslandState and shot.sh unchanged). Result: `pass 1 / fail 21`, e.g. `TypeError: L.engage is not a function`, `AssertionError: Lock.qml missing`, `Cannot read properties of undefined (reading 'timeoutDefault')`. These failures were expected because the library, the tokens, Lock.qml and the IslandState IPC did not exist yet. The one pass is "no QML registers an IPC target named lock", a regression guard that is already true.
- **RED 2 (theme).** Command: `node --test tests/theme.test.mjs`. Result: `fail 1`, "defaults: layout.lock matches reference 3.10 and §4.6", because `layout.lock` was missing.
- **RED 3 (power pin).** Command: `node --test tests/power.test.mjs`. Result: `fail 2`: the new Lock.qml gate test, and the callers list, which was still `["states/Power.qml"]`.
- **RED 4 (check file, brief step 2).** Command: `tests/smoke.sh tests/smoke/19-lock-preview.sh`. Result: `exit 1`, with `ERROR: caused by @LockPreview.qml[48:9]: Type States.LockCard unavailable`. This was expected, because LockCard did not exist. The RED shot (`lock-preview-full.png`) showed no card; the focused monitor was showing a fullscreen game at the time (see Concerns 6). The same log also showed `WARN quickshell.qmlscanner: Module path ".../config/quickshell" is outside of the config folder`, which led to Concerns 1.
- **GREEN.** `node --test 'tests/*.test.mjs'` → `pass 175 / fail 0`. `tests/smoke.sh tests/smoke/19-lock-preview.sh` → exit 0 with the output quoted above. `tests/smoke.sh tests/smoke/00-start.sh` → exit 0.
- During GREEN I fixed one test bug. In the "set to anything but false" regex, `\s*(?!false)` backtracked, so `= false` counted as a non-false assignment. It is now `=(?!=)(?!\s*false\b)`. I did not change any production code to make that test pass.

## Screenshot — `lock-preview` (shot 2 of 3; 2 taken in total, RED and GREEN)

I read `/tmp/wyspa-shots/lock-preview-full.png`. The cropped `lock-preview.png` does not frame a centred window, because shot.sh crops 800×500 from the top when `$DIR` is down. The preview window opened floating and centred over the terminal.

Checked against §3.10:
- **Card:** a rounded 460×360 glass card with a faint light ring, over the blurred and dimmed sunset wallpaper. The card shadow is barely visible against the dark backdrop.
- **Clock:** "00:53", large, tabular, tight spacing.
- **Date:** "niedziela, 11 października" in the muted lock colour, below the clock.
- **Field:** the password field shows the round accent avatar with "M", the "Hasło" placeholder and the light round → button, with the accent focus outline round it (the field has focus).
- **Status line:** empty, which is correct with no error and nothing busy.
- **Bottom row:** only "🔔 0 powiadomień". Battery and Wi-Fi are hidden because pc has no laptop battery and no NetworkManager.
- **Not in the preview:** the MiniPlayer and the Uśpij/Wyłącz buttons. They exist only on the lock surface; the brief's preview is the card over the blurred wallpaper. They can only be seen at Gate 9.

## Files changed

The commit touches these files:
- **Added:** `config/quickshell/Lock.qml`, `LockPreview.qml`, `states/LockCard.qml`, `lib/lock.js`, `tests/lock.test.mjs`, `tests/smoke/19-lock-preview.sh`
- **Modified:** `IslandState.qml`, `shell.qml`, `lib/theme.js`, `tests/power.test.mjs`, `tests/theme.test.mjs`, `tests/shot.sh`

`allowed-warnings.txt` is unchanged.

## Self-review findings (fixed before commit)

- The log guard forbade the word "message", which would have caught `d.message`. It now forbids `password|pending|typed|pw|.text|pam.`, which is what it meant.
- The `Info` inline component referenced the outer `root` id, which inline components cannot see. I moved it to the root and made it read `Theme.layout.lock` directly.
- Corner buttons: no keyDown path at all, so a letter typed in the field can never start a hold. Key releases do cancel a hold, which is the safe side.

## Concerns

1. **The preview moved from `tests/preview/LockPreview.qml` to `config/quickshell/LockPreview.qml` (a forced deviation from the brief).**
   - The brief says: **Files** "Create … `tests/preview/LockPreview.qml`", and Step 1 `qs -p "$DIR/tests/preview/LockPreview.qml" -d >/dev/null 2>&1`.
   - Why it fails: Quickshell resolves root singletons only inside the folder of the file it runs. With `-p <file>`, that folder is the file's own directory. Evidence from the RED run and a probe:
     - `WARN quickshell.qmlscanner: Module path "…/config/quickshell" is outside of the config folder.`
     - `WARN scene: @_probe.qml[5:-1]: ReferenceError: Theme is not defined`
   - `qs --help` has no option to set the config root.
   - What I did: the preview lives next to `shell.qml` and is launched as `qs -p "$DIR/LockPreview.qml" -d`, and `tests/preview/` was removed. Because it is now root QML, `no-magic.test.mjs` scans it (its size is `geom.lock × 2`) and the lock and power guards scan it too. It mentions only `LockCard`.
   - If you want another place for it, moving it is one line in the check file. Any directory outside the config root cannot load Theme.
2. **`loginctl unlock-session` probably does nothing.** No logind Unlock listener exists in this shell or the old one (see Recovery). Adding one would need a `Process` (D-Bus monitor) in Lock.qml and an allowlist entry in the power guard, which is outside this brief.
3. **Simplifications against §3.10:**
   - No ears or window-layer fade, because a lock surface covers the windows anyway.
   - No extra backdrop blur under the card, because the wallpaper is already blurred.
   - The gloss has the gradient and outline but not the bottom-edge highlight or inner glow from IslandShape.
   - The mini player is the shared `MiniPlayer` sized to 380×56 in `lockGlass` + ring. It keeps its own 40 px cover and its prev button (§3.10 says 36 px cover, no prev).
   - The submit arrow uses `Icon`'s fixed stroke of 1.6 (reference 2).
   - The focus outline is always visible while the field has focus, which on the lock screen is nearly always.
   - The status line has no idle text (the reference leaves it unspecified).
   - The notification count is `Notifs.unread`, matching the rest badge.
4. **PAM `error`, then possibly `completed`, may call `refuse()` twice:** two log lines and a restarted shake. The visible result is the same.
5. **Untested live:** the real lock, PAM, the morph, the idle lock, the corner-button hold and the key-release cancel (does `TextInput` propagate releases?). The morph starts in the surface's `Component.onCompleted`, possibly a frame or two before niri maps it, so the first few ms of the rest→card morph may be clipped. That would not be a bug. By design nothing locked in this run, so all of it is first exercised at Gate 9.
6. **The machine was in use.** The RED shot caught a fullscreen game (No Man's Sky) on the focused monitor. By the GREEN shot the focused monitor showed the terminal. The preview window was up for about 3 s. If you want the preview isolated, a non-shot iteration loop could use `QT_QPA_PLATFORM=offscreen`, which I used for the trap test.
7. Housekeeping for the controller: `/run/user/1000/quickshell/by-id/` holds about 200 dead-instance dirs from this run series (`qs ipc` prints them on a miss). I left them alone.
