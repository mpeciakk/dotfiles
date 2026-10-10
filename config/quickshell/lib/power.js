.pragma library

// The decisions of the power menu, kept apart from QML so node can test them. Nothing here runs anything:
// plan() only says what states/Power.qml perform() should do, and that is the one place that does it.

// `command` is the key in Theme.tokens.power.commands; the lock has none (it asks the session lock instead).
// `danger` paints the button and its ring in the danger colour.
var ITEMS = [
    { id: "lock", label: "Zablokuj", key: "L", hold: false, danger: false, done: "Blokowanie…", icon: "lock", command: "" },
    { id: "sleep", label: "Uśpij", key: "S", hold: false, danger: false, done: "Usypianie…", icon: "moon", command: "suspend" },
    { id: "logout", label: "Wyloguj", key: "O", hold: true, danger: false, done: "Wylogowywanie…", icon: "log-out", command: "logout" },
    { id: "reboot", label: "Restart", key: "R", hold: true, danger: false, done: "Ponowne uruchamianie…", icon: "rotate-ccw", command: "reboot" },
    { id: "off", label: "Wyłącz", key: "P", hold: true, danger: true, done: "Wyłączanie…", icon: "power", command: "poweroff" }
];

function item(kind) {
    for (var i = 0; i < ITEMS.length; i++)
        if (ITEMS[i].id === kind)
            return ITEMS[i];
    return null;
}

function isHold(kind) {
    var it = item(kind);
    return it !== null && it.hold;
}

// The label powerDone shows.
function label(kind) {
    var it = item(kind);
    return it === null ? "" : it.done;
}

// The argv `commands` (Theme.tokens.power.commands) holds for `kind`; null for the lock, an unknown
// button or a missing / empty override.
function commandFor(kind, commands) {
    var it = item(kind);
    if (it === null || it.command === "" || !commands)
        return null;
    var argv = commands[it.command];
    return Array.isArray(argv) && argv.length > 0 ? argv.slice() : null;
}

// Only an explicit false runs anything: an unset or odd test-mode value fails safe.
function shouldExecute(testMode) {
    return testMode === false;
}

// What perform() does for `kind`: { execute, lock, argv, message }. In test mode nothing is executed and
// the lock is not requested; the message says what would have happened.
function plan(kind, commands, testMode) {
    var it = item(kind);
    var argv = commandFor(kind, commands);
    var wouldLock = it !== null && it.command === "";
    var wouldDo = wouldLock ? "request the session lock" : argv === null ? "" : "run: " + argv.join(" ");
    if (testMode === true)
        return { execute: false, lock: false, argv: null, message: "power (test mode): would " + (wouldDo === "" ? "do nothing for " + kind : wouldDo) };
    if (!shouldExecute(testMode) || wouldDo === "")
        return { execute: false, lock: false, argv: null, message: "power: nothing to do for " + kind };
    return {
        execute: true,
        lock: wouldLock,
        argv: wouldLock ? null : argv,
        message: wouldLock ? "power: requesting the session lock" : "power: running " + argv.join(" ")
    };
}

// The button a typed letter stands for (R22), "" for none.
function kindForKey(text) {
    var up = String(text).toUpperCase();
    for (var i = 0; i < ITEMS.length; i++)
        if (ITEMS[i].key === up)
            return ITEMS[i].id;
    return "";
}

// The focus after an arrow press: it stops at both ends.
function step(index, delta, count) {
    return Math.max(0, Math.min(count - 1, index + delta));
}
