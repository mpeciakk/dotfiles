import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { load, plain, strip } from "./qmljs.mjs";

const N = load("lib/notifs.js");
const L = load("lib/theme.js").defaults.layout.center;
const it = (id, appName) => ({ id, appName, summary: "s" + id });

test("group(): groups by app, newest group first, items newest first", () => {
    const g = plain(N.group([it(5, "a"), it(4, "b"), it(3, "a"), it(2, "c"), it(1, "b")]));
    assert.deepStrictEqual(g.map(x => x.app), ["a", "b", "c"]);
    assert.deepStrictEqual(g[0].items.map(x => x.id), [5, 3]);
    assert.deepStrictEqual(g[1].items.map(x => x.id), [4, 1]);
});

test("group(): empty", () => {
    assert.deepStrictEqual(plain(N.group([])), []);
});

test("appColor(): stable and within the palette", () => {
    const cols = ["#1", "#2", "#3", "#4"];
    assert.equal(N.appColor("firefox", cols), N.appColor("firefox", cols));
    assert.ok(cols.includes(N.appColor("firefox", cols)));
    assert.ok(cols.includes(N.appColor("", cols)));
});

test("initial()", () => {
    assert.equal(N.initial("firefox"), "F");
    assert.equal(N.initial(""), "?");
});

// Reference 3.5 / R28: count == 0 -> hMin (170); else
//   min(620, 14 + 36 + 10 + listH + 16) = min(620, 76 + listH)
//   listH = sum(28 + shown*64 + (shown-1)*6 + stackPad) + 12*(groups-1)
// (a) no groups: 170
// (b) one group of 3, collapsed: shown = 1, stackPad = 14 (collapsed, n > 2)
//     listH = 28 + 64 + 0 + 14 = 106;  76 + 106 = 182
// (c) same group expanded: shown = 3, stackPad = 0
//     listH = 28 + 192 + 12 + 0 = 232;  76 + 232 = 308
test("centerHeight(): empty, collapsed group of 3, expanded group of 3", () => {
    const three = N.group([it(3, "a"), it(2, "a"), it(1, "a")]);
    assert.equal(N.centerHeight(N.group([]), {}, L), 170);
    assert.equal(N.centerHeight(three, {}, L), 182);
    assert.equal(N.centerHeight(three, { a: true }, L), 308);
});

test("iconSource(): image wins, then an absolute or image:// appIcon, then the theme icon, else empty", () => {
    const theme = name => (name === "firefox" ? "/icons/firefox.png" : "");
    assert.equal(N.iconSource({ image: "image://qsimage/1", appIcon: "firefox" }, theme), "image://qsimage/1");
    assert.equal(N.iconSource({ image: "", appIcon: "/tmp/a.png" }, theme), "/tmp/a.png");
    assert.equal(N.iconSource({ image: "", appIcon: "image://qsimage/2" }, theme), "image://qsimage/2");
    assert.equal(N.iconSource({ image: "", appIcon: "file:///tmp/a.png" }, theme), "file:///tmp/a.png");
    assert.equal(N.iconSource({ image: "", appIcon: "firefox" }, theme), "/icons/firefox.png");
    assert.equal(N.iconSource({ image: "", appIcon: "nope" }, theme), "");
    assert.equal(N.iconSource({ image: "", appIcon: "" }, theme), "");
});

// Replace / removal / cap (D4): the history holds one snapshot per id, newest first.
test("replaceById(): the snapshot goes to the top, the others keep their order, a new id is just prepended", () => {
    const h = [it(5, "a"), it(4, "b"), it(3, "c")];
    const upd = { id: 3, appName: "c", summary: "new" };
    assert.deepStrictEqual(plain(N.replaceById(h, upd)).map(x => x.id), [3, 5, 4]);
    assert.equal(N.replaceById(h, upd)[0].summary, "new");
    assert.deepStrictEqual(plain(N.replaceById(h, it(9, "d"))).map(x => x.id), [9, 5, 4, 3]);
    assert.deepStrictEqual(h.map(x => x.id), [5, 4, 3], "the input is not mutated");
});

test("removeById(): drops that id only; an unknown id changes nothing", () => {
    const h = [it(5, "a"), it(4, "b"), it(3, "c")];
    assert.deepStrictEqual(plain(N.removeById(h, 4)).map(x => x.id), [5, 3]);
    assert.deepStrictEqual(plain(N.removeById(h, 99)).map(x => x.id), [5, 4, 3]);
});

test("cap(): keeps the newest `max` and names the ids that fell out", () => {
    const h = [it(5, "a"), it(4, "a"), it(3, "a"), it(2, "a"), it(1, "a")];
    const c = plain(N.cap(h, 3));
    assert.deepStrictEqual(c.kept.map(x => x.id), [5, 4, 3]);
    assert.deepStrictEqual(c.dropped, [2, 1]);
    const under = plain(N.cap(h, 9));
    assert.deepStrictEqual(under.kept.map(x => x.id), [5, 4, 3, 2, 1]);
    assert.deepStrictEqual(under.dropped, []);
});

test("clampUnread(): never above the history length, never below zero", () => {
    assert.equal(N.clampUnread(3, 5), 3);
    assert.equal(N.clampUnread(7, 5), 5);
    assert.equal(N.clampUnread(2, 0), 0);
    assert.equal(N.clampUnread(-1, 5), 0);
});

test("a push, a replace and a removal never leave unread above the history length", () => {
    let h = [];
    let unread = 0;
    for (const id of [1, 2, 3]) { h = N.replaceById(h, it(id, "a")); unread = N.clampUnread(unread + 1, h.length); }
    h = N.replaceById(h, it(2, "a"));
    unread = N.clampUnread(unread, h.length);
    assert.deepStrictEqual([h.length, unread], [3, 3]);
    h = N.removeById(N.removeById(h, 1), 3);
    unread = N.clampUnread(unread, h.length);
    assert.deepStrictEqual([h.length, unread], [1, 1]);
});

// Every island window keeps a Toast layer mounted, hidden when not lit. A bar run there renders the window at full
// rate for toastBarMs on every arrival (DND, other screens) with nothing on screen: only the shown toast runs it.
test("Toast.qml: the bar runs only while the toast is active", () => {
    const src = strip(readFileSync(join(dirname(fileURLToPath(import.meta.url)), "..", "states/Toast.qml"), "utf8"));
    assert.match(src, /function onArrived\(\): void \{\s*if \(root\.active\)\s*root\.restartBar\(\);\s*\}/);
    assert.match(src, /onActiveChanged: \{\s*if \(root\.active\)\s*root\.restartBar\(\);\s*else\s*barRun\.stop\(\);\s*\}/);
});

// Notifs.qml talks to the D-Bus server, which node cannot run; the protocol rules are pinned on its source and
// proven on a private session bus by tests/smoke/22-notifs-dbus.sh.
const notifsSrc = strip(readFileSync(join(dirname(fileURLToPath(import.meta.url)), "..", "services/Notifs.qml"), "utf8"));
const body = name => {
    const at = notifsSrc.search(new RegExp(`function ${name}\\(`));
    return notifsSrc.slice(at, notifsSrc.indexOf("\n    }\n", at));
};

test("Notifs.qml: a close by the app removes the card and never calls dismiss() back on that object", () => {
    assert.doesNotMatch(body("forget"), /dismiss\(/);
    assert.match(notifsSrc, /notif\.closed\.connect\(\(\) => root\.forget\(notif\.id\)\)/);
});

test("Notifs.qml: our own dismiss() is not handled again as a close by the app", () => {
    // release() forgets the object before dismiss(), whose `closed` would otherwise edit the history mid-edit.
    const release = body("release");
    assert.ok(release.indexOf("delete root.tracked[id]") < release.indexOf("notif.dismiss()"));
    assert.match(body("forget"), /if \(!\(id in root\.tracked\)\)\s*return;/);
});

test("Notifs.qml: a transient notification is announced and never tracked or stored", () => {
    const handler = notifsSrc.slice(notifsSrc.indexOf("onNotification:"), notifsSrc.indexOf("IpcHandler"));
    const transient = handler.slice(handler.indexOf("if (notif.transient)"), handler.indexOf("notif.tracked = true"));
    assert.match(transient, /root\.announce\(snap\);\s*return;/);
    assert.doesNotMatch(transient, /push\(|history/);
});

test("Notifs.qml: every card the user or the cap removes goes through release(), which dismisses the object", () => {
    for (const fn of ["dismiss", "dismissApp", "clearAll", "push"])
        assert.match(body(fn), /root\.release\(/, fn);
});
