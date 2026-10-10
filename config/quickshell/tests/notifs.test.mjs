import { test } from "node:test";
import assert from "node:assert/strict";
import { load, plain } from "./qmljs.mjs";

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
