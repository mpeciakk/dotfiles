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

// Whether a lock request arriving now only has to cancel the reverse morph: the session is still locked but the
// card is on its way back to rest (a correct password), so the request must not be dropped as "already locked".
// Only an explicit false test mode does it.
function keepsLocked(testMode, locked, unlocking) {
    return testMode === false && locked === true && unlocking === true;
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
