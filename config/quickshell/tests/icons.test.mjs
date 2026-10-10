import { test } from "node:test";
import assert from "node:assert/strict";
import { load } from "./qmljs.mjs";

const I = load("lib/icons.js");
const NAMES = ["bell", "moon", "volume-x", "volume-1", "volume-2", "sun", "sun-moon", "wifi", "bluetooth",
    "play", "pause", "skip-back", "skip-forward", "power", "lock", "log-out", "rotate-ccw", "search",
    "calculator", "terminal", "app-window", "x", "check", "arrow-right", "battery", "battery-charging",
    "chevron-down", "chevron-up"];

test("every icon the shell uses is a path d string", () => {
    for (const n of NAMES) {
        assert.equal(typeof I.paths[n], "string", n);
        assert.match(I.paths[n], /^[MmLlHhVvCcSsQqTtAaZz0-9 ,.\-]+$/, n);
        assert.match(I.paths[n], /^[Mm]/, n);
    }
});

test("sub-paths of one d string start with an absolute M", () => {
    // A relative `m` after another sub-path would start from that sub-path's end point.
    for (const n of NAMES)
        assert.doesNotMatch(I.paths[n].slice(1), /m/, n);
});

test("prototype paths are kept verbatim", () => {
    assert.ok(I.paths.bell.includes("M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"));
    assert.ok(I.paths.power.includes("M12 2v10"));
    assert.ok(I.paths.check.includes("M20 6 9 17l-5-5"));
    assert.ok(I.paths.moon.includes("M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z"));
    assert.ok(I.paths.bluetooth.includes("M7 7l10 10-5 5V2l5 5L7 17"));
    assert.ok(I.paths.x.includes("M6 6l12 12M18 6 6 18"));
    assert.ok(I.paths["arrow-right"].includes("M5 12h14M13 6l6 6-6 6"));
    assert.ok(I.paths.pause.includes("M9 5v14M15 5v14"));
    assert.ok(I.paths["skip-back"].includes("M19 4l-10 8 10 8V4zM5 5v14"));
    assert.ok(I.paths.search.includes("M20 20l-3.5-3.5"));
});

test("reference 3.8 / 5 icons carry the prototype geometry, not stock Lucide", () => {
    // lock: rect x5 y11 w14 h10 rx2 + shackle M8 11V8a4 4 0 0 1 8 0v3
    assert.ok(I.paths.lock.includes("M7 11H17a2 2 0 0 1 2 2V19a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V13a2 2 0 0 1 2-2z"));
    assert.ok(I.paths.lock.includes("M8 11V8a4 4 0 0 1 8 0v3"));
    // log-out: M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4 + m16 17 5-5-5-5M21 12H9 (m -> M)
    assert.ok(I.paths["log-out"].includes("M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"));
    assert.ok(I.paths["log-out"].includes("M16 17l5-5-5-5M21 12H9"));
    // rotate-ccw: M3 12a9 9 0 1 0 3-6.7L3 8 + M3 3v5h5
    assert.ok(I.paths["rotate-ccw"].includes("M3 12a9 9 0 1 0 3-6.7L3 8"));
    assert.ok(I.paths["rotate-ccw"].includes("M3 3v5h5"));
    // battery: rect x2 y7 w17 h10 rx2.5 + cap M22 11v2; the charging variant shares body edges and cap
    assert.ok(I.paths.battery.includes("M4.5 7H16.5a2.5 2.5 0 0 1 2.5 2.5V14.5a2.5 2.5 0 0 1-2.5 2.5H4.5a2.5 2.5 0 0 1-2.5-2.5V9.5a2.5 2.5 0 0 1 2.5-2.5z"));
    assert.ok(I.paths.battery.includes("M22 11v2"));
    assert.ok(I.paths["battery-charging"].includes("M22 11v2"));
    assert.ok(I.paths["battery-charging"].includes("V9.5a2.5 2.5 0 0 1 2.5-2.5"));
});
