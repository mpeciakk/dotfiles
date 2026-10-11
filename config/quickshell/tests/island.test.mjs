import { test } from "node:test";
import assert from "node:assert/strict";
import { load, plain } from "./qmljs.mjs";

const I = load("lib/island.js");
const G = {
    line: { w: 56, h: 5, r: 3 }, rest: { w: 200, h: 36, r: 18 }, restBadge: { w: 252, h: 36, r: 18 },
    osd: { w: 300, h: 44, r: 22 }, media: { w: 380, h: 56, r: 28 }, toast: { w: 420, h: 76, r: 30 },
    control: { w: 520, h: 440, r: 30 }, launcher: { w: 680, h: 356, r: 30 }, power: { w: 540, h: 180, r: 30 },
    powerDone: { w: 340, h: 56, r: 28 }, center: { w: 440, hMin: 170, hMax: 620, r: 30 }, ear: 16,
};

test("geometry: table states", () => {
    assert.deepStrictEqual(plain(I.geometry("launcher", G, {})), { w: 680, h: 356, r: 30, ears: true });
    assert.deepStrictEqual(plain(I.geometry("osd", G, {})), { w: 300, h: 44, r: 22, ears: true });
    assert.deepStrictEqual(plain(I.geometry("powerDone", G, {})), { w: 340, h: 56, r: 28, ears: true });
});

test("geometry: rest widens with the badge", () => {
    assert.deepStrictEqual(plain(I.geometry("rest", G, { badge: false })), { w: 200, h: 36, r: 18, ears: true });
    assert.deepStrictEqual(plain(I.geometry("rest", G, { badge: true })), { w: 252, h: 36, r: 18, ears: true });
});

test("geometry: line has no ears", () => {
    assert.deepStrictEqual(plain(I.geometry("line", G, {})), { w: 56, h: 5, r: 3, ears: false });
});

test("geometry: center height clamps and radius follows min(h/2, r)", () => {
    assert.deepStrictEqual(plain(I.geometry("center", G, { centerHeight: 900 })), { w: 440, h: 620, r: 30, ears: true });
    assert.deepStrictEqual(plain(I.geometry("center", G, { centerHeight: 100 })), { w: 440, h: 170, r: 30, ears: true });
    assert.deepStrictEqual(plain(I.geometry("center", G, { centerHeight: 333 })), { w: 440, h: 333, r: 30, ears: true });
});

test("geometry: unknown state falls back to rest", () => {
    assert.deepStrictEqual(plain(I.geometry("bogus", G, {})), { w: 200, h: 36, r: 18, ears: true });
});

test("geometry: works over the real Theme.geom defaults", () => {
    const real = load("lib/theme.js").defaults.geom;
    assert.deepStrictEqual(plain(I.geometry("rest", real, {})), { w: 200, h: 36, r: 18, ears: true });
    assert.deepStrictEqual(plain(I.geometry("launcher", real, {})), { w: 680, h: 356, r: 30, ears: true });
});

test("radiusFor", () => {
    assert.equal(I.radiusFor(36, 30), 18);
    assert.equal(I.radiusFor(440, 30), 30);
});

test("accepts(): priority", () => {
    assert.equal(I.accepts("rest", "toast"), true);
    assert.equal(I.accepts("launcher", "toast"), false);
    assert.equal(I.accepts("toast", "osd"), false);
    assert.equal(I.accepts("osd", "toast"), true);
    assert.equal(I.accepts("media", "osd"), true);
    assert.equal(I.accepts("control", "launcher"), true);
    assert.equal(I.accepts("launcher", "control"), false);
    assert.equal(I.accepts("control", "power"), true);
    assert.equal(I.accepts("toast", "rest"), true);
    assert.equal(I.accepts("rest", "bogus"), false);
});

test("isModal()", () => {
    for (const s of ["launcher", "control", "power", "center"]) assert.equal(I.isModal(s), true, s);
    for (const s of ["rest", "osd", "media", "toast", "powerDone", "line"]) assert.equal(I.isModal(s), false, s);
});

test("stranded(): a modal state whose output is gone has no surface to close it; nothing else is stranded", () => {
    assert.equal(I.stranded("launcher", "DP-1", ["HDMI-A-1"]), true);
    assert.equal(I.stranded("power", "DP-1", []), true);
    assert.equal(I.stranded("launcher", "DP-1", ["DP-1", "HDMI-A-1"]), false);
    for (const s of ["rest", "osd", "media", "toast", "powerDone"]) assert.equal(I.stranded(s, "DP-1", []), false, s);
});

test("osdIcon: brightness is a sun; volume by level, mute and zero is volume-x", () => {
    assert.equal(I.osdIcon("brightness", 0.5, false, 0.5), "sun");
    assert.equal(I.osdIcon("volume", 0.4, true, 0.5), "volume-x");
    assert.equal(I.osdIcon("volume", 0, false, 0.5), "volume-x");
    assert.equal(I.osdIcon("volume", 0.4, false, 0.5), "volume-1");
    assert.equal(I.osdIcon("volume", 0.5, false, 0.5), "volume-2");
    assert.equal(I.osdIcon("volume", 1.2, false, 0.5), "volume-2");
});
