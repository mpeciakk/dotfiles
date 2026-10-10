import { test } from "node:test";
import assert from "node:assert/strict";
import { load, plain } from "./qmljs.mjs";

const T = load("lib/theme.js");

test("rgba() encodes #aarrggbb with rounded alpha", () => {
    assert.equal(T.rgba(16, 14, 26, 0.62), "#9e100e1a");
    assert.equal(T.rgba(255, 255, 255, 0.07), "#12ffffff");
});

test("hex() normalises #rrggbb and #aarrggbb", () => {
    assert.equal(T.hex("#ECEAF2"), "#ffeceaf2");
    assert.equal(T.hex("#80112233"), "#80112233");
});

test("withAlpha() replaces alpha", () => {
    assert.equal(T.withAlpha("#B9A7F5", 0.18), "#2eb9a7f5");
});

test("merge() overrides leaves, keeps siblings, replaces arrays, never mutates", () => {
    const base = { a: { b: 1, c: 2 }, l: [1, 2] };
    assert.deepStrictEqual(plain(T.merge(base, { a: { c: 3 }, l: [9] })), { a: { b: 1, c: 3 }, l: [9] });
    assert.deepStrictEqual(plain(base), { a: { b: 1, c: 2 }, l: [1, 2] });
    assert.deepStrictEqual(plain(T.merge({ a: { b: 1 } }, { a: 5 })), { a: { b: 1 } });
    assert.deepStrictEqual(plain(T.merge({ a: 1 }, null)), { a: 1 });
});

test("defaults: geometry matches DESIGN §4", () => {
    const g = plain(T.defaults.geom);
    assert.deepStrictEqual(g.line, { w: 56, h: 5, r: 3 });
    assert.deepStrictEqual(g.rest, { w: 200, h: 36, r: 18 });
    assert.deepStrictEqual(g.restBadge, { w: 252, h: 36, r: 18 });
    assert.deepStrictEqual(g.osd, { w: 300, h: 44, r: 22 });
    assert.deepStrictEqual(g.media, { w: 380, h: 56, r: 28 });
    assert.deepStrictEqual(g.toast, { w: 420, h: 76, r: 30 });
    assert.deepStrictEqual(g.control, { w: 520, h: 440, r: 30 });
    assert.deepStrictEqual(g.launcher, { w: 680, h: 356, r: 30 });
    assert.deepStrictEqual(g.power, { w: 540, h: 180, r: 30 });
    assert.deepStrictEqual(g.powerDone, { w: 340, h: 56, r: 28 });
    assert.deepStrictEqual(g.center, { w: 440, hMin: 170, hMax: 620, r: 30 });
    assert.deepStrictEqual(g.lock, { w: 460, h: 360, r: 36 });
    assert.equal(g.ear, 16);
    assert.equal(g.exclusive, 36);
    assert.deepStrictEqual(g.hoverZone, { w: 400, h: 28 });
});

test("defaults: motion matches DESIGN §5", () => {
    const m = plain(T.defaults.motion);
    assert.equal(m.morphMs, 460);
    assert.deepStrictEqual(m.morphCurve, [0.32, 0.72, 0, 1, 1, 1]);
    assert.deepStrictEqual(m.enterCurve, [0.2, 0, 0, 1, 1, 1]);
    assert.deepStrictEqual(m.easeCurve, [0.25, 0.1, 0.25, 1, 1, 1]);
    assert.equal(m.lockMorphMs, 640);
    assert.equal(m.themeFadeMs, 600);
    assert.equal(m.sheenFadeMs, 300);
    assert.equal(m.osdTimeoutMs, 1600);
    assert.equal(m.toastTimeoutMs, 3600);
    assert.equal(m.holdMs, 900);
    assert.equal(m.reducedFadeMs, 120);
});

test("defaults: choices", () => {
    assert.equal(T.defaults.mode, "dark");
    assert.equal(T.defaults.modeSource, "manual");
    assert.equal(T.defaults.glassLevel, "ciekłe");
    assert.equal(T.defaults.glass, true);
    assert.equal(T.defaults.reducedMotion, false);
    assert.equal(T.defaults.fonts.ui, "JetBrainsMono Nerd Font");
    assert.equal(T.defaults.fonts.mono, "JetBrainsMono Nerd Font");
    assert.equal(T.defaults.sizes.iconStroke, 1.6);
    assert.equal(T.defaults.sizes.iconGrid, 24);
    assert.equal(T.defaults.sizes.sheenGlow, 30);
    assert.equal(T.defaults.sizes.sheenMidStop, 0.45);
});

test("resolve(): dark ciekłe", () => {
    const c = plain(T.resolve(T.defaults, "dark", "ciekłe", true));
    assert.equal(c.islandBg, T.rgba(22, 18, 36, 0.28));
    assert.equal(c.tile, T.rgba(255, 255, 255, 0.07));
    assert.equal(c.sel, T.rgba(255, 255, 255, 0.12));
    assert.equal(c.chip, T.rgba(255, 255, 255, 0.14));
    assert.equal(c.card, c.sel);
    assert.equal(c.hover, c.sel);
    assert.equal(c.track, c.chip);
    assert.equal(c.sliderFill, c.fg);
    assert.equal(c.sheen, 1);
    assert.equal(c.fg, T.hex("#ECEAF2"));
    assert.equal(c.fgMuted, T.hex("#A29DB3"));
    assert.equal(c.accent, T.hex("#B9A7F5"));
    assert.equal(c.accentSoft, T.withAlpha("#B9A7F5", 0.18));
    assert.equal(c.onAccent, T.hex("#121118"));
    assert.equal(c.danger, T.hex("#F2A7B8"));
    assert.equal(c.ring, T.rgba(255, 255, 255, 0.07));
    assert.equal(c.shadowColor, T.rgba(10, 6, 20, 0.5));
    assert.equal(c.shadowY, 18);
    assert.equal(c.shadowBlur, 60);
    assert.equal(c.shadowPad, 78);
    assert.equal(c.sheenTop, T.rgba(255, 255, 255, 0.12));
    assert.equal(c.sheenMid, T.rgba(255, 255, 255, 0.02));
    assert.equal(c.sheenEdge, T.rgba(255, 255, 255, 0.22));
    assert.equal(c.sheenOutline, T.rgba(255, 255, 255, 0.1));
    assert.equal(c.sheenGlow, T.rgba(255, 255, 255, 0.06));
    assert.deepStrictEqual(c.lockWallpaper, { blur: 22, saturate: 1.2, brightness: 0.78, scale: 1.08 });
});

test("resolve(): light subtelne and light mocne", () => {
    const s = plain(T.resolve(T.defaults, "light", "subtelne", true));
    assert.equal(s.islandBg, T.rgba(230, 226, 236, 0.8));
    assert.equal(s.tile, T.hex("#EFECF3"));
    assert.equal(s.sel, T.hex("#F3F1F6"));
    assert.equal(s.card, T.hex("#F3F1F6"));
    assert.equal(s.chip, T.hex("#DDD9E5"));
    assert.equal(s.track, T.hex("#CFCADA"));
    assert.equal(s.sheen, 0);
    assert.equal(s.fg, T.hex("#1E1B2A"));
    assert.equal(s.accent, T.hex("#5E48B8"));
    assert.equal(s.onAccent, T.hex("#FFFFFF"));
    assert.equal(s.danger, T.hex("#B4405E"));
    assert.equal(s.ring, T.rgba(255, 255, 255, 0.55));
    assert.equal(s.shadowColor, T.rgba(40, 30, 70, 0.2));
    assert.equal(s.shadowBlur, 50);
    assert.equal(s.shadowPad, 68);
    assert.equal(s.sheenGlow, T.rgba(255, 255, 255, 0));
    assert.deepStrictEqual(s.lockWallpaper, { blur: 18, saturate: 1.2, brightness: 0.92, scale: 1.08 });
    const m = plain(T.resolve(T.defaults, "light", "mocne", true));
    assert.equal(m.islandBg, T.rgba(232, 228, 238, 0.58));
    assert.equal(m.tile, T.rgba(255, 255, 255, 0.42));
    assert.equal(m.chip, T.rgba(30, 27, 42, 0.08));
    assert.equal(m.sheen, 0.5);
});

test("resolve(): solid fallback and unknown level", () => {
    const c = plain(T.resolve(T.defaults, "dark", "ciekłe", false));
    assert.equal(c.islandBg, T.rgba(16, 14, 26, 0.78));
    assert.equal(c.tile, T.hex("#17161F"));
    assert.equal(c.sel, T.hex("#1E1D28"));
    assert.equal(c.sheen, 0);
    const u = plain(T.resolve(T.defaults, "dark", "nope", true));
    assert.equal(u.islandBg, T.rgba(22, 18, 36, 0.28));
});

test("resolve(): config overrides flow through merge", () => {
    const tokens = T.merge(T.defaults, { palette: { dark: { accent: "#8FD3C1" } } });
    assert.equal(T.resolve(tokens, "dark", "ciekłe", true).accent, T.hex("#8FD3C1"));
});

test("defaults: layout.rest matches reference 3.1", () => {
    const r = plain(T.defaults.layout.rest);
    assert.deepStrictEqual(r, {
        gap: 14, dotsGap: 4, dot: 5, dotActiveW: 14, dotRadius: 3,
        eqGap: 2, eqH: 12, eqBarW: 2, eqScaleMin: 0.35, eqDelayMs: [0, -300, -600],
        badgeGap: 5, badgeH: 22, badgePad: 8, badgeRadius: 11, badgeFont: 11, badgeIcon: 12
    });
});
