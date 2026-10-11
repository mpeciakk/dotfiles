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
});

test("guard: the IdleMonitor takes enabled and timeout from L.idle with the file's testMode and respects inhibitors", () => {
    const m = lock.code.match(/IdleMonitor\s*\{[\s\S]*?\n\s{4}\}/);
    assert.ok(m, "no IdleMonitor block");
    assert.match(m[0], /respectInhibitors\s*:\s*true/);
    assert.match(m[0], /enabled\s*:\s*root\.idle\.enabled\s*&&\s*!\s*sessionLock\.locked/);
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
