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
});
