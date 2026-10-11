import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, existsSync } from "node:fs";
import { join, dirname, relative } from "node:path";
import { fileURLToPath } from "node:url";
import { load, plain, strip, qmlFiles, functionSpan } from "./qmljs.mjs";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const L = existsSync(join(root, "lib/lock.js")) ? load("lib/lock.js") : {};
const T = load("lib/theme.js");

// ---- lib/lock.js: the decisions of the session lock (Lock.qml applies them) ----

test("engage: only an explicit false test mode locks, and only when not locked yet", () => {
    assert.equal(L.engage(false, false).engage, true);
    assert.equal(L.engage(false, true).engage, false);
    for (const odd of [true, undefined, null, "", 0, 1, "false"])
        assert.equal(L.engage(odd, false).engage, false, `test mode ${JSON.stringify(odd)} must not lock`);
});

test("engage: test mode says what it would do, and never mentions anything but the lock", () => {
    assert.equal(L.engage(true, false).message, "lock (test mode): would lock the session");
    assert.equal(L.engage(false, false).message, "lock: locking the session");
    assert.equal(L.engage(false, true).message, "lock: already locked");
});

test("idle: an absent timeout takes the default", () => {
    assert.deepStrictEqual(plain(L.idle(undefined, 300, false)), { enabled: true, timeout: 300 });
    assert.deepStrictEqual(plain(L.idle(null, 300, false)), { enabled: true, timeout: 300 });
});

test("idle: a positive timeout is used as it is", () => {
    assert.deepStrictEqual(plain(L.idle(120, 300, false)), { enabled: true, timeout: 120 });
});

test("idle: 0, negative or non-number timeouts disable it, and the monitor timeout stays positive", () => {
    // IdleMonitor reports idle at once with timeout 0: a disabled monitor still gets the default.
    for (const t of [0, -5, "300", NaN, true, {}])
        assert.deepStrictEqual(plain(L.idle(t, 300, false)), { enabled: false, timeout: 300 }, `timeout ${String(t)}`);
});

test("idle: a non-positive default with no valid host timeout disables it (0 must not lock right after startup)", () => {
    for (const d of [0, -1, NaN, undefined])
        for (const host of [undefined, null])
            assert.equal(L.idle(host, d, false).enabled, false, `default ${String(d)}, host ${String(host)}`);
    // the monitor timeout stays positive, as for any disabled idle lock
    assert.equal(L.idle(undefined, 0, false).timeout, 1);
});

test("idle: a valid host timeout still enables it whatever the default is", () => {
    assert.deepStrictEqual(plain(L.idle(120, 0, false)), { enabled: true, timeout: 120 });
});

test("errorShown: the error shows after a refusal until the first typed character, and never comes back when the field empties", () => {
    assert.equal(L.errorShown(true, false), true);
    assert.equal(L.errorShown(true, true), false);
    assert.equal(L.errorShown(false, false), false);
    assert.equal(L.errorShown(false, true), false);
});

test("keepsLocked: a lock request during the reverse morph keeps the session locked; nothing else does", () => {
    assert.equal(L.keepsLocked(false, true, true), true);
    for (const [testMode, locked, unlocking] of [[false, true, false], [false, false, true], [false, false, false], [true, true, true], [undefined, true, true], [null, true, true]])
        assert.equal(L.keepsLocked(testMode, locked, unlocking), false, JSON.stringify([testMode, locked, unlocking]));
});

test("idle: test mode, or an unknown test mode, always disables it", () => {
    for (const mode of [true, undefined, null, 1])
        assert.deepStrictEqual(plain(L.idle(120, 300, mode)), { enabled: false, timeout: 120 });
});

test("notifCount: the Polish plural of the notification count", () => {
    const cases = [[0, "0 powiadomień"], [1, "1 powiadomienie"], [2, "2 powiadomienia"], [4, "4 powiadomienia"],
        [5, "5 powiadomień"], [12, "12 powiadomień"], [14, "14 powiadomień"], [22, "22 powiadomienia"], [25, "25 powiadomień"],
        [112, "112 powiadomień"], [101, "101 powiadomień"]];
    for (const [n, s] of cases) assert.equal(L.notifCount(n), s);
});

test("initial: the first letter of the name, else of the user, upper-cased", () => {
    assert.equal(L.initial("", "m"), "M");
    assert.equal(L.initial("ernest", "m"), "E");
    assert.equal(L.initial(undefined, undefined), "?");
});

test("defaults: lock.timeoutDefault is 300 s", () => {
    assert.equal(T.defaults.lock.timeoutDefault, 300);
});

// ---- Source guard: Lock.qml engageLock() is the ONE place that locks the session ----
// Nothing else may set WlSessionLock.locked to anything but false, bind it, or own a WlSessionLock; engageLock()
// decides through L.engage() with the file's own testMode and returns before it locks. PAM starts only outside
// test mode. No QML registers an IPC target "lock" (the old shell had one; tests/shot.sh no longer asks it).

const LOCK = "Lock.qml";
const sources = qmlFiles().map(f => ({ rel: relative(root, f), code: strip(readFileSync(f, "utf8")) }));
const lock = sources.find(s => s.rel === LOCK);

function body(name) {
    const span = functionSpan(lock.code, name);
    assert.ok(span, `no ${name}() in ${LOCK}`);
    return lock.code.slice(span.start, span.end);
}

test("guard: Lock.qml exists with engageLock()", () => {
    assert.ok(lock, `${LOCK} missing`);
    assert.ok(functionSpan(lock.code, "engageLock"), `no engageLock() in ${LOCK}`);
});

test("guard: WlSessionLock lives only in Lock.qml", () => {
    assert.deepEqual(sources.filter(s => /\bWlSessionLock\b/.test(s.code)).map(s => s.rel), [LOCK]);
});

test("guard: locked is never bound, and set to anything but false only inside engageLock()", () => {
    assert.ok(lock, `${LOCK} missing`);
    assert.doesNotMatch(lock.code, /\blocked\s*:/, "a declarative `locked:` binding could lock on its own");
    const span = functionSpan(lock.code, "engageLock");
    const engaging = [...lock.code.matchAll(/\blocked\s*=(?!=)(?!\s*false\b)/g)];
    assert.equal(engaging.length, 1, "exactly one assignment of locked that is not false");
    assert.ok(engaging[0].index >= span.start && engaging[0].index < span.end, "that assignment is inside engageLock()");
    assert.match(body("engageLock"), /\.locked\s*=\s*true\s*;/);
});

test("guard: engageLock() decides through L.engage with the file's testMode and returns before locking", () => {
    const b = body("engageLock");
    const decide = b.search(/L\.engage\(\s*root\.testMode\s*,\s*sessionLock\.locked\s*\)/);
    const bail = b.search(/if\s*\(\s*!\s*d\.engage\s*\)\s*return\b/);
    const engage = b.search(/\.locked\s*=\s*true/);
    assert.ok(decide >= 0, "engageLock() does not call L.engage(root.testMode, sessionLock.locked)");
    assert.ok(bail > decide, "engageLock() must return on !d.engage right after deciding");
    assert.ok(engage > bail, "engageLock() locks only after the !d.engage return");
});

test("guard: Lock.qml's testMode is read-only, bound to WYSPA_TEST === 1 and declared once", () => {
    assert.match(lock.code, /readonly\s+property\s+bool\s+testMode\s*:\s*Quickshell\.env\(\s*(["'])WYSPA_TEST\1\s*\)\s*===\s*(["'])1\2\s*(\n|;|$)/);
    assert.equal((lock.code.match(/\btestMode\s*:/g) ?? []).length, 1);
});

test("guard: every lock request (power gate, IPC, idle) goes to engageLock()", () => {
    assert.match(lock.code, /function\s+onLockRequested\s*\(\s*\)\s*(:\s*void\s*)?\{\s*root\.engageLock\(/);
    assert.match(lock.code, /function\s+onLockAsked\s*\(\s*\)\s*(:\s*void\s*)?\{\s*root\.engageLock\(/);
    assert.match(lock.code, /onIsIdleChanged\s*:\s*\{?\s*if\s*\(\s*isIdle\s*\)\s*root\.engageLock\(/);
    assert.match(lock.code, /function\s+onSleepSignal\s*\([^)]*\)[^{]*\{[\s\S]*?root\.engageLock\(\s*"sleep"\s*\)/);
});

test("guard: the IdleMonitor takes enabled and timeout from L.idle with the file's testMode and respects inhibitors", () => {
    const m = lock.code.match(/IdleMonitor\s*\{[\s\S]*?\n\s{4}\}/);
    assert.ok(m, "no IdleMonitor block");
    assert.match(m[0], /respectInhibitors\s*:\s*true/);
    assert.match(m[0], /enabled\s*:\s*root\.idle\.enabled\s*&&\s*!\s*root\.lockOn/);
    assert.match(m[0], /timeout\s*:\s*root\.idle\.timeout/);
    assert.match(lock.code, /readonly\s+property\s+var\s+idle\s*:\s*L\.idle\([^)]*,\s*root\.testMode\s*\)/);
});

test("guard: PAM starts only in authenticate(), after its test-mode return", () => {
    assert.equal((lock.code.match(/\bpam\.start\(/g) ?? []).length, 1);
    const b = body("authenticate");
    const bail = b.search(/if\s*\(\s*root\.testMode\s*\)\s*\{[^}]*return\s*;?\s*\}/);
    const start = b.search(/\bpam\.start\(/);
    assert.ok(bail >= 0 && start > bail, "authenticate() must return in test mode before pam.start()");
});

test("guard: nothing in Lock.qml logs the password or the PAM conversation", () => {
    for (const m of lock.code.matchAll(/console\.\w+\(([^;]*)\)/g))
        assert.doesNotMatch(m[1], /password|pending|typed|\bpw\b|\.text\b|\bpam\./i, `logs: ${m[0]}`);
});

test("guard: no QML registers an IPC target named lock", () => {
    assert.deepEqual(sources.filter(s => /target\s*:\s*["']lock["']/.test(s.code)).map(s => s.rel), []);
});

test("guard: the island IPC has lock(), unlock() and a readable locked, wired by IslandState's own signals", () => {
    const st = sources.find(s => s.rel === "IslandState.qml").code;
    assert.match(st, /signal\s+lockAsked\b/);
    assert.match(st, /signal\s+unlockAsked\b/);
    assert.match(st, /readonly\s+property\s+bool\s+locked\s*:\s*root\.locked/);
    assert.match(st, /function\s+lock\s*\(\s*\)\s*:\s*void\s*\{\s*root\.lockAsked\(\s*\)\s*;?\s*\}/);
    assert.match(st, /function\s+unlock\s*\(\s*\)\s*:\s*void\s*\{\s*root\.unlockAsked\(\s*\)\s*;?\s*\}/);
});

test("guard: the unlock hatch drops the lock at once, without PAM", () => {
    const b = body("unlockNow");
    assert.match(b, /\bsessionLock\.locked\s*=\s*false\b/);
    assert.match(lock.code, /function\s+onUnlockAsked\s*\(\s*\)\s*(:\s*void\s*)?\{\s*root\.unlockNow\(/);
});

test("guard: engageLock() cancels a running reverse morph through L.keepsLocked, before it decides and without touching locked", () => {
    const b = body("engageLock");
    const keep = b.search(/L\.keepsLocked\(\s*root\.testMode\s*,\s*sessionLock\.locked\s*,\s*root\.unlocking\s*\)/);
    const decide = b.search(/L\.engage\(/);
    assert.ok(keep >= 0 && keep < decide, "engageLock() must ask L.keepsLocked(root.testMode, sessionLock.locked, root.unlocking) first");
    const branch = b.slice(keep, decide);
    assert.match(branch, /releaseTimer\.stop\(\)/);
    assert.match(branch, /root\.unlocking\s*=\s*false/);
    assert.match(branch, /return\s*;/);
    assert.doesNotMatch(branch, /\blocked\s*=/);
});

test("guard: engageLock() returns from the keepsLocked branch itself (polarity: the branch is taken when it keeps the lock)", () => {
    const b = body("engageLock");
    const m = b.match(/if\s*\(\s*L\.keepsLocked\(\s*root\.testMode\s*,\s*sessionLock\.locked\s*,\s*root\.unlocking\s*\)\s*\)\s*\{/);
    assert.ok(m, "engageLock() must branch on L.keepsLocked(...) un-negated");
    const open = m.index + m[0].length;
    const close = b.indexOf("\n        }", open);
    assert.ok(close > open, "branch body not found");
    assert.match(b.slice(open, close), /\breturn\s*;/, "the keepsLocked branch must return");
});

// A hot reload while locked releases the lock without PAM: upstream WlSessionLock::onReload hands the old manager to
// the new instance, which starts with locked == false and calls unlock() on it. dotter symlinks every file of the
// config dir, so any write in the repo would reload the live shell. Hence no file watching; restart after deploy.
test("guard: shell.qml does not hot-reload (a reload while locked unlocks without PAM), and says why", () => {
    const raw = readFileSync(join(root, "shell.qml"), "utf8");
    assert.match(strip(raw), /settings\.watchFiles\s*:\s*false\b/);
    assert.equal([...strip(raw).matchAll(/watchFiles\s*:/g)].length, 1, "watchFiles is set exactly once");
    assert.match(raw, /\/\/[^\n]*reload[^\n]*lock[^\n]*restart/i, "a one-line comment must give the reason");
});

test("guard: the lock card's error follows L.errorShown and the first typed character clears it", () => {
    const card = readFileSync(join(root, "states/LockCard.qml"), "utf8");
    const code = strip(card);
    assert.match(code, /readonly\s+property\s+bool\s+showError\s*:\s*L\.errorShown\(\s*root\.failed\s*,\s*root\.typedSinceFailure\s*\)/);
    assert.doesNotMatch(code, /showError\s*:[^\n]*field\.text/, "showError must not depend on the field being empty");
    assert.match(code, /onFailedChanged\s*:\s*if\s*\(\s*root\.failed\s*\)\s*root\.typedSinceFailure\s*=\s*false/);
    assert.match(code, /onTextChanged\s*:\s*if\s*\(\s*field\.text\.length\s*>\s*0\s*\)\s*root\.typedSinceFailure\s*=\s*true/);
});

test("guard: tests/shot.sh refuses while the live shell or the checkout's instance is locked", () => {
    const shot = readFileSync(join(root, "tests/shot.sh"), "utf8");
    assert.match(shot, /qs ipc prop get island locked/);
    assert.match(shot, /qs ipc -p "\$DIR" prop get island locked/);
    assert.doesNotMatch(shot, /qs ipc call lock\b/, "the old shell's lock target is gone after deploy");
});

test("guard: the lock overlay lives in the island windows, only while the lock has a phase, and takes no input", () => {
    const island = readFileSync(join(root, "Island.qml"), "utf8");
    assert.match(island, /Loader\s*\{[^}]*active:\s*IslandState\.lockPhase\s*!==\s*""[\s\S]*?LockOverlay\s*\{/);
    const overlay = readFileSync(join(root, "LockOverlay.qml"), "utf8");
    assert.doesNotMatch(overlay, /\b(MouseArea|TapHandler|HoverHandler|Keys\.|focus\s*:)/);
    // The phase never passes through "" between "in" and "locked", or between "back" and "in".
    assert.match(lock.code, /lockPhase:\s*root\.lockOn\s*\?\s*"locked"\s*:\s*root\.handoff\s*\?\s*"back"\s*:\s*root\.prelude\s*!==\s*0\s*\?\s*"in"\s*:\s*""/);
    const b = body("engageLock");
    assert.ok(b.search(/root\.lockOn\s*=/) < b.search(/root\.prelude\s*=\s*0/), "prelude is cleared only after lockOn is set");
    const start = b.slice(b.search(/step\s*===\s*"prelude"/));
    assert.ok(start.search(/root\.prelude\s*=\s*1/) < start.search(/root\.stopHandoff\(\)/), "the way in starts before the hand-off stops");
});

test("guard: the lock drops handoffMs after a correct password, and the hand-off ends after the last of its animations", () => {
    assert.match(lock.code, /id:\s*releaseTimer[\s\S]{0,120}interval:\s*Theme\.reducedMotion\s*\?\s*0\s*:\s*Theme\.layout\.lock\.handoffMs/);
    assert.match(lock.code, /id:\s*handoffEnd[\s\S]{0,200}interval:\s*Theme\.reducedMotion\s*\?\s*0\s*:\s*Math\.max\(Theme\.motion\.lockMorphMs,\s*Theme\.layout\.lock\.deskDelayMs\s*\+\s*Theme\.layout\.lock\.deskMs,\s*Theme\.layout\.lock\.earDelayMs\s*\+\s*Theme\.layout\.lock\.earMs\)/);
    // The lock surface's first frame is the look the overlay's way in ended on: its card's content in without an enter.
    assert.match(lock.code, /enterAnimated:\s*false\s*\n\s*revealed:\s*surface\.shown/);
});

test("guard: bindings follow lockOn, never WlSessionLock.locked outside the lock surfaces (it does not notify an unlock)", () => {
    const surfaceStart = lock.code.indexOf("surface: Component {");
    assert.ok(surfaceStart > 0);
    const surfaceEnd = lock.code.length; // the surface component is the last thing in the file
    const outside = lock.code.slice(0, surfaceStart) + lock.code.slice(surfaceEnd);
    // A declarative binding is `name: <expr>` on one line; imperative reads (in functions) end in `;` or `(`/`)`.
    const bound = outside.split("\n").filter(l => /^\s*[\w.]+\s*:\s*[^{]*\bsessionLock\.locked\b/.test(l) && !/\bfunction\b/.test(l));
    assert.deepEqual(bound, []);
    assert.match(lock.code, /readonly property bool hidesIsland:\s*root\.prelude\s*!==\s*0\s*\|\|\s*root\.lockOn\b/);
    assert.match(lock.code, /enabled:\s*root\.idle\.enabled\s*&&\s*!root\.lockOn/);
    assert.match(lock.code, /onLockOnChanged:\s*IslandState\.reportLocked\(root\.lockOn\)/);
});

test("guard: the release starts the hand-off before it unlocks (the unlock clears secure, which would drop the overlay)", () => {
    const m = lock.code.match(/id:\s*releaseTimer[\s\S]*?onTriggered:\s*\{([\s\S]*?)\n\s{8}\}/);
    assert.ok(m, "no releaseTimer onTriggered block");
    const b = m[1];
    const handoff = b.search(/root\.handoff\s*=/);
    const unlock = b.search(/sessionLock\.locked\s*=\s*false/);
    assert.ok(handoff >= 0 && unlock > handoff);
});

test("dock: rounded top corners above dockAt, the island's ears below it, never both, 0 at dockAt", () => {
    const d = 0.05;
    assert.deepEqual(plain(L.dock(1, d)), { top: 1, ear: 0 });
    assert.deepEqual(plain(L.dock(0, d)), { top: 0, ear: 1 });
    assert.deepEqual(plain(L.dock(d, d)), { top: 0, ear: 0 });
    for (const m of [0, 0.01, 0.03, 0.049, 0.05, 0.06, 0.3, 0.7, 1]) {
        const r = L.dock(m, d);
        assert.ok(r.top === 0 || r.ear === 0, `both at ${m}`);
        assert.ok(r.top >= 0 && r.top <= 1 && r.ear >= 0 && r.ear <= 1, `range at ${m}`);
    }
    assert.ok(L.dock(0.02, d).ear > L.dock(0.04, d).ear, "the ears grow as the card docks");
});

test("lockStep: the way in first, wait while it plays, then lock; reduced motion locks at once", () => {
    assert.equal(L.lockStep(0, false), "prelude");
    assert.equal(L.lockStep(1, false), "wait");
    assert.equal(L.lockStep(2, false), "lock");
    assert.equal(L.lockStep(0, true), "lock");
    assert.equal(L.lockStep(1, true), "wait");
});

test("lockStep: a sleep request is never waited out: it snaps to the end look, or waits for the snap already running", () => {
    // 0 none and 1 playing: snap (the way in at zero durations, then the lock after the frames); reduced motion does not skip the frames.
    for (const reduced of [false, true]) {
        assert.equal(L.lockStep(0, reduced, true, false), "snap", `prelude 0, reduced ${reduced}`);
        assert.equal(L.lockStep(1, reduced, true, false), "snap", `playing a normal way in, reduced ${reduced}`);
        assert.equal(L.lockStep(2, reduced, true, false), "lock", `the way in ended, reduced ${reduced}`);
        assert.equal(L.lockStep(1, reduced, true, true), "wait", `a snap is waiting for its frames, reduced ${reduced}`);
    }
});

test("lockStep: a plain request is unchanged by the sleep arguments", () => {
    for (const instant of [false, true]) {
        assert.equal(L.lockStep(0, false, false, instant), "prelude");
        assert.equal(L.lockStep(1, false, false, instant), "wait");
        assert.equal(L.lockStep(2, false, false, instant), "lock");
        assert.equal(L.lockStep(0, true, false, instant), "lock");
    }
});

test("sleepSignal: reads PrepareForSleep from a `gdbus monitor --system` line (format taken from the live bus)", () => {
    const sig = "/org/freedesktop/login1: org.freedesktop.login1.Manager.PrepareForSleep";
    assert.equal(L.sleepSignal(`${sig} (true,)`), "start");
    assert.equal(L.sleepSignal(`${sig} (false,)`), "resume");
    // anything else, including the monitor's own banner and other logind signals, is not a sleep event
    for (const other of ["", "Monitoring signals on object /org/freedesktop/login1 owned by org.freedesktop.login1",
        "The name org.freedesktop.login1 is owned by :1.4",
        "/org/freedesktop/login1/session/_33: org.freedesktop.login1.Session.Lock ()",
        "/org/freedesktop/login1: org.freedesktop.login1.Manager.PrepareForShutdown (true,)",
        `${sig} (maybe,)`, `${sig} ()`, undefined, null, 5])
        assert.equal(L.sleepSignal(other), "other", JSON.stringify(other));
});

test("inhibitorWanted: held while unlocked or while the lock is not secure yet, released only when sleep is pending on a secure lock", () => {
    assert.equal(L.inhibitorWanted(false, false, false), true, "idle, unlocked");
    assert.equal(L.inhibitorWanted(false, true, false), true, "sleep pending, the lock is not secure yet: keep delaying");
    assert.equal(L.inhibitorWanted(false, false, true), true, "locked, no sleep: held again (the wake retakes it)");
    assert.equal(L.inhibitorWanted(false, true, true), false, "sleep pending and secure: release, logind may suspend");
});

test("inhibitorWanted and sleepWatched: only an explicit false test mode runs the processes", () => {
    for (const odd of [true, undefined, null, "", 0, 1, "false"]) {
        assert.equal(L.inhibitorWanted(odd, false, false), false, `inhibitor, test mode ${JSON.stringify(odd)}`);
        assert.equal(L.sleepWatched(odd), false, `monitor, test mode ${JSON.stringify(odd)}`);
    }
    assert.equal(L.sleepWatched(false), true);
});

test("framesPresented: the lock waits for every output's window, and for none that is not there", () => {
    assert.equal(L.framesPresented(["DP-1", "HDMI-A-1"], { "DP-1": true }), false);
    assert.equal(L.framesPresented(["DP-1", "HDMI-A-1"], { "DP-1": true, "HDMI-A-1": true }), true);
    assert.equal(L.framesPresented(["DP-1"], { "DP-1": true, "gone": true }), true, "a frame from an output that left does not matter");
    assert.equal(L.framesPresented([], {}), true, "no output, nothing to wait for");
});

test("sleep: a request on an already locked session only stays locked (no second lock)", () => {
    assert.equal(L.engage(false, true).engage, false);
    assert.equal(L.inhibitorWanted(false, true, true), false, "and the inhibitor is released at once");
});

test("lockInMs: the way in lasts until its last part is in (the extras, with the defaults)", () => {
    const m = T.defaults.motion, s = T.defaults.layout.lock;
    const ms = L.lockInMs(m, s);
    for (const part of [m.lockMorphMs, m.wallpaperMs, s.deskMs, s.enterDelayMs + s.enterOpacityMs, s.extrasDelayMs + s.extrasMs])
        assert.ok(ms >= part, `${ms} < ${part}`);
    assert.equal(ms, s.extrasDelayMs + s.extrasMs);
});

test("guard: engageLock() starts the way in only after its test-mode decision, and the prelude timer comes back to it", () => {
    const b = body("engageLock");
    const bail = b.search(/if\s*\(\s*!\s*d\.engage\s*\)\s*return\b/);
    const step = b.search(/L\.lockStep\(\s*root\.prelude\s*,\s*Theme\.reducedMotion\s*,\s*source\s*===\s*"sleep"\s*,\s*Theme\.lockInstant\s*\)/);
    const start = b.search(/root\.prelude\s*=\s*1/);
    assert.ok(bail >= 0 && step > bail && start > step);
    assert.match(lock.code, /id:\s*preludeTimer[\s\S]{0,200}interval:\s*L\.lockInMs\(Theme\.motion,\s*Theme\.layout\.lock\)[\s\S]{0,120}root\.prelude\s*=\s*2;\s*root\.engageLock\(root\.preludeFor\)/);
    // The hatch stops a pending way in and clears it, so it cannot lock after an unlock nor leave the island hidden.
    assert.match(body("unlockNow"), /preludeTimer\.stop\(\);\s*root\.prelude\s*=\s*0/);
});

test("guard: a lock the compositor ends itself releases through secure, not locked (locked still reads true in that signal)", () => {
    assert.match(lock.code, /onSecureStateChanged:\s*\{\s*if\s*\(\s*!sessionLock\.secure\s*&&\s*root\.lockOn\s*\)\s*root\.released\(\)/);
});

// ---- Lock before sleep (DESIGN W14) ----

function block(re, what) {
    const m = lock.code.match(re);
    assert.ok(m, `no ${what}`);
    return m[1];
}

test("guard: the sleep monitor and the delay inhibitor start only through the test-mode helpers, in Lock.qml, and nowhere else", () => {
    assert.match(lock.code, /readonly\s+property\s+bool\s+watchSleep\s*:\s*L\.sleepWatched\(\s*root\.testMode\s*\)/);
    assert.match(lock.code, /readonly\s+property\s+bool\s+holdInhibitor\s*:\s*L\.inhibitorWanted\(\s*root\.testMode\s*,\s*root\.sleepPending\s*,\s*root\.lockSecure\s*\)/);
    // each process is started from one `running = true`, behind its own gate
    assert.match(block(/function\s+syncInhibitor\s*\([^)]*\)[^{]*\{([\s\S]*?)\n    \}/, "syncInhibitor()"), /root\.holdInhibitor[\s\S]*inhibitor\.running\s*=\s*true/);
    assert.match(block(/function\s+syncMonitor\s*\([^)]*\)[^{]*\{([\s\S]*?)\n    \}/, "syncMonitor()"), /root\.watchSleep[\s\S]*monitor\.running\s*=\s*true/);
    assert.equal((lock.code.match(/\.running\s*=\s*true/g) ?? []).length, 2, "no other process is started");
    for (const s of sources.filter(s => s.rel !== LOCK))
        assert.doesNotMatch(s.code, /systemd-inhibit|PrepareForSleep/, `${s.rel} touches the sleep inhibitor`);
});

test("guard: the inhibitor is a logind sleep delay inhibitor, the monitor watches PrepareForSleep on the system bus", () => {
    assert.match(lock.code, /"systemd-inhibit"\s*,\s*"--what=sleep"\s*,\s*"--mode=delay"\s*,\s*"--who=wyspa"/);
    assert.match(lock.code, /"gdbus"\s*,\s*"monitor"\s*,\s*"--system"\s*,\s*"--dest"\s*,\s*"org\.freedesktop\.login1"\s*,\s*"--object-path"\s*,\s*"\/org\/freedesktop\/login1"/);
});

test("guard: the monitor records sleepPending through L.sleepSignal; a sleep start asks engageLock('sleep') and sets nothing else", () => {
    const b = block(/function\s+onSleepSignal\s*\([^)]*\)[^{]*\{([\s\S]*?)\n    \}/, "onSleepSignal()");
    assert.match(b, /L\.sleepSignal\(\s*line\s*\)/);
    assert.match(b, /root\.sleepPending\s*=\s*true/);
    assert.match(b, /root\.sleepPending\s*=\s*false/);
    assert.match(b, /root\.engageLock\(\s*"sleep"\s*\)/);
    assert.doesNotMatch(b, /\blocked\s*=/, "a sleep request never sets locked itself");
});

test("guard: a restart never happens by itself while the inhibitor is released (a release during a pending sleep is never undone)", () => {
    assert.match(lock.code, /id:\s*inhibitor[\s\S]*?onExited:\s*inhibitRestart\.restart\(\)/);
    assert.match(lock.code, /id:\s*inhibitRestart[\s\S]*?onTriggered:\s*root\.syncInhibitor\(\)/);
    assert.match(lock.code, /id:\s*monitor[\s\S]*?onExited:\s*monitorRestart\.restart\(\)/);
    assert.match(lock.code, /id:\s*monitorRestart[\s\S]*?onTriggered:\s*root\.syncMonitor\(\)/);
    assert.match(lock.code, /onHoldInhibitorChanged:\s*root\.syncInhibitor\(\)/);
});

test("guard: a lock request closes the island after the test-mode decision, so no modal state receives the password", () => {
    const b = body("engageLock");
    const bail = b.search(/if\s*\(\s*!\s*d\.engage\s*\)\s*return\b/);
    const close = b.search(/IslandState\.close\(\s*\)/);
    const step = b.search(/L\.lockStep\(/);
    assert.ok(bail >= 0 && close > bail && close < step, "IslandState.close() between the decision and the lock step");
});

test("guard: a sleep request snaps the way in (Theme.lockInstant first, remount), waits for every window's frame, and locks through engageLock()", () => {
    const b = body("engageLock");
    const snap = b.match(/if\s*\(\s*step\s*===\s*"snap"\s*\)\s*\{([\s\S]*?)\n        \}/);
    assert.ok(snap, "no snap branch");
    const s = snap[1];
    const instant = s.search(/Theme\.lockInstant\s*=\s*true/);
    assert.ok(instant >= 0 && instant < s.search(/root\.prelude\s*=\s*1/), "instant before the phase, so the overlay mounts at zero durations");
    assert.match(s, /IslandState\.reportLockFrameWait\(\s*true\s*\)/);
    assert.match(s, /IslandState\.remountLock\(\)/);
    assert.match(s, /preludeTimer\.stop\(\)/);
    assert.match(s, /frameCapTimer\.restart\(\)/);
    assert.match(s, /return\s*;/);
    // the frames (or the cap) come back to engageLock() with the way in ended, never to a second place that locks
    assert.match(lock.code, /function\s+onLockFramePresented\s*\([^)]*\)[^{]*\{[\s\S]*?L\.framesPresented\([\s\S]*?root\.prelude\s*=\s*2;\s*root\.engageLock\(root\.preludeFor\)/);
    assert.match(lock.code, /id:\s*frameCapTimer[\s\S]{0,200}interval:\s*Theme\.tokens\.lock\.sleepFrameCapMs[\s\S]{0,160}root\.prelude\s*=\s*2;\s*root\.engageLock\(root\.preludeFor\)/);
    // once locked, the instant mode and the frame wait end (the way back plays as in W12)
    const end = b.slice(b.search(/sessionLock\.locked\s*=\s*true/));
    assert.match(end, /Theme\.lockInstant\s*=\s*false/);
    assert.match(end, /IslandState\.reportLockFrameWait\(\s*false\s*\)/);
    assert.match(end, /frameCapTimer\.stop\(\)/);
    assert.match(body("unlockNow"), /Theme\.lockInstant\s*=\s*false/);
});

test("guard: Theme.lockInstant is the reduced-motion path: it only adds to the token", () => {
    const theme = strip(readFileSync(join(root, "Theme.qml"), "utf8"));
    assert.match(theme, /property\s+bool\s+lockInstant\s*:\s*false/);
    assert.match(theme, /readonly\s+property\s+bool\s+reducedMotion\s*:\s*root\.tokens\.reducedMotion\s*\|\|\s*root\.lockInstant\b/);
});

test("guard: the overlay reports its window's frames per output only while the lock waits, and the island window can remount it", () => {
    const overlay = strip(readFileSync(join(root, "LockOverlay.qml"), "utf8"));
    assert.match(overlay, /Connections\s*\{[^}]*target\s*:\s*over\.Window\.window[^}]*enabled\s*:\s*IslandState\.lockFrameWait[\s\S]*?function\s+onFrameSwapped\s*\(\s*\)\s*(:\s*void\s*)?\{\s*IslandState\.reportLockFrame\(\s*over\.screen\.name\s*\)/);
    const island = readFileSync(join(root, "Island.qml"), "utf8");
    assert.match(island, /Loader\s*\{\s*id:\s*lockLoader[^}]*active:\s*IslandState\.lockPhase\s*!==\s*""[\s\S]*?function\s+onLockRemounted\s*\(\s*\)\s*(:\s*void\s*)?\{\s*lockLoader\.active\s*=\s*false;\s*lockLoader\.active\s*=\s*Qt\.binding\(\s*\(\)\s*=>\s*IslandState\.lockPhase\s*!==\s*""\s*\)/);
});

test("guard: the way in takes the keyboard on the focused output and the whole input on every window, never in test mode, and no item holds focus", () => {
    const island = strip(readFileSync(join(root, "Island.qml"), "utf8"));
    assert.match(island, /readonly\s+property\s+bool\s+wayIn\s*:\s*IslandState\.lockPhase\s*===\s*"in"/);
    assert.match(island, /WlrLayershell\.keyboardFocus\s*:\s*Quickshell\.env\(\s*"WYSPA_TEST"\s*\)\s*!==\s*"1"\s*&&\s*\(\s*root\.modalHere\s*\|\|\s*root\.wayIn\s*&&\s*Niri\.focusedOutput\s*===\s*root\.screen\.name\s*\)\s*\?\s*WlrKeyboardFocus\.Exclusive\s*:\s*WlrKeyboardFocus\.None/);
    assert.match(island, /readonly\s+property\s+string\s+maskMode\s*:\s*root\.modalHere\s*\|\|\s*root\.wayIn\s*\?\s*"full"/);
    assert.match(island, /focus\s*:\s*root\.modalHere\s*&&\s*!root\.wayIn\b/);
});
