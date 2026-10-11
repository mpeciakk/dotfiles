import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { load, plain } from "./qmljs.mjs";

const L = load("lib/launch.js");
const root = join(dirname(fileURLToPath(import.meta.url)), "..");

test("wrap(): every start goes through uwsm app", () => {
    assert.deepEqual(plain(L.wrap(["sh", "-c", "firefox"])), ["uwsm", "app", "--", "sh", "-c", "firefox"]);
    assert.deepEqual(plain(L.wrap(["wl-copy", "--", "42"])), ["uwsm", "app", "--", "wl-copy", "--", "42"]);
});

test("entryArgv(): a valid Desktop Entry ID runs as the entry (uwsm reads Terminal= and Path=)", () => {
    for (const id of ["btop", "org.gnome.Nautilus", "jshell-java25-openjdk", "_x"])
        assert.deepEqual(plain(L.entryArgv(id, ["ignored"])), ["uwsm", "app", "--", id + ".desktop"]);
});

test("entryArgv(): an ID uwsm refuses runs by its parsed command", () => {
    for (const id of ["Big Walk", "-x", ".hidden", "a/b", ""])
        assert.deepEqual(plain(L.entryArgv(id, ["steam", "steam://rungameid/1"])), ["uwsm", "app", "--", "steam", "steam://rungameid/1"]);
});

test("guard: Apps starts processes only through lib/launch.js, and the launcher only through Apps", () => {
    const apps = readFileSync(join(root, "services/Apps.qml"), "utf8").replace(/\/\/.*$/gm, "");
    const calls = [...apps.matchAll(/execDetached\(([\s\S]*?)\);/g)].map(m => m[1]);
    assert.equal(calls.length, 2);
    for (const c of calls)
        assert.match(c, /\bL\.(wrap|entryArgv)\(/);
    assert.doesNotMatch(apps, /\.execute\(\)/);
    const launcher = readFileSync(join(root, "states/Launcher.qml"), "utf8").replace(/\/\/.*$/gm, "");
    assert.doesNotMatch(launcher, /\bexecDetached\b|\.execute\(\)/);
});

test("guard: Apps.run / Apps.launch are called only from the launcher's perform() callbacks (test mode stays log-only)", () => {
    const files = ["shell.qml", "Island.qml", "IslandShape.qml", "IslandContent.qml", "IslandState.qml", "Theme.qml", "Lock.qml", "Strut.qml", "Wallpaper.qml"]
        .concat(...["states", "components", "services"].map(d => readdirSync(join(root, d)).filter(f => f.endsWith(".qml")).map(f => `${d}/${f}`)));
    const re = /\bApps\s*\.\s*(run|launch)\s*\(/g;
    const offenders = [];
    for (const rel of files) {
        let code;
        try { code = readFileSync(join(root, rel), "utf8").replace(/\/\/.*$/gm, ""); } catch { continue; }
        for (const m of code.matchAll(re)) {
            const line = code.slice(code.lastIndexOf("\n", m.index) + 1, code.indexOf("\n", m.index));
            if (rel !== "states/Launcher.qml" || !/\broot\.perform\([^]*=>\s*Apps\./.test(line)) offenders.push(`${rel}: ${line.trim()}`);
        }
    }
    assert.deepEqual(offenders, []);
    assert.ok(files.includes("states/Launcher.qml"));
});
