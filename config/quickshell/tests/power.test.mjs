import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, existsSync } from "node:fs";
import { join, dirname, relative } from "node:path";
import { fileURLToPath } from "node:url";
import { load, plain, strip, qmlFiles, jsFiles, functionSpan } from "./qmljs.mjs";

const P = load("lib/power.js");
const T = load("lib/theme.js");
const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const COMMANDS = plain(T.defaults.power.commands);

test("defaults: power.commands are the four real commands (reference 3.8, brief)", () => {
    assert.deepStrictEqual(COMMANDS, {
        suspend: ["systemctl", "suspend"],
        logout: ["niri", "msg", "action", "quit", "--skip-confirmation"],
        reboot: ["systemctl", "reboot"],
        poweroff: ["systemctl", "poweroff"]
    });
});

test("buttons: five, in reference order, with their done labels and keys", () => {
    assert.deepStrictEqual(plain(P.ITEMS).map(i => [i.id, i.label, i.key, i.done]), [
        ["lock", "Zablokuj", "L", "Blokowanie…"],
        ["sleep", "Uśpij", "S", "Usypianie…"],
        ["logout", "Wyloguj", "O", "Wylogowywanie…"],
        ["reboot", "Restart", "R", "Ponowne uruchamianie…"],
        ["off", "Wyłącz", "P", "Wyłączanie…"]
    ]);
});

test("buttons: only Wyłącz is a danger button", () => {
    assert.deepStrictEqual(plain(P.ITEMS).filter(i => i.danger).map(i => i.id), ["off"]);
});

test("isHold: only logout, reboot and off need the hold", () => {
    assert.deepStrictEqual(["lock", "sleep", "logout", "reboot", "off"].map(P.isHold), [false, false, true, true, true]);
    assert.equal(P.isHold("nope"), false);
});

test("label: the done label of a button, empty for an unknown one", () => {
    assert.equal(P.label("off"), "Wyłączanie…");
    assert.equal(P.label("lock"), "Blokowanie…");
    assert.equal(P.label("nope"), "");
});

test("commandFor: maps buttons to Theme.tokens.power.commands, lock has none", () => {
    assert.deepStrictEqual(plain(P.commandFor("sleep", COMMANDS)), ["systemctl", "suspend"]);
    assert.deepStrictEqual(plain(P.commandFor("logout", COMMANDS)), ["niri", "msg", "action", "quit", "--skip-confirmation"]);
    assert.deepStrictEqual(plain(P.commandFor("reboot", COMMANDS)), ["systemctl", "reboot"]);
    assert.deepStrictEqual(plain(P.commandFor("off", COMMANDS)), ["systemctl", "poweroff"]);
    assert.equal(P.commandFor("lock", COMMANDS), null);
    assert.equal(P.commandFor("nope", COMMANDS), null);
});

test("commandFor: a missing or empty override yields no command", () => {
    assert.equal(P.commandFor("off", {}), null);
    assert.equal(P.commandFor("off", { poweroff: [] }), null);
    assert.equal(P.commandFor("off", null), null);
});

test("shouldExecute: only an explicit false runs anything", () => {
    assert.equal(P.shouldExecute(false), true);
    assert.equal(P.shouldExecute(true), false);
    assert.equal(P.shouldExecute(undefined), false);
    assert.equal(P.shouldExecute("0"), false);
});

test("plan: test mode never executes and never asks for the lock", () => {
    for (const kind of ["lock", "sleep", "logout", "reboot", "off", "nope"]) {
        const p = P.plan(kind, COMMANDS, true);
        assert.equal(p.execute, false, kind);
        assert.equal(p.lock, false, kind);
        assert.equal(p.argv, null, kind);
    }
    assert.match(P.plan("off", COMMANDS, true).message, /test mode.*would run: systemctl poweroff/);
    assert.match(P.plan("lock", COMMANDS, true).message, /test mode.*would request the session lock/);
});

test("plan: outside test mode a button runs its command, lock requests the lock", () => {
    assert.deepStrictEqual(plain(P.plan("reboot", COMMANDS, false)), {
        execute: true, lock: false, argv: ["systemctl", "reboot"], message: "power: running systemctl reboot"
    });
    const lock = plain(P.plan("lock", COMMANDS, false));
    assert.equal(lock.execute, true);
    assert.equal(lock.lock, true);
    assert.equal(lock.argv, null);
});

test("plan: an unknown button or a missing command executes nothing, even outside test mode", () => {
    assert.equal(P.plan("nope", COMMANDS, false).execute, false);
    assert.equal(P.plan("off", {}, false).execute, false);
    assert.equal(P.plan("off", COMMANDS, undefined).execute, false);
});

test("step: arrows move the focus and stop at both ends", () => {
    assert.equal(P.step(0, 1, 5), 1);
    assert.equal(P.step(4, 1, 5), 4);
    assert.equal(P.step(0, -1, 5), 0);
    assert.equal(P.step(3, -1, 5), 2);
});

// ---- The hold and keyboard state machine (lib/power.js reduce): what Power.qml dispatches to ----

const K = plain(P.KEYS);
const down = (code, extra = {}) => ({ type: "keyDown", code, repeat: false, chord: false, ...extra });
const up = (code, extra = {}) => ({ type: "keyUp", code, repeat: false, ...extra });
const mouseDown = kind => ({ type: "pointerPress", kind });
const mouseUp = kind => ({ type: "pointerRelease", kind });
const click = kind => ({ type: "pointerClick", kind });
const TIMER = { type: "timerElapsed" };
const NO = { type: "none", kind: "" };

// Feeds `events` one after another; returns every result and the last one's state.
function run(events, from = P.initial()) {
    let state = from;
    const results = [];
    for (const ev of events) {
        const r = plain(P.reduce(state, ev));
        results.push(r);
        state = r.state;
    }
    return { results, state, effects: results.map(r => r.effect), last: results[results.length - 1] };
}

// The keyboard parked on Wyloguj / Wyłącz (the arrows are tested on their own below).
const onLogout = () => run([down(K.right), down(K.right)]).state;
const onOff = () => run([down(K.right), down(K.right), down(K.right), down(K.right)]).state;

test("reduce: the key map holds the Qt key codes of the arrows, Enter and L S O R P", () => {
    assert.deepEqual(K, { left: 0x01000012, right: 0x01000014, return: 0x01000004, enter: 0x01000005, l: 0x4c, s: 0x53, o: 0x4f, r: 0x52, p: 0x50 });
});

test("reduce: arrows move the focus, show the focus ring and stop at both ends", () => {
    const r = run([down(K.right), down(K.right)]);
    assert.equal(r.state.focused, 2);
    assert.equal(r.state.keyboard, true);
    assert.equal(r.last.handled, true);
    assert.equal(run([down(K.left)]).state.focused, 0);
    assert.equal(run([down(K.right), down(K.right), down(K.right), down(K.right), down(K.right)]).state.focused, 4);
});

test("reduce: Enter on a hold button starts the hold, Enter up cancels it", () => {
    const r = run([down(K.return), up(K.return)], onLogout());
    assert.deepEqual(r.effects, [{ type: "start", kind: "logout" }, { type: "cancel", kind: "logout" }]);
    assert.equal(r.state.holding, "");
});

test("reduce: Enter and the keypad Enter are the same key", () => {
    const r = run([down(K.return), up(K.enter)], onLogout());
    assert.deepEqual(r.effects, [{ type: "start", kind: "logout" }, { type: "cancel", kind: "logout" }]);
});

test("reduce: Enter on Zablokuj / Uśpij acts at once and starts no hold", () => {
    assert.deepEqual(run([down(K.return)]).last.effect, { type: "finish", kind: "lock" });
    assert.deepEqual(run([down(K.return)], run([down(K.right)]).state).last.effect, { type: "finish", kind: "sleep" });
    assert.equal(run([down(K.return)]).state.holding, "");
});

test("reduce: a letter focuses its button and presses it, hold letters start a hold", () => {
    const r = run([down(K.p)]);
    assert.deepEqual(r.last.effect, { type: "start", kind: "off" });
    assert.equal(r.state.focused, 4);
    assert.equal(r.state.keyboard, true);
    assert.deepEqual(run([down(K.l)]).last.effect, { type: "finish", kind: "lock" });
    assert.deepEqual(run([down(K.s)]).last.effect, { type: "finish", kind: "sleep" });
    assert.deepEqual(run([down(K.o)]).last.effect, { type: "start", kind: "logout" });
    assert.deepEqual(run([down(K.r)]).last.effect, { type: "start", kind: "reboot" });
});

test("reduce: letter up cancels the hold that letter started", () => {
    const r = run([down(K.p), up(K.p)]);
    assert.deepEqual(r.effects, [{ type: "start", kind: "off" }, { type: "cancel", kind: "off" }]);
    assert.equal(r.state.holding, "");
});

test("reduce: Enter, Right, Enter up: the arrow ends the hold and nothing is left to finish", () => {
    const r = run([down(K.return), down(K.right), up(K.return), TIMER], onLogout());
    assert.deepEqual(r.effects, [{ type: "start", kind: "logout" }, { type: "cancel", kind: "logout" }, NO, NO]);
    assert.equal(r.state.holding, "");
    assert.equal(r.state.focused, 3);
});

test("reduce: a letter during an Enter hold does not take the hold over", () => {
    const r = run([down(K.return), down(K.p), TIMER], onLogout());
    assert.deepEqual(r.effects[0], { type: "start", kind: "logout" });
    assert.deepEqual(r.effects[1], NO);
    assert.equal(r.results[1].state.holding, "logout");
    assert.equal(r.results[1].state.focused, 2);
    // the Enter hold is still running and still belongs to Enter: it finishes Wyloguj, never Wyłącz
    assert.deepEqual(r.effects[2], { type: "finish", kind: "logout" });
    // ... and Enter up cancels it
    assert.deepEqual(run([down(K.return), down(K.p), up(K.return)], onLogout()).last.effect, { type: "cancel", kind: "logout" });
});

// AltGr (ISO_Level3_Shift) is in constant use on the pl layout and changes the key code of the key's release:
// P up arrives as Key_THORN (0xde), O up as oacute (0xd3), R up as copyright (0xa9). No key code can be trusted
// to match the press, so any key release ends a hold (fail-safe: it costs the user a re-press).
const CONTROL = 0x01000021;
const SHIFT = 0x01000020;
const ALTGR = 0x01001103;

test("reduce: a modifier press during a key hold starts nothing and cancels nothing", () => {
    const r = run([down(K.p), down(CONTROL), down(SHIFT), down(ALTGR), TIMER]);
    assert.deepEqual(r.effects, [{ type: "start", kind: "off" }, NO, NO, NO, { type: "finish", kind: "off" }]);
    assert.equal(r.results[3].state.holding, "off");
});

test("reduce: P down, AltGr down, P up as THORN: the hold is cancelled and the timer finds nothing", () => {
    const r = run([down(K.p), down(ALTGR), up(0xde), TIMER]);
    assert.deepEqual(r.effects, [{ type: "start", kind: "off" }, NO, { type: "cancel", kind: "off" }, NO]);
    assert.equal(r.state.holding, "");
});

test("reduce: O and R holds are cancelled the same way when AltGr changes their release code", () => {
    assert.deepEqual(run([down(K.o), down(ALTGR), up(0xd3), TIMER]).effects.map(e => e.type), ["start", "none", "cancel", "none"]);
    assert.deepEqual(run([down(K.r), down(ALTGR), up(0xa9), TIMER]).effects.map(e => e.type), ["start", "none", "cancel", "none"]);
});

test("reduce: a letter up with a modifier in between still cancels", () => {
    const r = run([down(K.p), down(CONTROL), up(K.p), TIMER]);
    assert.deepEqual(r.effects, [{ type: "start", kind: "off" }, NO, { type: "cancel", kind: "off" }, NO]);
    assert.equal(r.state.holding, "");
});

test("reduce: any key release cancels a running hold, a modifier's or an unknown code's included", () => {
    for (const code of [K.o, K.return, SHIFT, CONTROL, ALTGR, 0x58, 0x01000000, 0])
        assert.deepEqual(run([down(K.p), up(code), TIMER]).effects, [{ type: "start", kind: "off" }, { type: "cancel", kind: "off" }, NO], String(code));
});

test("reduce: an Enter hold is cancelled by a modifier chord pressed and released meanwhile", () => {
    const r = run([down(K.return), down(SHIFT), up(SHIFT), TIMER], onLogout());
    assert.deepEqual(r.effects, [{ type: "start", kind: "logout" }, NO, { type: "cancel", kind: "logout" }, NO]);
});

test("reduce: a key release during a pointer hold cancels it too (the safe side)", () => {
    const r = run([mouseDown("off"), up(SHIFT), TIMER]);
    assert.deepEqual(r.effects, [{ type: "start", kind: "off" }, { type: "cancel", kind: "off" }, NO]);
    assert.equal(r.state.holding, "");
});

test("reduce: a key release without a hold changes nothing and is not handled", () => {
    const idle = run([down(K.right)]).state;
    assert.deepEqual(run([up(K.p), up(ALTGR), up(0)], idle).results.map(r => [r.effect, r.handled]), [[NO, false], [NO, false], [NO, false]]);
});

test("reduce: Ctrl/Alt/Meta + letter or Enter is a chord, not a press", () => {
    const r = run([down(K.p, { chord: true })]);
    assert.deepEqual(r.last, { state: plain(P.initial()), effect: NO, handled: false });
    assert.equal(run([down(K.return, { chord: true })]).last.handled, false);
});

test("reduce: mouse press then Enter on the same button: Enter down neither restarts nor cancels the pointer's hold", () => {
    const r = run([mouseDown("off"), down(K.return), up(K.return), TIMER], onOff());
    assert.deepEqual(r.effects[0], { type: "start", kind: "off" });
    assert.deepEqual(r.effects[1], NO);
    // Enter's release is a key release: like any, it ends the hold (see the AltGr tests below)
    assert.deepEqual(r.effects[2], { type: "cancel", kind: "off" });
    assert.deepEqual(r.effects[3], NO);
    // without that release the pointer hold runs on and its own release ends it
    assert.deepEqual(run([mouseDown("off"), down(K.return), TIMER], onOff()).last.effect, { type: "finish", kind: "off" });
    assert.deepEqual(run([mouseDown("off"), down(K.return), mouseUp("off")], onOff()).last.effect, { type: "cancel", kind: "off" });
});

test("reduce: a pointer release or exit does not end a hold the keyboard started", () => {
    const r = run([down(K.return), mouseUp("off"), mouseUp("logout")], onLogout());
    assert.deepEqual(r.effects, [{ type: "start", kind: "logout" }, NO, NO]);
    assert.equal(r.state.holding, "logout");
});

test("reduce: pointer release of another button leaves the pointer hold alone; its own release cancels it", () => {
    const r = run([mouseDown("off"), mouseUp("reboot"), mouseUp("off")]);
    assert.deepEqual(r.effects, [{ type: "start", kind: "off" }, NO, { type: "cancel", kind: "off" }]);
});

test("reduce: pointer press shows no focus ring; hold buttons start, the others wait for the click", () => {
    const from = run([down(K.right)]).state;
    const r = run([mouseDown("sleep"), click("sleep")], from);
    assert.equal(r.results[0].state.keyboard, false);
    assert.deepEqual(r.effects, [NO, { type: "finish", kind: "sleep" }]);
    assert.deepEqual(run([click("off")]).last.effect, NO);
});

test("reduce: a press while another hold runs is ignored", () => {
    const r = run([mouseDown("off"), mouseDown("reboot"), click("sleep"), down(K.o)]);
    assert.deepEqual(r.effects, [{ type: "start", kind: "off" }, NO, NO, NO]);
    assert.equal(r.state.holding, "off");
});

test("reduce: the layer going inactive mid-hold cancels it and resets the keyboard", () => {
    const held = run([down(K.right), down(K.p)]).state;
    const r = run([{ type: "active", on: false }, TIMER], held);
    assert.deepEqual(r.effects, [{ type: "cancel", kind: "off" }, NO]);
    assert.deepEqual(r.state, plain(P.initial()));
    // and becoming active starts from the same clean state
    assert.deepEqual(run([{ type: "active", on: true }], held).last.state, plain(P.initial()));
});

test("reduce: losing the keyboard focus mid-hold cancels it; without a hold it changes nothing", () => {
    assert.deepEqual(run([down(K.p), { type: "focusLost" }]).effects, [{ type: "start", kind: "off" }, { type: "cancel", kind: "off" }]);
    assert.deepEqual(run([mouseDown("off"), { type: "focusLost" }]).last.effect, { type: "cancel", kind: "off" });
    const idle = run([down(K.right)]).state;
    assert.deepEqual(run([{ type: "focusLost" }], idle).last, { state: idle, effect: NO, handled: false });
});

test("reduce: the hold timer finishes only a hold that is still on; a stray tick after a cancel does nothing", () => {
    assert.deepEqual(run([down(K.p), TIMER]).effects, [{ type: "start", kind: "off" }, { type: "finish", kind: "off" }]);
    assert.equal(run([down(K.p), TIMER]).state.holding, "");
    assert.deepEqual(run([down(K.p), up(K.p), TIMER]).last.effect, NO);
    assert.deepEqual(run([mouseDown("off"), mouseUp("off"), TIMER]).last.effect, NO);
    assert.deepEqual(run([TIMER]).last.effect, NO);
    // a second tick after the finish does nothing either
    assert.deepEqual(run([down(K.p), TIMER, TIMER]).last.effect, NO);
});

test("reduce: key auto-repeat changes nothing, down or up", () => {
    const r = run([down(K.p), down(K.p, { repeat: true }), up(K.p, { repeat: true }), down(K.right, { repeat: true })]);
    assert.deepEqual(r.effects, [{ type: "start", kind: "off" }, NO, NO, NO]);
    assert.equal(r.state.holding, "off");
    assert.equal(r.results[1].handled, true);
});

test("reduce: keys that are no button are not handled", () => {
    assert.equal(run([down(0x58)]).last.handled, false);
    assert.equal(run([down(0x01000000)]).last.handled, false);
});

test("reduce: never mutates the state it is given", () => {
    const before = JSON.stringify(P.initial());
    const s = P.initial();
    P.reduce(s, down(K.p));
    assert.equal(JSON.stringify(s), before);
});

// ---- Source guard: components/PowerActions.qml perform() is the ONE place that runs a power command or asks for the lock ----
// The menu (states/Power.qml) and, later, the lock screen instantiate PowerActions and call perform(); no
// other QML may read Theme.tokens.power.commands, start a process or emit the lock request.

const GATE = "components/PowerActions.qml";

const sources = qmlFiles().map(f => ({ rel: relative(root, f), code: strip(readFileSync(f, "utf8")) }));
const gate = sources.find(s => s.rel === GATE);

// Everything that runs something, reads the power commands or reaches the session lock.
const DANGEROUS = [
    ["execDetached", /\bexecDetached\b/g],
    ["Process", /\bProcess\s*\{/g],
    ["systemctl", /\bsystemctl\b/g],
    ["loginctl", /\bloginctl\b/g],
    ["quit", /\bquit\b/gi],
    ["Socket", /\bSocket(Server)?\b/g],
    ["openUrlExternally", /\bopenUrlExternally\b/g],
    ["power words", /\b(poweroff|reboot|suspend|hibernate|halt)\b/g],
    ["power commands", /\btokens\s*(\.|\[\s*["'`])\s*power\b|\bpower\s*\.\s*commands\b|\bcommands\s*\.\s*(suspend|logout|reboot|poweroff)\b/g],
    ["lockRequested()", /(?<!signal )\blockRequested\s*\(/g]
];

// The other places that start a process. Each runs something that is not a power command; a new site, or
// any of these touching systemctl / loginctl / quit / the power commands / the lock, fails the guard.
// (menus/*.sh are shell scripts, not QML: they are not scanned.)
const ALLOWED = {
    // brightnessctl: set and read the backlight
    "services/Brightness.qml": ["execDetached", "Process"],
    // niri msg: focus a window, and the event stream
    "services/Niri.qml": ["execDetached", "Process"],
    // the launcher's own perform(): copy, run a typed command, run a menu command; the menus' Process
    "states/Launcher.qml": ["execDetached", "Process"]
};

test("guard: the gate exists with a perform() function", () => {
    assert.ok(existsSync(join(root, GATE)));
    assert.ok(gate && functionSpan(gate.code, "perform"), `no perform() in ${GATE}`);
});

test("guard: every process start, power command read and lock request in the tree is the gate's perform() or allowlisted", () => {
    const span = functionSpan(gate.code, "perform");
    const offenders = [];
    for (const s of sources)
        for (const [name, re] of DANGEROUS)
            for (const m of s.code.matchAll(re)) {
                const inGate = s.rel === GATE && m.index >= span.start && m.index < span.end;
                if (!inGate && !(ALLOWED[s.rel] ?? []).includes(name)) offenders.push(`${s.rel}: ${name} (${m[0]}) at ${m.index}`);
            }
    assert.deepEqual(offenders, []);
});

test("guard: the allowlist only excuses starting a process, and every entry is still true", () => {
    for (const [rel, tokens] of Object.entries(ALLOWED)) {
        const s = sources.find(x => x.rel === rel);
        assert.ok(s, `${rel} is allowlisted but gone`);
        for (const t of tokens) {
            assert.ok(["execDetached", "Process"].includes(t), `${rel}: ${t} must never be allowlisted`);
            assert.match(s.code, new RegExp(DANGEROUS.find(d => d[0] === t)[1].source), `${rel} no longer uses ${t}: drop it from the allowlist`);
        }
    }
});

test("guard: the DANGEROUS list catches each spelling it claims to (quit in any case, Socket, openUrlExternally)", () => {
    const caught = code => DANGEROUS.filter(([, re]) => new RegExp(re.source, re.flags).test(code)).map(d => d[0]);
    for (const [code, name] of [["Qt.quit()", "quit"], ["Qt.QUIT()", "quit"], ["Quit()", "quit"], ["Socket { }", "Socket"], ["SocketServer { }", "Socket"],
        ["Qt.openUrlExternally(u)", "openUrlExternally"], ["execDetached(x)", "execDetached"], ["Process { }", "Process"]])
        assert.ok(caught(code).includes(name), `${name} not caught in: ${code}`);
});

// lib/*.js is plain JS that QML calls: it must not start a process, open a socket or a URL either. Only the files that
// hold the power commands as DATA (lib/theme.js defaults, lib/power.js item table) may spell power words; the
// QML-only process / lock entries are never excused here.
const LIB_ALLOWED = {
    "lib/theme.js": ["systemctl", "quit", "power words"],
    "lib/power.js": ["power words"]
};
const libSources = jsFiles().map(f => ({ rel: relative(root, f), code: strip(readFileSync(f, "utf8")) }));

const scanLib = (srcs, allowed) => srcs.flatMap(s => DANGEROUS.flatMap(([name, re]) =>
    (allowed[s.rel] ?? []).includes(name) ? [] : [...s.code.matchAll(re)].map(m => `${s.rel}: ${name} (${m[0]})`)));

test("guard: lib/*.js starts no process, opens no socket or URL and never reaches the lock or the power commands", () => {
    assert.ok(libSources.length > 10, "lib/*.js not found");
    assert.deepEqual(scanLib(libSources, LIB_ALLOWED), []);
});

test("guard: the lib scan finds a planted offender, and the lib allowlist is only power words, each still true", () => {
    assert.ok(scanLib(libSources, {}).some(o => o.startsWith("lib/theme.js")), "without the allowlist the data files are flagged: the scan is real");
    assert.deepEqual(scanLib([{ rel: "lib/x.js", code: "function f() { Qt.openUrlExternally(u); }" }], {}), ["lib/x.js: openUrlExternally (openUrlExternally)"]);
    for (const [rel, names] of Object.entries(LIB_ALLOWED)) {
        const s = libSources.find(x => x.rel === rel);
        assert.ok(s, `${rel} is allowlisted but gone`);
        for (const n of names) {
            assert.ok(["systemctl", "quit", "power words"].includes(n), `${rel}: ${n} must never be allowlisted in lib`);
            const re = DANGEROUS.find(d => d[0] === n)[1];
            assert.match(s.code, new RegExp(re.source, re.flags.replace("g", "")), `${rel} no longer spells ${n}: drop it from the allowlist`);
        }
    }
});

test("guard: perform() decides through P.plan with the gate's own testMode and returns before anything runs", () => {
    const span = functionSpan(gate.code, "perform");
    const body = gate.code.slice(span.start, span.end);
    const plan = body.search(/P\.plan\(\s*kind\s*,\s*Theme\.tokens\.power\.commands\s*,\s*root\.testMode\s*\)/);
    const bail = body.search(/if\s*\(\s*!\s*p\.execute\s*\)\s*return\b/);
    const exec = body.search(/\bexecDetached\b/);
    const lock = body.search(/(?<!signal )\blockRequested\s*\(/);
    assert.ok(plan >= 0, "perform() does not call P.plan(kind, Theme.tokens.power.commands, root.testMode)");
    assert.ok(bail > plan, "perform() must return on !p.execute right after planning");
    assert.ok(exec > bail && lock > bail, "perform() must run / lock only after the !p.execute return");
    assert.equal((body.match(/\bexecDetached\b/g) ?? []).length, 1);
    assert.equal((body.match(/(?<!signal )\blockRequested\s*\(/g) ?? []).length, 1);
});

test("guard: the gate's testMode is read-only and bound to WYSPA_TEST === 1, and is declared once", () => {
    assert.match(gate.code, /readonly\s+property\s+bool\s+testMode\s*:\s*Quickshell\.env\(\s*(["'])WYSPA_TEST\1\s*\)\s*===\s*(["'])1\2\s*(\n|;|$)/);
    assert.equal((gate.code.match(/\btestMode\s*:/g) ?? []).length, 1);
});

test("guard: Power.qml gets its actions from the gate and only calls perform() on it", () => {
    const power = sources.find(s => s.rel === "states/Power.qml");
    assert.match(power.code, /\bPowerActions\s*\{/);
    assert.match(power.code, /\bactions\.perform\(/);
    assert.deepEqual([...power.code.matchAll(/(\w+)\.perform\(/g)].map(m => m[1]), ["actions"]);
    assert.doesNotMatch(power.code, /function\s+perform\b/);
});

test("guard: no QML spells a real power command, in either quote style (they live in lib/theme.js)", () => {
    const offenders = sources
        .filter(s => /systemctl\s+(suspend|reboot|poweroff)|["'`](suspend|reboot|poweroff|quit|halt|hibernate)["'`]|action\s+quit/.test(s.code))
        .map(s => s.rel);
    assert.deepEqual(offenders, []);
});

test("guard: lockRequested() is called nowhere but the gate", () => {
    const callers = sources.filter(s => /\.lockRequested\s*\(/.test(s.code)).map(s => s.rel);
    assert.deepEqual(callers, [GATE]);
});

test("guard: the lock screen gets its Uśpij / Wyłącz from the gate and only calls perform() on it", () => {
    const lock = sources.find(s => s.rel === "Lock.qml");
    assert.ok(lock, "Lock.qml missing");
    assert.match(lock.code, /\bPowerActions\s*\{/);
    assert.deepEqual([...new Set([...lock.code.matchAll(/(\w+)\.perform\(/g)].map(m => m[1]))], ["actions"]);
    assert.doesNotMatch(lock.code, /function\s+perform\b/);
});

test("guard: the only QML that mentions PowerActions (instantiates it, so calls perform() on it) is the power menu and the lock screen", () => {
    // The power menu (states/Power.qml) and the lock screen's corner buttons (Lock.qml, Task 19) both go through
    // the gate; any other user is a new way to the machine's power and must be added here on purpose.
    const users = sources.filter(s => s.rel !== GATE && /\bPowerActions\b/.test(s.code)).map(s => s.rel).sort();
    assert.deepEqual(users, ["Lock.qml", "states/Power.qml"]);
});
