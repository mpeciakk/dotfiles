.pragma library

// The decisions of the power menu, kept apart from QML so node can test them. Nothing here runs anything:
// plan() only says what components/PowerActions.qml perform() should do, and that is the one place that does it.

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

// The focus after an arrow press: it stops at both ends.
function step(index, delta, count) {
    return Math.max(0, Math.min(count - 1, index + delta));
}

// ---- The hold / keyboard state machine --------------------------------------------------------------
// states/Power.qml owns no decision of its own: it turns every key, pointer, focus, layer and timer event
// into one of the events below and acts on the effect reduce() answers. Nothing here runs a command; a
// `finish` effect only says "this button is confirmed", and the QML then goes through perform().
//
// state:  { holding, source, focused, keyboard }
//   holding   the button whose hold is running ("" = none)
//   source    what started that hold: "pointer", or "key:<enter | key code>"; "" with no hold
//   focused   the button the keyboard is on; keyboard: whether its focus ring shows
// events: { type: "keyDown", code, repeat, chord }   a key went down (chord: Ctrl/Alt/Meta held)
//         { type: "keyUp", code, repeat }
//         { type: "pointerPress", kind } / { type: "pointerRelease", kind } (release, exit, cancelled grab)
//         { type: "pointerClick", kind }              a click: the buttons that need no hold act on it
//         { type: "focusLost" }, { type: "active", on }, { type: "timerElapsed" }
// result: { state, effect: { type: "none" | "start" | "cancel" | "finish", kind }, handled }
//   handled: a keyDown the menu used (the QML accepts the event); anything else is left to its parent.
// Keys are matched by key code (the Qt.Key_* number), never by the typed text: a modifier changes the text.

var KEYS = { left: 0x01000012, right: 0x01000014, return: 0x01000004, enter: 0x01000005, l: 0x4c, s: 0x53, o: 0x4f, r: 0x52, p: 0x50 };

function initial() {
    return { holding: "", source: "", focused: 0, keyboard: false };
}

function isEnter(code) {
    return code === KEYS.return || code === KEYS.enter;
}

// The button a key code stands for (R22), "" for none.
function kindForCode(code) {
    for (var i = 0; i < ITEMS.length; i++)
        if (KEYS[ITEMS[i].key.toLowerCase()] === code)
            return ITEMS[i].id;
    return "";
}

function indexOf(kind) {
    for (var i = 0; i < ITEMS.length; i++)
        if (ITEMS[i].id === kind)
            return i;
    return -1;
}

function sourceOfKey(code) {
    return isEnter(code) ? "key:enter" : "key:" + code;
}

function patch(state, changes) {
    var out = {};
    for (var k in state)
        out[k] = state[k];
    for (var c in changes)
        out[c] = changes[c];
    return out;
}

function answer(state, type, kind, handled) {
    return { state: state, effect: { type: type, kind: kind }, handled: handled };
}

// A press of `kind` from `source`: the risky buttons start their hold, the others confirm at once.
function press(state, kind, source) {
    if (isHold(kind))
        return answer(patch(state, { holding: kind, source: source }), "start", kind, true);
    return answer(state, "finish", kind, true);
}

function stopHold(state, changes) {
    return answer(patch(state, patch(changes, { holding: "", source: "" })), "cancel", state.holding, true);
}

function reduce(state, ev) {
    var idle = state.holding === "";
    if (ev.type === "keyDown") {
        var arrow = ev.code === KEYS.left || ev.code === KEYS.right;
        var enter = isEnter(ev.code);
        var letter = kindForCode(ev.code);
        if (!arrow && !enter && letter === "")
            return answer(state, "none", "", false);
        if (!arrow && ev.chord)
            return answer(state, "none", "", false);
        if (ev.repeat)
            return answer(state, "none", "", true);
        if (arrow) {
            // Moving off a button ends its hold, as the pointer leaving does.
            var moved = { keyboard: true, focused: step(state.focused, ev.code === KEYS.left ? -1 : 1, ITEMS.length) };
            return idle ? answer(patch(state, moved), "none", "", true) : stopHold(state, moved);
        }
        // A hold belongs to the press that started it: a second press (key or pointer) is ignored.
        if (!idle)
            return answer(state, "none", "", true);
        var focused = enter ? state.focused : indexOf(letter);
        return press(patch(state, { keyboard: true, focused: focused }), ITEMS[focused].id, sourceOfKey(ev.code));
    }
    if (ev.type === "keyUp") {
        // Any key release ends a running hold, whichever key it is: a modifier (AltGr on the pl layout) changes
        // the key code of the release, so it cannot be matched to the press. Cancelling is the safe side; it
        // costs a re-press. Auto-repeat is not a release.
        if (!ev.repeat && !idle)
            return stopHold(state, {});
        return answer(state, "none", "", false);
    }
    if (ev.type === "pointerPress") {
        if (!idle)
            return answer(state, "none", "", false);
        var pressed = patch(state, { keyboard: false });
        return isHold(ev.kind) ? press(pressed, ev.kind, "pointer") : answer(pressed, "none", "", false);
    }
    if (ev.type === "pointerClick")
        return idle && item(ev.kind) !== null && !isHold(ev.kind) ? answer(state, "finish", ev.kind, false) : answer(state, "none", "", false);
    if (ev.type === "pointerRelease")
        return !idle && state.source === "pointer" && state.holding === ev.kind ? stopHold(state, {}) : answer(state, "none", "", false);
    if (ev.type === "focusLost")
        return idle ? answer(state, "none", "", false) : stopHold(state, {});
    if (ev.type === "active")
        // Opening or closing the layer starts clean; the cancel always stops a timer that might be running.
        return answer(initial(), "cancel", state.holding, false);
    if (ev.type === "timerElapsed")
        // Only a hold that is still on confirms: a tick after a cancel finds nothing.
        return idle ? answer(state, "none", "", false) : answer(patch(state, { holding: "", source: "" }), "finish", state.holding, false);
    return answer(state, "none", "", false);
}
