.pragma library

// The decisions of the session lock, kept apart from QML so node can test them. Nothing here locks anything:
// engage() only says whether Lock.qml engageLock() may set WlSessionLock.locked, and that is the one place
// that does it. tests/lock.test.mjs pins both.

// Whether to lock now: { engage, message }. Only an explicit false test mode locks (an unset or odd value
// fails safe), and never twice.
function engage(testMode, locked) {
    if (testMode === true)
        return { engage: false, message: "lock (test mode): would lock the session" };
    if (testMode !== false)
        return { engage: false, message: "lock: test mode unknown, not locking" };
    if (locked)
        return { engage: false, message: "lock: already locked" };
    return { engage: true, message: "lock: locking the session" };
}

// Whether a lock request arriving now only has to cancel the unlock: the password was accepted but the lock is still
// on (Lock.qml releaseTimer, handoffMs), so the request must not be dropped as "already locked".
// Only an explicit false test mode does it.
function keepsLocked(testMode, locked, unlocking) {
    return testMode === false && locked === true && unlocking === true;
}

// The next step of an allowed lock request (DESIGN W12, W14): "prelude" = play the way in on the overlay first, "wait" =
// it is playing (the lock follows when it ends), "lock" = lock now (it ended, or reduced motion: no way in), "snap" =
// a sleep request: the way in at zero durations on a fresh overlay, and the lock after every window has presented a
// frame of its end look (never waited out: logind gives the shell 5 s). A snap already running (instant) is waited for.
// prelude: 0 none, 1 playing, 2 ended.
function lockStep(prelude, reducedMotion, sleep, instant) {
    if (sleep === true) {
        if (prelude === 2)
            return "lock";
        return prelude === 1 && instant === true ? "wait" : "snap";
    }
    if (prelude === 1)
        return "wait";
    if (prelude === 0 && !reducedMotion)
        return "prelude";
    return "lock";
}

// A line of `gdbus monitor --system --dest org.freedesktop.login1 --object-path /org/freedesktop/login1`:
// "<path>: org.freedesktop.login1.Manager.PrepareForSleep (true,)" -> "start", "(false,)" -> "resume", else "other".
function sleepSignal(line) {
    if (typeof line !== "string")
        return "other";
    var m = /\borg\.freedesktop\.login1\.Manager\.PrepareForSleep \((true|false),\)\s*$/.exec(line);
    return m ? (m[1] === "true" ? "start" : "resume") : "other";
}

// Whether the shell watches logind for a sleep and holds the delay inhibitor at all: only an explicit false test mode.
function sleepWatched(testMode) {
    return testMode === false;
}

// Whether the sleep delay inhibitor is held now (DESIGN W14): always, except while a sleep is pending and the session
// lock is secure (logind may suspend then). Released stays released until the wake: the restart of an exited
// inhibitor asks this again.
function inhibitorWanted(testMode, sleepPending, lockSecure) {
    return testMode === false && !(sleepPending === true && lockSecure === true);
}

// Whether every output in `outputs` (names) has presented a frame of the overlay's end look (`presented`: name -> true).
function framesPresented(outputs, presented) {
    for (var i = 0; i < outputs.length; i++)
        if (presented[outputs[i]] !== true)
            return false;
    return true;
}

// How long the way in plays: until the last of the morph, the wallpaper, the card's content and the extras is in.
function lockInMs(motion, spec) {
    return Math.max(motion.lockMorphMs, motion.wallpaperMs, spec.deskMs,
        spec.enterDelayMs + spec.enterOpacityMs, spec.enterDelayMs - spec.enterScaleLeadMs + spec.enterScaleMs,
        spec.enterDelayMs + spec.enterBlurMs, spec.extrasDelayMs + spec.extrasMs);
}

// How far the card is docked into the screen's top edge, from the lock morph (1 = the card in the middle, 0 = the
// rest island): { top, ear }, each 0..1. Above dockAt the card has rounded top corners (top), below it the island's
// ears instead (ear); never both, so the outline is either a floating card or the island, and the change is
// continuous (both are 0 at dockAt).
function dock(morph, dockAt) {
    return {
        top: morph > dockAt ? (morph - dockAt) / (1 - dockAt) : 0,
        ear: morph < dockAt ? 1 - morph / dockAt : 0
    };
}

// The idle lock: { enabled, timeout } from the host's lock.timeout (seconds). Absent -> the default; a positive
// number -> itself; anything else (0, negative, not a number) -> disabled; a timeout that is still not positive
// (a default of 0) -> disabled too; test mode -> always disabled.
// IdleMonitor reports idle at once with timeout 0, so the timeout handed to it stays positive even when disabled.
function idle(hostTimeout, defaultTimeout, testMode) {
    var absent = hostTimeout === undefined || hostTimeout === null;
    var valid = typeof hostTimeout === "number" && hostTimeout > 0;
    var timeout = valid ? hostTimeout : defaultTimeout;
    var usable = typeof timeout === "number" && timeout > 0;
    return {
        enabled: testMode === false && (absent || valid) && usable,
        timeout: usable ? timeout : 1
    };
}

// The error ring and the status line: shown after a refused attempt until the first character is typed, and
// not again when the field is emptied (reference 4.5: typing clears err).
function errorShown(failed, typedSinceFailure) {
    return failed && !typedSinceFailure;
}

// The status line after a refused attempt when PAM said nothing (DESIGN W16).
var REFUSED_TEXT = "Niepoprawne hasło — spróbuj ponownie";

// One PamContext message of the running attempt: kept when it is text for the user (not the password prompt, not
// blank); returns a new list. PAM sends them before the prompt and `message` is "" again at completed().
function collectMessage(messages, message, responseRequired) {
    var list = messages ? messages.slice() : [];
    if (responseRequired !== true && typeof message === "string" && message.trim() !== "")
        list.push(message.trim());
    return list;
}

// The status line of a refused attempt: PAM's own messages joined by a space (pam_faillock: the account is locked,
// minutes left), or the fixed text when there were none.
function refusalText(messages) {
    var text = (messages || []).join(" ").trim();
    return text === "" ? REFUSED_TEXT : text;
}

// "2 powiadomienia": the bottom row shows only the count (DESIGN §6).
function notifCount(n) {
    var tens = n % 100;
    var units = n % 10;
    var word = n === 1 ? "powiadomienie"
        : units >= 2 && units <= 4 && (tens < 12 || tens > 14) ? "powiadomienia"
        : "powiadomień";
    return n + " " + word;
}

// The avatar's letter: the configured name's, else the user's.
function initial(name, user) {
    return (name || user || "?").charAt(0).toUpperCase();
}
