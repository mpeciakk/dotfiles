import { test } from "node:test";
import assert from "node:assert/strict";
import { load, plain } from "./qmljs.mjs";

const N = load("lib/niri.js");
const w = (id, extra = {}) => ({ id, title: "t" + id, app_id: "a", workspace_id: 1, is_focused: false, ...extra });
const ts = (secs, nanos = 0) => ({ secs, nanos });

test("WindowsChanged replaces the map", () => {
    const s = plain(N.reduceWindows({ 9: w(9) }, { WindowsChanged: { windows: [w(1), w(2)] } }));
    assert.deepStrictEqual(Object.keys(s), ["1", "2"]);
});

test("open/change, close, focus", () => {
    let s = N.reduceWindows({}, { WindowOpenedOrChanged: { window: w(1) } });
    s = N.reduceWindows(s, { WindowOpenedOrChanged: { window: w(2, { title: "x" }) } });
    s = N.reduceWindows(s, { WindowFocusChanged: { id: 2 } });
    assert.equal(s[2].is_focused, true);
    assert.equal(s[1].is_focused, false);
    s = N.reduceWindows(s, { WindowClosed: { id: 1 } });
    assert.deepStrictEqual(Object.keys(plain(s)), ["2"]);
});

test("unrelated events return the same object", () => {
    const s = { 1: w(1) };
    assert.equal(N.reduceWindows(s, { WorkspaceActivated: { id: 3 } }), s);
    assert.equal(N.reduceWindows(s, { WindowLayoutsChanged: { changes: [] } }), s);
});

test("WindowFocusChanged with a null id leaves nobody focused", () => {
    const s = { 1: w(1, { is_focused: true }), 2: w(2) };
    const r = N.reduceWindows(s, { WindowFocusChanged: { id: null } });
    assert.notEqual(r, s);
    assert.equal(r[1].is_focused, false);
    assert.equal(r[2].is_focused, false);
});

test("a focused window opened or changed unfocuses the others", () => {
    const s = { 1: w(1, { is_focused: true }) };
    const r = N.reduceWindows(s, { WindowOpenedOrChanged: { window: w(2, { is_focused: true }) } });
    assert.equal(r[1].is_focused, false);
    assert.equal(r[2].is_focused, true);
});

test("WindowFocusTimestampChanged updates one window, ignores unknown ids", () => {
    const s = { 1: w(1, { focus_timestamp: ts(5) }) };
    const r = N.reduceWindows(s, { WindowFocusTimestampChanged: { id: 1, focus_timestamp: ts(9, 1) } });
    assert.deepStrictEqual(plain(r[1].focus_timestamp), ts(9, 1));
    assert.deepStrictEqual(plain(s[1].focus_timestamp), ts(5));
    assert.equal(N.reduceWindows(s, { WindowFocusTimestampChanged: { id: 7, focus_timestamp: ts(1) } }), s);
});

test("WindowClosed of an unknown id still returns a new object, never mutates", () => {
    const s = { 1: w(1) };
    const r = N.reduceWindows(s, { WindowClosed: { id: 7 } });
    assert.notEqual(r, s);
    assert.deepStrictEqual(Object.keys(plain(s)), ["1"]);
});

test("reduceWindows never mutates its input", () => {
    const s = { 1: w(1, { is_focused: true }), 2: w(2) };
    const frozen = JSON.stringify(s);
    N.reduceWindows(s, { WindowFocusChanged: { id: 2 } });
    N.reduceWindows(s, { WindowOpenedOrChanged: { window: w(3, { is_focused: true }) } });
    N.reduceWindows(s, { WindowClosed: { id: 1 } });
    assert.equal(JSON.stringify(s), frozen);
});

test("sortWindows: newest focus first, missing/null timestamps last, ties by id", () => {
    const s = {
        5: w(5, { focus_timestamp: ts(10, 5) }),
        3: w(3, { focus_timestamp: ts(10, 5) }),
        4: w(4, { focus_timestamp: ts(10, 900) }),
        9: w(9, { focus_timestamp: ts(11) }),
        2: w(2, { focus_timestamp: null }),
        1: w(1),
    };
    assert.deepStrictEqual(plain(N.sortWindows(s)).map(x => x.id), [9, 4, 3, 5, 1, 2]);
});

test("sortWindows compares secs before nanos without overflowing doubles", () => {
    const s = { 1: w(1, { focus_timestamp: ts(20000000, 0) }), 2: w(2, { focus_timestamp: ts(19999999, 999999999) }) };
    assert.deepStrictEqual(plain(N.sortWindows(s)).map(x => x.id), [1, 2]);
});
