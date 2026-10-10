import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { load } from "./qmljs.mjs";

// polishB1: small UI fixes. The pure part is tested through lib/notifs.js; the QML parts that need a real
// pointer, keyboard, sink or a fading layer are pinned by source guards (and, where an IPC property
// shows them, by the smokes).

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const src = rel => readFileSync(join(root, rel), "utf8").replace(/\/\/.*$/gm, "");
const N = load("lib/notifs.js");
const theme = name => (name === "firefox" ? "/icons/firefox.png" : "");

test("storedSource(): keeps every image URL but image://qsimage/, which dies with its Notification", () => {
    assert.equal(N.storedSource({ image: "image://icon/firefox", appIcon: "" }, theme), "image://icon/firefox");
    assert.equal(N.storedSource({ image: "/tmp/shot.png", appIcon: "" }, theme), "/tmp/shot.png");
    assert.equal(N.storedSource({ image: "file:///tmp/shot.png", appIcon: "firefox" }, theme), "file:///tmp/shot.png");
    assert.equal(N.storedSource({ image: "image://qsimage/7", appIcon: "firefox" }, theme), "/icons/firefox.png");
    assert.equal(N.storedSource({ image: "image://qsimage/7", appIcon: "" }, theme), "");
    assert.equal(N.storedSource({ image: "", appIcon: "firefox" }, theme), "/icons/firefox.png");
});

test("guard: the centre's cards take the picture through storedSource()", () => {
    const c = src("states/Center.qml");
    assert.match(c, /N\.storedSource\(\s*\{\s*image:\s*card\.modelData\.image\b/);
    assert.doesNotMatch(c, /N\.iconSource\(/);
});

test("guard: the launcher forgets the selected label when it closes", () => {
    const l = src("states/Launcher.qml");
    const handler = l.match(/onActiveChanged:\s*\{[\s\S]*?\n    \}/)[0];
    const elseBranch = handler.slice(handler.indexOf("} else {"));
    assert.match(elseBranch, /IslandState\.launcherResult\s*=\s*""/);
});

test("guard: a rebuilt list is scrolled back to the selected row", () => {
    const l = src("states/Launcher.qml");
    assert.match(l, /ListView\s*\{[\s\S]*?onModelChanged:\s*list\.positionViewAtIndex\(\s*root\.selected,\s*ListView\.Contain\s*\)/);
});

test("guard: launcherMenu() hands the menu over only when the open is granted", () => {
    const s = src("IslandState.qml");
    const fn = s.match(/function launcherMenu\(id: string\): void \{[\s\S]*?\n        \}/)[0];
    assert.match(fn, /if\s*\(root\.request\("launcher"\)\)\s*root\.launcherMenuRequest\s*=\s*id/);
    assert.ok(fn.indexOf("request(") < fn.indexOf("launcherMenuRequest"), "request first");
});

test("guard: the launcher's description line is plain text (app_id, comments and menu sublabels are external)", () => {
    const l = src("states/Launcher.qml");
    const sub = l.match(/Text \{[^{}]*text: row\.modelData\.sub[^{}]*\}/)[0];
    assert.match(sub, /textFormat:\s*Text\.PlainText/);
});

test("guard: a menu row without a command runs nothing", () => {
    const l = src("states/Launcher.qml");
    const branch = l.match(/row\.kind === "item"\) \{[\s\S]*?\n        \}\n    \}/)[0];
    assert.match(branch, /if\s*\(\s*row\.command\s*===\s*""\s*\)\s*return;/);
    assert.ok(branch.indexOf('row.command === ""') < branch.indexOf("execDetached"));
});

test("guard: a default sink change shuts the OSD gate again, with the startup timer", () => {
    const s = src("IslandState.qml");
    assert.match(s, /Timer\s*\{\s*id:\s*osdGate\b[^}]*onTriggered:\s*root\.osdReady\s*=\s*true/);
    const audio = s.match(/target: Audio[\s\S]*?\n    \}/)[0];
    assert.match(audio, /function onSinkChanged\(\): void \{\s*root\.osdReady\s*=\s*false;\s*osdGate\.restart\(\);\s*\}/);
});

test("guard: the toast's +N chip keeps its last value while the layer fades out", () => {
    const t = src("states/Toast.qml");
    assert.match(t, /Binding\s*\{[^}]*property:\s*"shownMore"[^}]*value:\s*root\.more[^}]*when:\s*root\.more\s*>=\s*0[^}]*restoreMode:\s*Binding\.RestoreNone/);
    assert.match(t, /visible:\s*root\.shownMore\s*>\s*0/);
    assert.match(t, /text:\s*"\+"\s*\+\s*root\.shownMore/);
});

test("guard: the toast's app line has no dangling separator for an empty body", () => {
    const t = src("states/Toast.qml");
    assert.match(t, /\[root\.snap\.appName,\s*root\.snap\.body\]\.filter\([^)]*\)\.join\(" · "\)/);
    assert.doesNotMatch(t, /appName \+ " · "/);
});

test("guard: the toast's icon is decoded at its box size, synchronously", () => {
    const t = src("states/Toast.qml");
    const img = t.match(/Image \{[\s\S]*?\n            \}/)[0];
    assert.match(img, /sourceSize\.width:\s*root\.spec\.iconImage/);
    assert.match(img, /sourceSize\.height:\s*root\.spec\.iconImage/);
    assert.doesNotMatch(img, /asynchronous/);
});
