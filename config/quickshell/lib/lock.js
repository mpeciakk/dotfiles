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

// The idle lock: { enabled, timeout } from the host's lock.timeout (seconds). Absent -> the default; a positive
// number -> itself; anything else (0, negative, not a number) -> disabled; test mode -> always disabled.
// IdleMonitor reports idle at once with timeout 0, so the timeout handed to it stays positive even when disabled.
function idle(hostTimeout, defaultTimeout, testMode) {
    var absent = hostTimeout === undefined || hostTimeout === null;
    var valid = typeof hostTimeout === "number" && hostTimeout > 0;
    return {
        enabled: testMode === false && (absent || valid),
        timeout: valid ? hostTimeout : defaultTimeout
    };
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
