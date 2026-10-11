# Task 18 report: Power menu + powerDone

Commit: e251869 `quickshell: power menu with hold-to-confirm` (branch worktree-feat+wyspa-shell)

## What was implemented
- `lib/power.js` (`.pragma library`, no imports): `ITEMS` (5 buttons: id, label, key, hold, danger, done label, icon, command key), `isHold`, `label`, `commandFor(kind, commands)`, `shouldExecute(testMode)` (true only for an explicit `false`: fail-safe), `plan(kind, commands, testMode)` -> `{execute, lock, argv, message}`, `kindForKey`, `step`.
- `states/Power.qml`: 540x180 menu per 3.8. `perform(kind)` is the single gate: `P.plan(...)`, `console.info(message)`, then (only if `plan.execute`) `IslandState.lockRequested()` or `Quickshell.execDetached(argv)`. In test mode `plan` returns `execute:false, lock:false`, so nothing runs. `finish(kind)` -> `request("powerDone")`, sets `IslandState.powerLabel`, then `perform`. Hold: `Timer(holdMs)` is the only thing that confirms a hold; ring = `Shape` arc (`PathAngleArc`) whose progress animates linearly over `holdMs` up and over `holdCancelMs` (ease) back. Pointer: press starts hold (risky), click acts (L/S); release / cancel / exit rewind. Keyboard: Left/Right (clamped), Enter press/release = hold, letters L S O R P = press on that button (hold still required for O/R/P), auto-repeat ignored, Esc not accepted (propagates to the stage). Focus ring (accent@0.9, 1.5, gap 4, r 18) only after keyboard use. Hover = `Theme.hover`; held = `Theme.chip`; rest = `Theme.tile` (no new palette keys: `chip` in subtelne-dark is exactly the reference `#2C2A39`, `tile` the reference `#1C1B26` role).
- `states/PowerDone.qml`: dot + halo + `IslandState.powerLabel` (14/500); "prototyp" marker dropped. Auto-return to `rest` after `powerDoneMs` was already in `IslandState.timeouts` (verified live: returns to rest).
- `IslandState.qml`: `property string powerLabel`, `signal lockRequested` (declared only; NOTHING connected), readonly IPC `powerLabel`.
- `IslandContent.qml`: `sources.power`, `sources.powerDone`.
- `Island.qml`: dim `Rectangle` (`Theme.scrimDim`, opacity 1 only when `effState === "power"`, `Behavior` `dimMs` ease, `visible: opacity > 0`), declared after the catcher MouseArea and before `IslandShape`: a Rectangle takes no input so the click-outside catcher and the 5a z-order are unchanged; the island body paints above it.
- `lib/theme.js`: `power.commands` (exact brief values), `layout.power`, `layout.powerDone`.
- Tests: `tests/power.test.mjs` (pure logic + source guard), `tests/theme.test.mjs` (layout tokens), `tests/smoke/18-power.sh` (verbatim from the brief + a comment).

## Safety evidence
Test-mode guard is the only execution path. Repo-wide grep (`*.qml`, excluding docs/ and tests/) for `execDetached|Process \{|systemctl|loginctl|lock-session|WlSessionLock|quit|lockRequested|ipc call lock`:
```
services/Brightness.qml:20,23   (pre-existing brightness)
services/Niri.qml:40,44,95      (pre-existing niri focus)
IslandState.qml:40,42           comment + `signal lockRequested` (declaration)
states/Power.qml:37             IslandState.lockRequested();   <- inside perform()
states/Power.qml:39             Quickshell.execDetached(p.argv); <- inside perform()
states/Launcher.qml:124,127,133,137,251 (pre-existing; 137 is a comment)
```
No `WlSessionLock`, `loginctl`, `lock-session`, `quit`, `systemctl` literal anywhere in QML (the commands live only in `lib/theme.js`). `grep onLockRequested|lockRequested`: only the declaration and the one call in `perform`. No new IPC function (only the readonly `powerLabel` property). Nothing ever pressed a button; no synthetic input; `perform` never called from IPC.

Guard test (`tests/power.test.mjs`, "guard: ..." tests): scans every `*.qml` under config/quickshell except docs/ and tests/ (comments stripped) and asserts: Power.qml has `perform`; in power files (`*power*` + IslandState.qml) `execDetached`, `Process {`, `systemctl`, `quit`, `loginctl`, `lockRequested(` occur only inside the `perform` body; outside `perform` Power.qml does not mention `tokens.power`/`commands`, has exactly one `execDetached` and no `Process`; no QML spells `systemctl suspend|reboot|poweroff`, `"suspend"|"reboot"|"poweroff"|"quit"` or `action quit`; `.lockRequested(` is called only from states/Power.qml. (I deliberately did NOT assert "no WlSessionLock / nothing connected to lockRequested": Task 19 legitimately adds both and would have to rewrite this test.)

Mutation proof that the guard bites (both reverted before commit): (1) `Component.onCompleted: Quickshell.execDetached(["true"])` in PowerDone.qml -> `FAIL ... 'states/PowerDone.qml: execDetached at 237'`; (2) a `function sneaky()` with `execDetached` + `IslandState.lockRequested()` in Power.qml -> 2 guard tests failed.

## TDD evidence
- RED 1 (logic): `node --test tests/power.test.mjs` before `lib/power.js` existed -> `Error: ENOENT ... lib/power.js`. Then with power.js but no theme defaults -> `TypeError: Cannot read properties of undefined (reading 'commands')` (module-level `T.defaults.power.commands`). Expected: tokens/module missing.
- RED 2 (tokens): `node --test tests/theme.test.mjs` -> `✖ defaults: layout.power and layout.powerDone match reference 3.8 / 3.9 ... "undefined" is not valid JSON`, then GREEN after adding the defaults (23/23).
- RED 3 (guard): with logic + tokens green, `node --test tests/theme.test.mjs tests/power.test.mjs` -> 36 pass, 4 fail, exactly the four guard tests that need `states/Power.qml` ("states/Power.qml exists and has a perform() function", "only inside perform()", "perform() is the only place...", "lockRequested() is called nowhere but perform()").
- RED 4 (visual, brief Step 2): `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh tests/smoke/18-power.sh` before the QML: exit 0 (the island state is already accepted), `power.png` = empty 540x180 glass body, no content, no dim (the failure is visual, not an exit code).
- GREEN: `node --test tests/*.test.mjs` -> `tests 119 / pass 119 / fail 0`; `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh tests/smoke/18-power.sh` -> `ok: island.current = power`, shot, `ok: island.current = rest`, exit 0, no logged warnings; `qs list --all` after each run -> "No running instances."
- `power.png` after: five round 60 px buttons (lock, moon, log-out, rotate-ccw, power), the power icon in danger pink, labels Zablokuj/Uśpij/Wyloguj/Restart/Wyłącz, keys `L`, `S`, `przytrzymaj O/R/P`, header "Zasilanie" + hint "Esc zamyka · strzałki + Enter", no hold ring, and the desktop behind visibly dimmed.
- Optional layout shot of `powerDone` (scratch check in /tmp, not committed) via `island open powerDone`: 340x56, accent dot with halo; the label is empty because `powerLabel` is only set by confirming a button (not testable without a real action). `island current` returned to `rest` by itself after 1800 ms.
- Live shots used: 3 of 3 (power RED, power GREEN, powerDone layout).

## What is NOT tested live (plainly)
There is no pointer injection on `pc`, and pressing a button would act on the live machine, so: the hold ring fill/rewind, release-cancels, hover colour, focus ring, the keyboard flows (Left/Right, Enter hold, letters L/S/O/R/P) and the button -> `finish` -> `perform` path are verified ONLY by code reading and the node tests of the pure logic (`plan`, `commandFor`, `shouldExecute`, `isHold`, `kindForKey`, `step`) plus the source guard. In test mode keyboard focus is None, so keys cannot reach the menu anyway. The Esc / click-outside behaviour is unchanged Island.qml code (the dim is a Rectangle, no MouseArea) and was not click-tested.

## Self-review
- Safety: `finish` only proceeds if `root.active` and `request("powerDone")` accepted; the hold timer is stopped in `onActiveChanged` (Esc / click-outside mid-hold cannot later fire a command) and re-checks `holding !== ""` on trigger; key auto-repeat is ignored for press and release; unknown kind / missing or empty command override / non-`false` test flag execute nothing.
- Keyboard-only starting point: focus starts on Zablokuj (index 0) with the focus ring hidden until the first key, so a bare Enter right after opening acts on Lock (not destructive). Reference 3.8: "letter hotkeys and their hold behaviour unspecified"; R22 defines it, implemented as R22.
- Every changed line traces to the brief. `no-magic` passes (new numbers are only `/ 2`, `2 *`, `0`, `1`).

## Concerns
- `Theme.tile`/`Theme.chip` stand in for the reference `powerBtn`/`powerBtnHeld` (no new palette keys; exact in the subtelne-dark glass level, glass levels are semi-transparent by design). The reference leaves light/glass colours unspecified.
- The lock action in non-test mode only emits `IslandState.lockRequested()`; until Task 19 connects it, Zablokuj does show `powerDone` ("Blokowanie…") but locks nothing. Task 19 must connect the signal and will need to extend (not delete) the guard test in `tests/power.test.mjs` if it adds more callers.
- `powerDone` through IPC `open` shows no label (`powerLabel` empty by design).
- `shot.sh` crops around the island, so the dim over the rest of the screen is judged from the darkened background around the crop only.

## Follow-up fix (advisor review): keyboard hold outliving the key release

Bug: in `Keys.onPressed` the Left/Right branch moved `focused` but left `holding`/`holdTimer` alone, and the Enter release called `release(P.ITEMS[root.focused].id)` with the NEW focus. Sequence: focus Restart, hold Enter, tap Right, release Enter -> `release("off")` is a no-op because `holding === "reboot"`; the timer would keep running and fire the reboot after `holdMs` with nothing pressed.

Fix (states/Power.qml, arrow branch): `root.release(root.holding);` before moving the focus (keyboard analogue of pointer-leave in 4.4; harmless when nothing is held). Keyboard-only path, no pointer/key injection on pc: verified by code reading. Letter path was already safe (a letter press reassigns `focused` and `holding` together; its release cancels); a letter pressed during an Enter hold cancels the hold on Enter release (safe direction).

Re-run: `node --test tests/*.test.mjs` -> tests 119 / pass 119 / fail 0; scratch smoke without a shot (open power / expect power / close / expect rest) -> exit 0, no warnings; `qs list --all` -> No running instances. Shots stay at 3 of 3.

Extra concern: `onExited` also fires on plain hover-out, so a mouse hold that drifts off the button cancels silently (the ring just rewinds): matches reference 4.4 (mouseleave), noted so user gate 8 is not surprised.

## Review fix round 2 (task reviewer, 3 Important): one gate, key-code matching, a tested state machine

Nothing was pressed, triggered or performed; no screenshot, no notify-send. Smoke runs were the non-shot files only (`tests/smoke/18-power.sh` has a `shot` line and was not run).

### Finding 1: the source guard was easy to get around
Change: `perform()` moved out of `states/Power.qml` into the new `components/PowerActions.qml` (an `Item` with `readonly property bool testMode: Quickshell.env("WYSPA_TEST") === "1"` and `perform(kind)` = `P.plan(kind, Theme.tokens.power.commands, root.testMode)`, then `console.info`, return on `!p.execute`, then lock or `execDetached`). `states/Power.qml` instantiates `Components.PowerActions { id: actions }` and calls `actions.perform(kind)`; Task 19's Lock.qml does the same instead of its own exec. Comments in `lib/theme.js` and `lib/power.js` now name the new gate.
Tests (`tests/power.test.mjs`, "Source guard" section, rewritten around `GATE = components/PowerActions.qml`):
- repo-wide scan of every QML (not just `/power/i` files): `execDetached`, `Process {`, `systemctl`, `loginctl`, `quit`, bare `poweroff|reboot|suspend|hibernate|halt`, `tokens.power` / `power.commands` / `commands.<name>`, `lockRequested(` may appear only inside the gate's `perform` span, or in an explicit allowlist (Brightness.qml, Niri.qml, Launcher.qml: only the tokens `execDetached` and `Process`, one comment each; menus/*.sh are not QML). A test pins the allowlist: only those two tokens may ever be listed, and an entry that is no longer true fails (stale list).
- `perform` body: contains `P.plan(kind, Theme.tokens.power.commands, root.testMode)`, then `if (!p.execute) return`, and only after that exactly one `execDetached` and one `lockRequested(`.
- `testMode` is `readonly`, declared once, bound to `Quickshell.env("WYSPA_TEST") === "1"` (either quote style accepted).
- literal test accepts `"`, `'` and backtick; Power.qml must instantiate `PowerActions` and only call `actions.perform(`; `lockRequested()` callers == [gate].
Mutation checks (node only, no QML was loaded; each reverted, `git status` clean afterwards):
- A1: new `components/Stray.qml` with `Quickshell.execDetached(Theme.tokens.power.commands.poweroff)` -> RED: `✖ guard: every process start, power command read and lock request in the tree is ...` with offenders `components/Stray.qml: execDetached`, `power commands (tokens.power)`, `power commands (commands.poweroff)`, `power words (poweroff)`; `ℹ fail 1`. (The old guard stayed green here: the file has no "power" in its name.)
- A2: new Stray.qml with `Process { command: ['poweroff'] }` -> RED: the repo-wide test (`Process`, `power words`) and the literal test (`'poweroff'`); `ℹ fail 2`.
- B: `perform` rewritten as `Quickshell.execDetached(Theme.tokens.power.commands[kind])` -> RED: `✖ guard: perform() decides through P.plan ...` and `✖ guard: lockRequested() is called nowhere but the gate`; `ℹ fail 2`.
- B2: `P.plan(..., false)` instead of `root.testMode` -> RED: `✖ guard: perform() decides through P.plan ...`; `ℹ fail 1`.
- B3: `testMode` bound to `Quickshell.env("WYSPA_TEST") !== "0"` -> RED: `✖ guard: the gate's testMode is read-only and bound to WYSPA_TEST === 1 ...`; `ℹ fail 1`.
Grep proof after the change (`grep -rnE "tokens\.power|power\.commands|lockRequested\(" --include=*.qml`): only `components/PowerActions.qml:17` (`P.plan(kind, Theme.tokens.power.commands, root.testMode)`) and `:22` (`IslandState.lockRequested()`) outside a comment; `execDetached` with the power commands: `components/PowerActions.qml:24` only (the others are Brightness.qml, Launcher.qml x3, Niri.qml x2: brightnessctl, wl-copy / typed launcher commands, niri focus).

### Finding 2: a modifier during the hold defeated hold-to-confirm
Change: `Keys.onPressed/onReleased` now send `event.key` (a Qt key code) to the reducer; `event.text` is no longer used anywhere. The hold records which key started it (`source: "key:enter"` or `"key:<code>"`) and only that key's release cancels it; `onActiveFocusChanged` dispatches `focusLost`, which cancels a running hold. `P.kindForKey(text)` was orphaned by this and removed together with its test.
Tests: "reduce: a letter up with a modifier in between still cancels (matched by key code, not text)" (P down, Control down, P up (same code) -> cancel, a later timer tick -> nothing), "Ctrl/Alt/Meta + letter or Enter is a chord, not a press" (keeps the old behaviour: Ctrl+P starts no hold), "losing the keyboard focus mid-hold cancels it".

### Finding 3: the hold / keyboard state machine had no test
Change: the transitions are lifted into `lib/power.js` as `initial()` and a pure `reduce(state, event) -> { state, effect: {type: none|start|cancel|finish, kind}, handled }`; state `{holding, source, focused, keyboard}`; events `keyDown{code,repeat,chord}`, `keyUp{code,repeat}`, `pointerPress/pointerRelease/pointerClick{kind}`, `focusLost`, `active{on}`, `timerElapsed`; `KEYS` holds the Qt codes as plain numbers (node needs no Qt). `states/Power.qml` has one `dispatch(ev)` that calls `P.reduce`, stores the state and applies the effect (`start` -> `holdTimer.restart()`, `cancel` -> `stop()`, `finish` -> `finish(kind)`). Kept: `finish` re-checks `root.active` and `request("powerDone")`; `onActiveChanged` stops the timer (the `active` event always answers `cancel`); only `testMode === false` executes (plan unchanged). Rules: auto-repeat is ignored; a second press while a hold runs (key or pointer) is ignored; a pointer release/exit does not end a key-started hold and a key release does not end a pointer-started hold; arrow, focus loss, layer inactive or the starting key's release end it; `timerElapsed` finishes only a hold that is still on.
RED (stub reducer, `node --test 'tests/*.test.mjs'`, saved at /tmp/wyspa-red.txt): `ℹ tests 141 / pass 121 / fail 20` (the new reduce tests failing on the stub: arrows, Enter/letter start and cancel, key map, active, focus, timer, pointer/key mix, auto-repeat, ...).
GREEN after implementing: `ℹ tests 141 / pass 141 / fail 0`.
Sequences covered: Enter -> Right -> Enter up (cancel, no later finish, focus moved), letter during an Enter hold (ignored; the Enter hold finishes Wyloguj, never Wyłącz; Enter up cancels), letter up with a modifier, mouse press + Enter on the same button (Enter neither restarts nor cancels; the pointer release cancels), pointer release vs key hold, `active` false mid-hold (cancel + state reset), `focusLost`, stray `timerElapsed` after cancel / after finish, auto-repeat down and up, unrelated key up, chords, state not mutated.
Behaviour change to flag: a letter pressed during an Enter hold used to take the hold over (and the Enter release cancelled it); it is now ignored, so the hold stays with the key that started it.

### Final evidence
- `node --test 'tests/*.test.mjs'` -> `ℹ tests 143 / pass 143 / fail 0` (119 before; +22 reduce tests, guard section 5 -> 8 tests, -1 `kindForKey`).
- Smoke, each followed by `sleep 2; qs list --all` -> "No running instances.": `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh tests/smoke/00-start.sh` exit 0 (no logged warnings; IslandContent mounts every layer through a Loader at start, so Power.qml and PowerActions.qml loaded cleanly); `04-state.sh` exit 0 (17 `ok:` lines); `06-content.sh` exit 0 (4 `ok:`). None of them opens the power layer, and it was not opened by hand.
- Not testable here, by design: the QML wiring `dispatch` <-> Keys/MouseArea/Timer (no key or pointer injection; a press could act on the live machine). It is thin (builds an event, applies the effect); the decisions it forwards are covered by the reducer tests.

### Concerns (not on the list, not changed)
- The launcher can run any typed command (`sh -c row.text`), including `systemctl poweroff`, by design; the guard allowlists it as "not the power menu".
- Launcher.qml and Niri.qml use their own test-mode handling (Launcher's `perform`; Niri's focus calls are unconditional); out of scope.

Commit d70e4e5. Output check: `node --test 'tests/*.test.mjs' 2>&1 | grep -vE '^(ok|✔|ℹ|#|  )'` prints nothing (pristine). Committed gate is unmutated: `git show HEAD:config/quickshell/components/PowerActions.qml | grep -nE 'testMode|P\.plan'` -> line 14 `readonly property bool testMode: Quickshell.env("WYSPA_TEST") === "1"`, line 17 `P.plan(kind, Theme.tokens.power.commands, root.testMode)`.
Extra concern: the `KEYS` test compares the map with its own literals, so a wrong Qt key code cannot be caught from node; the failure mode is a dead key (safe), not a misfire.
For the controller to adjudicate: letter-during-Enter-hold is now ignored (before: the letter took the hold over).

## Fix round 2 (second review, Important: AltGr during a key hold)

**Finding:** matching the keyUp by key code misses AltGr: on `pl`, P down -> AltGr down -> P up reaches `reduce` as `keyUp` code 0xde (THORN), `none`, and `timerElapsed` then finishes `off` after the key is released.

**Change (`config/quickshell/lib/power.js`, `keyUp` branch):** any non-repeat `keyUp` while a hold runs now cancels it (`!ev.repeat && !idle`); the `state.source === sourceOfKey(code)` match is gone. `Power.qml` is unchanged (it still passes `event.key`; the code is no longer used for matching). Decisions:
- Option (a) as instructed; (b) not attempted.
- Modifier key DOWN during a hold starts nothing and cancels nothing (pinned); only a key UP cancels.
- Enter hold + Shift (or any chord) pressed and released meanwhile now cancels: pinned.
- Unknown / 0 / modifier key-up codes cancel: pinned (loop over 8 codes).
- Pointer holds: chose the fail-safe direction, a stray key release (e.g. the modifier of the keybind that opened the menu) cancels a pointer hold too. Cost is a re-press; pinned in "a key release during a pointer hold cancels it too". Note this contradicts the "keep mouse holds unaffected" half of the dispatch; I followed the explicit "pick the fail-safe" half. One-line revert if the controller disagrees: `&& (state.source === "pointer" ? false : true)` style guard in that branch.
- `source` is now only read to tell a pointer hold from a key hold (`pointerRelease`); the `key:<code>` suffix is no longer compared anywhere. Left as is (not on the list).

**Tests (`tests/power.test.mjs`):** rewritten: "a letter during an Enter hold" (letter up no longer asserted as ignored), "mouse press then Enter" (Enter up now cancels), "keys that are no button" (the "unrelated key up does not cancel" assertion removed). Added: modifier press during a hold is inert; P/AltGr/THORN-up; O (0xd3) and R (0xa9) variants; any key release incl. modifiers / unknown / 0 cancels; Enter hold + Shift chord cancels; key release cancels a pointer hold; key release with no hold is a no-op and unhandled.

**RED (before the fix, `node --test 'tests/*.test.mjs'`):** `ℹ tests 151 / pass 145 / fail 6`; failing: P-down/AltGr/THORN-up, O and R variants, any-key-release-cancels, Enter-hold + Shift chord, key release during pointer hold, mouse+Enter-up.
Reducer one-liner (`down(0x50), down(AltGr 0x01001103), up(0xde), timerElapsed`, script /tmp/oneliner.mjs):
- before: `start off, none , none , finish off`
- after:  `start off, none , cancel off, none`

**GREEN:** `node --test 'tests/*.test.mjs'` -> `ℹ tests 151 / pass 151 / fail 0`.

**Callers pin (Minor 1):** new test "guard: the only QML that mentions PowerActions ... is states/Power.qml" asserts the files (outside the gate) mentioning `PowerActions` are exactly `["states/Power.qml"]`; a comment says Task 19 adds `states/Lock.qml`. (Mention, not only `.perform(`, because `root.perform(` exists in four unrelated files; anything that instantiates or types a `PowerActions` is caught.) Mutation: `states/Stray.qml` with `Components.PowerActions { id: sneaky }` + `sneaky.perform("off")` -> `✖ guard: the only QML that mentions PowerActions ...` with `+ 'states/Stray.qml'`, `ℹ pass 49 / fail 1` for power.test.mjs; file removed, full suite back to 151/151, `git status` clean of it.

**Smoke (non-shot only, each then `sleep 2; qs list --all` -> "No running instances."):** `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh tests/smoke/00-start.sh` exit 0; `04-state.sh` ok lines through `island.hidden = false`. `18-power.sh` not run (has `shot`). No live screenshots, nothing pressed or performed.

**Residual concern:** Qt's behaviour (release delivered with a modified keysym) is ~80% inference; the fix does not depend on it being true, it only makes the cancel unconditional. If the Qt release for the held key were NOT delivered at all (focus loss aside), the hold would still run to finish; that is the pre-existing Keys design, covered by `focusLost` / `active`.
