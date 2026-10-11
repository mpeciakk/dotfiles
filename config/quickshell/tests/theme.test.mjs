import { test } from "node:test";
import assert from "node:assert/strict";
import { load, plain } from "./qmljs.mjs";
import { readFileSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

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

test("raiseAlpha() adds to the alpha and stops at opaque", () => {
    assert.equal(T.raiseAlpha("#66100e1a", 0.2), "#99100e1a");
    assert.equal(T.raiseAlpha("#f0100e1a", 0.2), "#ff100e1a");
    assert.equal(T.raiseAlpha("#100e1a", 0.2), "#ff100e1a");
});

test("defaults: the legibility sampler rescales to 64", () => {
    assert.equal(T.defaults.legibility.sampleSize, 64);
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
    assert.equal(c.fg, T.hex("#ECEAF2"));
    assert.equal(c.fgMuted, T.hex("#A29DB3"));
    assert.equal(c.accent, T.hex("#B9A7F5"));
    assert.equal(c.accentSoft, T.withAlpha("#B9A7F5", 0.18));
    assert.equal(c.onAccent, T.hex("#121118"));
    assert.equal(c.danger, T.hex("#F2A7B8"));
    assert.equal(c.ring, T.rgba(255, 255, 255, 0.07));
    assert.equal(c.shadowColor, T.rgba(10, 6, 20, 0.38));
    assert.equal(c.shadowY, 12);
    assert.equal(c.shadowBlur, 36);
    assert.equal(c.shadowPad, 48);
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
    assert.equal(s.fg, T.hex("#1E1B2A"));
    assert.equal(s.accent, T.hex("#4E3A9E"));
    assert.equal(s.fgMuted, T.hex("#48435C"));
    assert.equal(s.fgDim, T.hex("#5C5770"));
    assert.equal(s.dotInactive, T.hex("#6E6984"));
    assert.equal(s.onAccent, T.hex("#FFFFFF"));
    assert.equal(s.danger, T.hex("#B4405E"));
    assert.equal(s.ring, T.rgba(255, 255, 255, 0.3));
    assert.equal(s.shadowColor, T.rgba(20, 16, 30, 0.16));
    assert.equal(s.shadowBlur, 30);
    assert.equal(s.shadowPad, 40);
    assert.deepStrictEqual(s.lockWallpaper, { blur: 18, saturate: 1.2, brightness: 0.92, scale: 1.08 });
    const m = plain(T.resolve(T.defaults, "light", "mocne", true));
    assert.equal(m.islandBg, T.rgba(232, 228, 238, 0.58));
    assert.equal(m.tile, T.rgba(255, 255, 255, 0.42));
    assert.equal(m.chip, T.rgba(30, 27, 42, 0.08));
});

test("resolve(): solid fallback and unknown level", () => {
    const c = plain(T.resolve(T.defaults, "dark", "ciekłe", false));
    assert.equal(c.islandBg, T.rgba(16, 14, 26, 0.78));
    assert.equal(c.tile, T.hex("#17161F"));
    assert.equal(c.sel, T.hex("#1E1D28"));
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

test("defaults: layout.osd matches reference 3.2", () => {
    assert.deepStrictEqual(plain(T.defaults.layout.osd), {
        padX: 16, gap: 12, icon: 18, barH: 6, barRadius: 3, valueW: 28, valueFont: 12, volumeHighFrom: 0.5, percent: 100
    });
});

test("defaults: layout.toast matches reference 3.4 variant B", () => {
    assert.deepStrictEqual(plain(T.defaults.layout.toast), {
        padX: 16, gap: 14, icon: 44, iconRadius: 14, iconImage: 28, iconLetter: 16, textGap: 2,
        titleFont: 14, bodyFont: 12, chipH: 24, chipPad: 9, chipRadius: 12, chipFont: 11,
        barInset: 30, barH: 2
    });
});

test("resolve(): appColors are the accent followed by its three alternatives (R30)", () => {
    const dark = T.resolve(T.defaults, "dark", "ciekłe", true).appColors;
    assert.deepStrictEqual(plain(dark), ["#ffb9a7f5", "#fff1d6ae", "#ff8fd3c1", "#fff2a7b8"]);
    const light = T.resolve(T.defaults, "light", "ciekłe", true).appColors;
    assert.deepStrictEqual(plain(light), ["#ff4e3a9e", "#ff8a5a1e", "#ff2f7a68", "#ffa23d5c"]);
});

test("resolve(): appColors follow an accent override", () => {
    const tokens = T.merge(T.defaults, { palette: { dark: { accent: "#112233" } } });
    assert.equal(T.resolve(tokens, "dark", "ciekłe", true).appColors[0], "#ff112233");
});

test("defaults: layout.center matches reference 3.5 and R28", () => {
    assert.deepStrictEqual(plain(T.defaults.layout.center), {
        hMin: 170, hMax: 620,
        pad: 14, header: 36, gap: 10, bottom: 16,
        groupHeader: 28, card: 64, cardGap: 6, groupGap: 12,
        stackPad1: 7, stackPad2: 14,
        headerPadX: 4, headerGap: 10, titleFont: 15, countFont: 12,
        btnH: 30, btnPadX: 10, btnRadius: 15, btnFont: 12, dndGap: 8, dndIcon: 13,
        emptyGap: 6, emptyIcon: 22, emptyFont: 13,
        groupHeadH: 22, groupHeadPadX: 4, groupHeadGap: 8, groupFont: 11, groupLetterEm: 0.08, groupCountFont: 11,
        toggleFont: 11, togglePadX: 6, groupBtn: 22, groupBtnRadius: 11, groupBtnIcon: 12,
        layer1Inset: 8, layer2Inset: 16, stack1Opacity: 0.7, stack2Opacity: 0.45,
        cardRadius: 16, cardPadL: 12, cardPadR: 8, cardInnerGap: 12,
        cardIcon: 36, cardIconRadius: 11, cardIconImage: 24, cardIconLetter: 14, cardTextGap: 2,
        cardTitleFont: 13, cardBodyFont: 12, cardTimeFont: 11,
        dismissBtn: 28, dismissRadius: 14, dismissIcon: 12,
        scrollW: 4
    });
});

test("defaults: layout.center bounds equal geom.center bounds", () => {
    assert.equal(T.defaults.layout.center.hMin, T.defaults.geom.center.hMin);
    assert.equal(T.defaults.layout.center.hMax, T.defaults.geom.center.hMax);
});

test("defaults: layout.launcher matches reference 3.6 and R29", () => {
    assert.deepStrictEqual(plain(T.defaults.layout.launcher), {
        pad: 10, fieldH: 48, fieldPadX: 16, fieldGap: 10, searchIcon: 18, queryFont: 16,
        caretW: 1.5, caretH: 18, caretGap: 2,
        kbdFont: 11, kbdPadX: 8, kbdPadY: 3, kbdPadYRow: 4,
        chipsGap: 6, chipsPadX: 4, chipsPadTop: 10, chipsPadBottom: 8,
        chipH: 28, chipPadX: 12, chipFont: 12, chipPrefixGap: 4,
        visibleRows: 3, shortcuts: 9, rowGap: 4, rowPadX: 14, rowPadY: 10, rowInnerGap: 14,
        icon: 40, iconImage: 28, iconLetter: 16, iconGlyph: 20, nameFont: 15, descFont: 12, textGap: 2, dot: 8,
        emptyFont: 13,
        footerPadTop: 10, footerPadX: 12, footerPadBottom: 2, footerGap: 16, footerFont: 11,
        refreshMs: 700, refreshes: 4
    });
});

test("defaults: layout.control matches reference 3.7 and R24", () => {
    assert.deepStrictEqual(plain(T.defaults.layout.control), {
        pad: 16, gap: 10,
        headPadX: 6, headPadTop: 2, headPadBottom: 4, clockFont: 44, clockLetterEm: -0.03, dateFont: 13, dateGap: 2,
        tilePad: 12, tileGap: 10, tileCircle: 38, tileIcon: 17, tileTitleFont: 14, tileSubFont: 12, tileTextGap: 1,
        cardPadX: 14, cardPadY: 16, cardGap: 16, sliderGap: 12, sliderIcon: 17, trackH: 6, trackRadius: 3,
        valueW: 28, valueFont: 12, hitH: 24, wheelStep: 0.05, percent: 100, brightnessThrottleMs: 50, brightnessMin: 0.05,
        toggleCols: 4, togglePadY: 2, toggleGap: 6, toggle: 50, toggleIcon: 18, toggleLabelFont: 11
    });
});

test("defaults: layout.miniPlayer matches reference 3.7", () => {
    assert.deepStrictEqual(plain(T.defaults.layout.miniPlayer), {
        pad: 10, gap: 12, art: 40, artRadius: 12, textGap: 1, titleFont: 13, artistFont: 12,
        play: 38, playIcon: 14, skip: 32, skipIcon: 15, disabledOpacity: 0.4
    });
});

test("defaults: layout.media matches reference 3.3", () => {
    assert.deepStrictEqual(plain(T.defaults.layout.media), {
        art: 36, artRadius: 10, play: 36,
        eqGap: 2, eqH: 14, eqBarW: 2, eqMarginRight: 4, eqScaleMin: 0.35, eqDelayMs: [0, -200, -500, -700],
        emptyFont: 13
    });
});

test("defaults: layout.power and layout.powerDone match reference 3.8 / 3.9", () => {
    assert.deepStrictEqual(plain(T.defaults.layout.power), {
        padTop: 16, padX: 18, padBottom: 18, gap: 14, headPadX: 4, titleFont: 14, hintFont: 12,
        gridGap: 8, buttonGap: 8, buttonPadY: 4, circle: 60, icon: 20,
        ringRadius: 28, ringWidth: 2.5, ringStart: -90, ringSweep: 360,
        labelFont: 12, keyFont: 10, focusWidth: 1.5, focusGap: 4, focusRadius: 18
    });
    assert.deepStrictEqual(plain(T.defaults.layout.powerDone), {
        padX: 20, gap: 12, dot: 10, dotRadius: 5, haloWidth: 4, labelFont: 14
    });
});

test("defaults: layout.lock matches reference 3.10 and §4.6", () => {
    assert.deepStrictEqual(plain(T.defaults.layout.lock), {
        padTop: 30, padX: 28, padBottom: 24,
        clockFont: 88, clockLetterEm: -0.045, dateGap: 10, dateFont: 15,
        fieldGap: 30, fieldW: 340, fieldH: 52, fieldPadX: 8, fieldInnerGap: 12, fieldRing: 1, errorRing: 1.5,
        focusWidth: 1.5, focusGap: 3, focusAlpha: 0.8,
        avatar: 36, avatarFont: 16, inputH: 40, inputFont: 15, inputLetterEm: 0.12, submit: 36, submitIcon: 16,
        statusGap: 12, statusFont: 13, statusH: 18,
        bottomGap: 18, bottomFont: 12, bottomItemGap: 6, bottomIcon: 14, percent: 100,
        shakeSteps: [-10, 8, -6, 3, 0],
        contentScaleFrom: 0.92, contentBlur: 8,
        enterDelayMs: 260, enterOpacityMs: 260, enterScaleLeadMs: 40, enterScaleMs: 380, enterBlurMs: 260,
        exitOpacityMs: 140, exitScaleMs: 180, exitBlurMs: 140,
        playerW: 380, playerH: 56, playerRadius: 28, edge: 32,
        cornerGap: 10, cornerButton: 48, cornerIcon: 18, ringRadius: 22,
        extrasDelayMs: 520, extrasMs: 300
    });
});

test("guard: no QML property is named on<Capital> (Quickshell 0.3.2 drops its binding: Theme.onAccent read black)", () => {
    const root = join(dirname(fileURLToPath(import.meta.url)), "..");
    const qml = dir => readdirSync(join(root, dir)).filter(f => f.endsWith(".qml")).map(f => join(dir, f));
    for (const f of [...qml("."), ...qml("states"), ...qml("components"), ...qml("services")]) {
        const s = readFileSync(join(root, f), "utf8");
        assert.doesNotMatch(s, /\bproperty\s+\w+(<[^>]*>)?\s+on[A-Z]/, f);
        assert.doesNotMatch(s, /\bTheme\.on[A-Z]/, f);
    }
});

test("the glass has no gloss: no sheen tokens, the rim is the ring alone", () => {
    assert.equal(T.defaults.sheen, undefined);
    assert.equal(T.defaults.motion.sheenFadeMs, undefined);
    for (const level of Object.keys(T.defaults.glassLevels))
        for (const mode of ["dark", "light"]) {
            assert.equal(T.defaults.glassLevels[level][mode].sheen, undefined);
            const c = plain(T.resolve(T.defaults, mode, level, true));
            assert.deepStrictEqual(Object.keys(c).filter(k => k.startsWith("sheen")), []);
        }
    assert.equal(T.defaults.legibility.lightBoost, 0.18);
});
