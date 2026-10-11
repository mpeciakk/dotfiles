# Wyspa review fixes (lock, notifications, GPU memory) — plan

## Goal
Fix the four groups of findings from the 2026-10-11 review of `config/quickshell`: the session locks before every
suspend and swallows input during the way in, the lock card says why a correct password is refused under faillock,
replaced / closed / transient notifications behave per the protocol, and the shell's GPU memory drops where a measurement shows it (`nvidia-smi` on `pc`: 1036 MiB at
21:00 after several lock cycles, 410 MiB at 22:11 — the peak, not the steady state, is the target). Spec: `config/quickshell/docs/DESIGN.md` (W12 amended, W14–W16 added).

## Decisions
- D1 Lock before sleep: the shell watches `org.freedesktop.login1.Manager.PrepareForSleep` on the system bus
  (`gdbus monitor --system`, restarted if it exits); the monitor only sets `sleepPending` (true on `(true,)`, false on
  `(false,)`). A logind sleep **delay** inhibitor (`systemd-inhibit --what=sleep --mode=delay --who=wyspa`) runs
  exactly while `!testMode && !(sleepPending && lockSecure)` — one binding, restarted on exit only while it holds, so a
  release is never undone during a pending sleep. `sleepPending` true → `engageLock("sleep")` with the way in played
  at zero durations (the reduced-motion path), and the lock goes on only after every island window has presented
  one frame of the overlay's end look (`frameSwapped`, capped well under logind's 5 s `InhibitDelayMaxSec`), so the
  frame niri shows at the unlock after the wake is the lock's look and the way back plays as in W12. Already locked →
  the condition releases at once. A refused lock has no event: logind's 5 s cap is the fallback. Always on, no config
  key. Test mode: neither process starts, decided in one place and pinned by a source-grep test. Rejected: locking only in the
  power menu's Uśpij (misses the lid and `systemctl suspend`); swayidle/hypridle `before-sleep` → `island lock` (a second
  daemon, and the IPC lock plays the 0.8 s way in); also handling logind `Lock` (`loginctl lock-session`) — not asked.
- D2 Way-in input (amends W12, user decision 2026-10-11): an allowed lock request first closes the island
  (`IslandState.close()`), so no modal state (launcher field, power-menu keys) gets the typed password; during
  `lockPhase === "in"` the island window of the focused output (`Niri.focusedOutput`) takes
  `WlrKeyboardFocus.Exclusive` with no item holding focus, and every island window takes the full input mask; keys
  typed then are dropped, clicks do not reach windows. Test mode keeps keyboard focus None (existing rule).
  Rejected: hiding the password field until locked (the leak is the keys); feeding the dropped keys into the field.
- D3 Faillock (user decision: shared tally stays): the card's status line shows the PAM messages of the refused
  attempt (non-prompt messages, e.g. pam_faillock's "account locked … minutes left", in whatever language PAM sends)
  instead of the fixed "Niepoprawne hasło — spróbuj ponownie", joined by a space on the existing one-line status
  (elided, not wrapped; the overlay's card is unaffected); no message → the fixed text. One refusal per attempt
  (PamContext emits `error` and then `completed(Error)`; today `refuse()` runs twice). `assets/pam.d/passwd` unchanged.
- D4 Notifications (user decisions): every non-transient notification is `tracked` while its card is in `history`.
  A replacement (Quickshell v0.3.2 `server.cpp` `Notify`: a tracked `replaces_id` updates the same object in place and
  emits **no** new `notification`) updates the snapshot and moves the card to the top: no `arrived`, `series` and
  `unread` unchanged; a toast on screen shows the newest card as it always does. A close by the app (`closed` with
  `NotificationCloseReason.CloseRequested`) removes the card without calling `dismiss()` back on that object. A card
  the user or the cap removes (dismiss, dismissApp, clear, the cap of 50) calls `dismiss()` on its tracked object. `transient` → toast only: not in `history`, not in `unread`; so
  the toast's `latest` no longer comes from `history[0]`. `unread` never exceeds `history.length`.
  Rejected: a new toast per replacement (progress would flash every second).
- D5 GPU memory is measured, not guessed: first find what drives the peak (plain `nvidia-smi` table, type `G` row —
  `--query-compute-apps` does not list the shell); a change ships only if it measurably cuts GPU memory or RSS and
  screenshots show no visual change. Lock paths (`LockOverlay`, lock surface) never mount in test mode: their
  candidates are measured on the live shell at the finish stage, before/after a lock. Candidates: wallpaper `sourceSize` from the output's
  real (fractional) scale — never above its physical pixels (`Wallpaper.qml`, `LockOverlay.qml`, `Lock.qml`);
  `IslandContent` hidden layers' `layer.enabled` also gated on `opacity > 0`; `Center` model gated on `active`, card
  `Image` without `cache: false` and asynchronous. Rejected: unmounting hidden layers (IslandContent keeps them
  mounted so nothing reflows during a morph).

## Constraints
- Every rule in `config/quickshell/CLAUDE.md` "Conventions": theme-only literals (`tests/no-magic.test.mjs`), `lib/*.js`
  pure `.pragma library`, icons only through `components/Icon.qml`, test mode decided in ONE place per side effect and
  pinned by source-grep tests — never weaken `tests/power.test.mjs` / `tests/lock.test.mjs`.
- Never call `island lock` from a test or a smoke; never lock the live session. Smokes run as
  `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh tests/smoke/<x>.sh`; a new WARN/ERROR fails them.
- Never a bare `qs kill`; never `dotter deploy` or restart `quickshell.service` from a task (the finish stage does it).
- `WlSessionLock.locked` does not notify an unlock in 0.3.2: bindings use `Lock.qml` `lockOn`.
- Guard tests protect behaviour, not regex text: a task that changes a pinned call (e.g. `L.lockStep(...)`) updates the
  guard to the new signature with the same intent, and adds new lock sources to the "every request goes through
  `engageLock()`" guard. Weakening means removing an intent, not editing a pattern.

## Verification
1. `node --test 'tests/*.test.mjs'` green; every `tests/smoke/*.sh` green.
2. On the live shell after `dotter deploy` + `systemctl --user restart quickshell` (finish stage, one notification
   daemon per session, so not on a test instance):
   - `id=$(notify-send -p a)`, then `notify-send -r $id b` → one card reading "b", unread +1 total.
   - `notify-send -e t` (transient) → toast, centre count unchanged.
   - `gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications
     --method org.freedesktop.Notifications.CloseNotification $id` → the card is gone.
   - `systemd-inhibit --list` shows the `wyspa` sleep delay inhibitor while unlocked.
3. By the user on `pc`: Mod+L, then type at once into a focused terminal → nothing arrives (also with the launcher
   open before Mod+L); Uśpij from the power menu, wake → the lock card is up, unlock → the way back plays with no flash
   of the windows; `journalctl -b -u systemd-logind` has no "inhibitor timeout is reached" and the shell log shows lock
   → secure → release before logind's "Suspending". Faillock: as T2's probe found (expected: three wrong, then the
   correct one shows the message); this also locks sudo/TTY for 600 s — clean up with `faillock --user m --reset`.
   The lid path is only checkable on `laptop`: unverified until done there.
4. GPU: plain `nvidia-smi` numbers before/after in the T4 report; lock-path candidates on the live shell at finish.

## Task 1: Lock before sleep and the way-in input grab
**Outcome:** a suspend from any source finds the session locked (D1); during the way in no key or click reaches a
window (D2). W12/W14 behaviour as in Decisions.
**Acceptance:** node tests on the pure parts in `lib/lock.js`: parsing a `gdbus monitor` line into sleep start / resume
/ other; the inhibitor condition; the lock step for a sleep request in every prelude state (0, 1 playing, 2) and when
already locked; a sleep request during the way in jumps to the end look instead of waiting the full way in.
Source-grep tests: test mode starts neither process; `engageLock()` stays the one place that sets `locked` and the
"sleep" source goes through it; a lock request closes the island; `Island.qml` keyboard focus goes Exclusive in phase
`in` only outside test mode, with `stage.focus` off. Smokes stay green.
**Area:** `Lock.qml`, `lib/lock.js`, `Island.qml` (keyboard focus, mask mode), `IslandState.qml` if the mask mode needs
the phase, `tests/lock.test.mjs`, `tests/smoke/allowed-warnings.txt` only if a new warning is unavoidable and explained.
**Context:** `Lock.qml` `engageLock()` / `L.lockStep()` / `preludeTimer`; `Island.qml` `WlrLayershell.keyboardFocus`,
`maskMode`. Before coding, check the real `gdbus monitor` line format: watch the session object
(`gdbus monitor --system --dest org.freedesktop.login1 --object-path /org/freedesktop/login1/session/<id>`) and run
`loginctl lock-session` (harmless: nothing listens for `Lock`); the manager's `PrepareForSleep` prints in the same
shape with `(true,)` / `(false,)`. A delay inhibitor as user `m` works on `pc` (probed: `systemd-inhibit --list` showed
it, `InhibitDelayMaxUSec` 5000000).

## Task 2: Faillock message on the lock card
**Outcome:** a refused attempt shows PAM's own messages when PAM sent any (D3); one refusal per attempt.
**Acceptance:** first a real probe, not a guess: a throwaway `qs` script outside the repo with a `PamContext` on a
temporary PAM stack (`pam_faillock.so preauth dir=<tmp> deny=1`, `pam_deny.so`, `pam_faillock.so authfail dir=<tmp>
deny=1`) — record in the report what messages arrive on the second attempt (`message`, `messageIsError`, order).
Then node tests on the pure part (`lib/lock.js`: messages of an attempt → the status text; none → the fixed text)
and a test that one failed attempt calls `refuse()` once. `19-lock-preview.sh` green. The probe also says on which
attempt the message appears (preauth → the attempt after the lockout); Verification 3 follows it.
**Area:** `Lock.qml` (PamContext handlers), `states/LockCard.qml` (status line), `lib/lock.js`, `tests/lock.test.mjs`.
**Context:** `Lock.qml` `PamContext` (`onResponseRequiredChanged`, `onCompleted`, `onError`), `refuse()`;
`LockCard.qml` status line and `L.errorShown()`. Builds on Task 1's `Lock.qml`.

## Task 3: Notifications — replace, close, transient, unread cap
**Outcome:** D4 end to end in `services/Notifs.qml`.
**Acceptance:** node tests on pure helpers in `lib/notifs.js` for: replacing a snapshot by id (moved to top, others
kept in order); removal by id; unread after push / replace / removal never above history length; the cap of 50 naming
the ids that fell out (so their objects get `dismiss()`). IPC `inject` keeps working (negative ids, no object).
`08-notifs.sh`, `11-series.sh`, `11-toast.sh`, `12-center.sh` green. The D-Bus path is proven before deploy: a smoke
whose test instance runs on a private session bus (`dbus-run-session`, so it owns `org.freedesktop.Notifications`)
drives `notify-send -p` / `-r` / `-e` and `CloseNotification` and checks `count`, `unread`, `series` and the top card.
A transient IPC path, if needed, is a separate typed `injectTransient`, so the 3-argument `inject` calls stay valid.
Update the docs this makes false: `CLAUDE.md` gotcha 6 ("not tracked") and the header comment of `services/Notifs.qml`.
**Area:** `services/Notifs.qml`, `lib/notifs.js`, `states/Toast.qml` (source of `latest`), `tests/notifs*.test.mjs`,
`tests/smoke/` notification smokes, `tests/smoke.sh` only if the private bus needs a hook there, `CLAUDE.md` gotcha 6.
**Context:** Quickshell v0.3.2 `NotificationServer` / `Notification` (`tracked`, `transient`, `closed(reason)`,
`dismiss()`, property change signals on replace); CLAUDE.md gotcha 6 (image URLs die with the object — keep the
snapshot policy `storedSource()`).

## Task 4: GPU memory, measured
**Outcome:** the D5 candidates that measurably cut GPU memory or RSS are in; the others are reported with their
numbers and left out.
**Acceptance:** first, what drives the peak: the live shell's plain `nvidia-smi` MiB at rest, after opening each state,
and (read-only, the user locks) after a lock cycle — then pick candidates. The report has a table: change → plain
`nvidia-smi` MiB and RSS of a test instance from the worktree (`qs -p <worktree>/config/quickshell -d` with `WYSPA_TEST=1`, killed by
`qs kill -p`), baseline first, each after the same warm-up (open `center`, `launcher`, `control`, `media` once via IPC).
Screenshots (`tests/shot.sh`) before/after for rest and center look the same (the lock preview does not exercise the
lock wallpaper: lock candidates are checked live at finish). Smokes green.
**Area:** `Wallpaper.qml`, `LockOverlay.qml`, `Lock.qml` (wallpaper `Image` only), `IslandContent.qml`,
`states/Center.qml`.
**Context:** the review measured `screen.devicePixelRatio` = 2 on DP-2 (real scale 1.5, `wp2.jpg` 3840×2160) — check it
before relying on it, and whether Qt 6.12 multiplies `sourceSize` by the window's DPR (read the decoded size back);
LockOverlay's comment relies on the pixmap cache sharing the decode with `Wallpaper.qml` (same
url and `sourceSize`), keep the three in step.

## Rulings
- Task 1: IslandState.request() refuses every state during lockPhase "in" (closing still passes) — the implementer found a modal state (Mod+Space) opened during the way in would still take keys; D2 says no modal state gets the password — cost if wrong: a toast/OSD arriving in those ~0.8 s is not shown (history and unread still count it).
- All tasks: no smoke runs during tasks (user request 2026-10-11: the test instances draw on the real screens); node tests only, each report lists the smokes to re-run; one batch at the end with the user's ok.
