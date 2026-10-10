import { test } from "node:test";
import assert from "node:assert/strict";
import { readdirSync, readFileSync, existsSync } from "node:fs";
import { join, dirname, relative } from "node:path";
import { fileURLToPath } from "node:url";
import { load, plain } from "./qmljs.mjs";

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

test("kindForKey: L S O R P in either case, anything else is no button", () => {
    assert.deepStrictEqual(["l", "S", "o", "R", "p"].map(P.kindForKey), ["lock", "sleep", "logout", "reboot", "off"]);
    assert.equal(P.kindForKey("x"), "");
    assert.equal(P.kindForKey(""), "");
    assert.equal(P.kindForKey("lo"), "");
});

test("step: arrows move the focus and stop at both ends", () => {
    assert.equal(P.step(0, 1, 5), 1);
    assert.equal(P.step(4, 1, 5), 4);
    assert.equal(P.step(0, -1, 5), 0);
    assert.equal(P.step(3, -1, 5), 2);
});

// ---- Source guard: every power command and the lock request go through the one perform() of Power.qml ----

const strip = src => src.replace(/\/\*[\s\S]*?\*\//g, "").replace(/\/\/.*$/gm, "");

function qmlFiles(dir = root) {
    const out = [];
    for (const e of readdirSync(dir, { withFileTypes: true })) {
        if (e.isDirectory()) {
            if (dir === root && (e.name === "docs" || e.name === "tests")) continue;
            out.push(...qmlFiles(join(dir, e.name)));
        } else if (e.name.endsWith(".qml")) {
            out.push(join(dir, e.name));
        }
    }
    return out;
}

const sources = qmlFiles().map(f => ({ rel: relative(root, f), code: strip(readFileSync(f, "utf8")) }));
const DANGEROUS = /\bexecDetached\b|\bProcess\s*\{|\bsystemctl\b|\bquit\b|\bloginctl\b|(?<!signal )\blockRequested\s*\(/g;

// The span of the first `function <name>(…) { … }`.
function functionSpan(code, name) {
    const start = code.search(new RegExp(`function\\s+${name}\\s*\\(`));
    if (start < 0) return null;
    const open = code.indexOf("{", start);
    let depth = 0;
    for (let i = open; i < code.length; i++) {
        if (code[i] === "{") depth++;
        else if (code[i] === "}" && --depth === 0) return { start, end: i + 1 };
    }
    return null;
}

test("guard: states/Power.qml exists and has a perform() function", () => {
    assert.ok(existsSync(join(root, "states/Power.qml")));
    const power = sources.find(s => s.rel === "states/Power.qml");
    assert.ok(functionSpan(power.code, "perform"), "no perform() in Power.qml");
});

test("guard: in power files, execDetached/Process/systemctl/quit/loginctl/lockRequested() occur only inside perform()", () => {
    const powerFiles = sources.filter(s => /power/i.test(s.rel) || s.rel === "IslandState.qml");
    assert.ok(powerFiles.some(s => s.rel === "states/Power.qml"));
    const offenders = [];
    for (const s of powerFiles) {
        const span = functionSpan(s.code, "perform");
        for (const m of s.code.matchAll(DANGEROUS)) {
            const inside = s.rel === "states/Power.qml" && span && m.index >= span.start && m.index < span.end;
            if (!inside) offenders.push(`${s.rel}: ${m[0]} at ${m.index}`);
        }
    }
    assert.deepEqual(offenders, []);
});

test("guard: Power.qml perform() is the only place that reads the commands and runs one", () => {
    const power = sources.find(s => s.rel === "states/Power.qml");
    const span = functionSpan(power.code, "perform");
    const outside = power.code.slice(0, span.start) + power.code.slice(span.end);
    assert.doesNotMatch(outside, /tokens\.power|commands/);
    assert.equal((power.code.match(/\bexecDetached\b/g) ?? []).length, 1);
    assert.doesNotMatch(power.code, /\bProcess\b/);
});

test("guard: no QML spells a real power command (they live in lib/theme.js)", () => {
    const offenders = sources
        .filter(s => /systemctl\s+(suspend|reboot|poweroff)|"(suspend|reboot|poweroff|quit)"|action\s+quit/.test(s.code))
        .map(s => s.rel);
    assert.deepEqual(offenders, []);
});

test("guard: lockRequested() is called nowhere but perform() of Power.qml", () => {
    const callers = sources.filter(s => /\.lockRequested\s*\(/.test(s.code)).map(s => s.rel);
    assert.deepEqual(callers, ["states/Power.qml"]);
});
