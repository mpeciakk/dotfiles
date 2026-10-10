.pragma library

// Design tokens for Wyspa. Every UI value (colour, px, ms, opacity) lives here
// and is overridable from config.json under "island" (see Theme.qml, merge()).
// Colours are #aarrggbb strings — QML `color` cannot parse CSS rgba().

function pad2(n) {
    var s = n.toString(16);
    return s.length < 2 ? "0" + s : s;
}

function rgba(r, g, b, a) {
    return "#" + pad2(Math.round(a * 255)) + pad2(r) + pad2(g) + pad2(b);
}

// "#rrggbb" | "#aarrggbb" -> lowercase "#aarrggbb". Anything else passes through.
function hex(c) {
    var m = /^#([0-9a-fA-F]{6})$/.exec(c);
    if (m)
        return ("#ff" + m[1]).toLowerCase();
    return /^#[0-9a-fA-F]{8}$/.test(c) ? c.toLowerCase() : c;
}

function withAlpha(c, a) {
    return "#" + pad2(Math.round(a * 255)) + hex(c).slice(3);
}

function isObject(x) {
    return x !== null && typeof x === "object" && !Array.isArray(x);
}

function clone(x) {
    if (Array.isArray(x))
        return x.slice();
    if (!isObject(x))
        return x;
    var out = {};
    for (var k in x)
        out[k] = clone(x[k]);
    return out;
}

// Recursive for plain objects; arrays and primitives in `over` replace the base
// value; a non-object `over` for an object node is ignored. Never mutates.
function merge(base, over) {
    var out = clone(base);
    if (!isObject(over) || !isObject(out))
        return out;
    for (var k in over) {
        if (over[k] === null || over[k] === undefined)
            continue;
        if (isObject(out[k]))
            out[k] = isObject(over[k]) ? merge(out[k], over[k]) : out[k];
        else
            out[k] = clone(over[k]);
    }
    return out;
}

var defaults = {
    mode: "dark",
    modeSource: "manual",           // "manual" | "sun" | "wallpaper"
    location: { lat: null, lon: null },
    wallpaperLight: 0.6,            // mean luminance above which the wallpaper mode picks light
    wallpaperDark: 0.5,             // ... below which it picks dark (hysteresis between)
    legibility: { threshold: 0.7, boost: 0.2 },
    glass: true,
    glassLevel: "ciekłe",           // "subtelne" | "mocne" | "ciekłe"
    reducedMotion: false,

    fonts: { ui: "JetBrainsMono Nerd Font", mono: "JetBrainsMono Nerd Font" },

    sizes: { iconStroke: 1.6, iconGrid: 24, ringWidth: 1, clockRest: 13, sheenGlow: 30, sheenMidStop: 0.45 },

    // Island states. r = bottom radius (lock: all corners).
    geom: {
        line: { w: 56, h: 5, r: 3 },
        rest: { w: 200, h: 36, r: 18 },
        restBadge: { w: 252, h: 36, r: 18 },
        osd: { w: 300, h: 44, r: 22 },
        media: { w: 380, h: 56, r: 28 },
        toast: { w: 420, h: 76, r: 30 },
        control: { w: 520, h: 440, r: 30 },
        launcher: { w: 680, h: 356, r: 30 },
        power: { w: 540, h: 180, r: 30 },
        powerDone: { w: 340, h: 56, r: 28 },
        center: { w: 440, hMin: 170, hMax: 620, r: 30 },
        lock: { w: 460, h: 360, r: 36 },
        ear: 16,
        exclusive: 36,
        hoverZone: { w: 400, h: 28 }
    },

    radii: {
        tile: 20, card: 16, field: 24, lockField: 26, chip: 14, kbd: 8,
        iconLg: 14, iconMd: 12, iconSm: 11, art: 10
    },

    motion: {
        morphMs: 460,
        morphCurve: [0.32, 0.72, 0, 1, 1, 1],
        enterCurve: [0.2, 0, 0, 1, 1, 1],
        easeCurve: [0.25, 0.1, 0.25, 1, 1, 1],
        shakeCurve: [0.36, 0.07, 0.19, 0.97, 1, 1],
        lockMorphMs: 640,
        wallpaperMs: 700,
        themeFadeMs: 600,
        sheenFadeMs: 300,
        enterOpacityMs: 220,
        enterOpacityDelayMs: 160,
        enterScaleMs: 320,
        enterScaleDelayMs: 120,
        enterBlurMs: 220,
        enterBlurDelayMs: 160,
        exitOpacityMs: 120,
        exitScaleMs: 160,
        exitBlurMs: 120,
        contentScaleFrom: 0.94,
        contentBlur: 6,
        reducedFadeMs: 120,
        earFadeMs: 160,
        bgColorMs: 200,
        osdBarMs: 260,
        osdTimeoutMs: 1600,
        toastTimeoutMs: 3600,
        toastBarMs: 3400,
        toastBarDelayMs: 60,
        lineLeaveDelayMs: 250,
        mediaLeaveMs: 250,
        holdMs: 900,
        holdCancelMs: 220,
        powerDoneMs: 1800,
        dimMs: 400,
        stackPadMs: 300,
        buttonBgMs: 200,
        eqMs: 900,
        shakeMs: 380
    },

    // Colours that do not depend on the glass level. Omitted keys are derived in
    // resolve(): fgSoft = fg, fgLock = fgMuted, track = chip, lockField = tile,
    // lockGlass = islandBg.
    // Accent alternatives — dark: #F1D6AE #8FD3C1 #F2A7B8; light: #8A5A1E #2F7A68 #A23D5C
    palette: {
        dark: {
            ring: rgba(255, 255, 255, 0.07),
            fg: "#ECEAF2",
            fgMuted: "#A29DB3",
            fgDim: "#8B8699",
            fgLock: "#CFC8E0",
            accent: "#B9A7F5",
            onAccent: "#121118",
            inverseBg: "#ECEAF2",
            inverseFg: "#121118",
            danger: "#F2A7B8",
            dotInactive: "#57536A",
            line: rgba(236, 234, 242, 0.75),
            divider: "#1F1E2A",
            scrimDim: rgba(8, 6, 14, 0.45),
            lockField: rgba(255, 255, 255, 0.07),
            lockFieldRing: rgba(255, 255, 255, 0.12),
            lockGlass: rgba(16, 14, 26, 0.55)
        },
        light: {
            ring: rgba(255, 255, 255, 0.55),
            fg: "#1E1B2A",
            fgMuted: "#5C5770",
            fgDim: "#77728A",
            accent: "#5E48B8",
            onAccent: "#FFFFFF",
            inverseBg: "#1E1B2A",
            inverseFg: "#EFECF3",
            danger: "#B4405E",
            dotInactive: "#A9A4B8",
            line: rgba(30, 27, 42, 0.55),
            divider: "#D6D2DF",
            scrimDim: rgba(40, 30, 70, 0.22),
            track: "#CFCADA",
            lockFieldRing: rgba(30, 27, 42, 0.08)
        }
    },

    // Alpha of the colours derived from `accent`.
    accentAlpha: { soft: 0.18, halo: 0.2, focus: 0.9 },

    // Per glass level and theme. `card` falls back to `sel`; `sheen` is the gloss opacity.
    glassLevels: {
        "subtelne": {
            dark: { bg: rgba(16, 14, 26, 0.62), tile: "#17161F", sel: "#1E1D28", chip: "#2C2A39", card: "#1F1E2A", sheen: 0 },
            light: { bg: rgba(230, 226, 236, 0.8), tile: "#EFECF3", sel: "#F3F1F6", chip: "#DDD9E5", card: "#F3F1F6", sheen: 0 }
        },
        "mocne": {
            dark: { bg: rgba(16, 14, 26, 0.4), tile: rgba(255, 255, 255, 0.06), sel: rgba(255, 255, 255, 0.1), chip: rgba(255, 255, 255, 0.12), sheen: 0.5 },
            light: { bg: rgba(232, 228, 238, 0.58), tile: rgba(255, 255, 255, 0.42), sel: rgba(255, 255, 255, 0.52), chip: rgba(30, 27, 42, 0.08), sheen: 0.5 }
        },
        "ciekłe": {
            dark: { bg: rgba(22, 18, 36, 0.28), tile: rgba(255, 255, 255, 0.07), sel: rgba(255, 255, 255, 0.12), chip: rgba(255, 255, 255, 0.14), sheen: 1 },
            light: { bg: rgba(234, 230, 240, 0.44), tile: rgba(255, 255, 255, 0.4), sel: rgba(255, 255, 255, 0.5), chip: rgba(30, 27, 42, 0.08), sheen: 1 }
        }
    },

    // `glass: false` fallback: opaque-ish island, no gloss.
    solid: {
        dark: { bg: rgba(16, 14, 26, 0.78), tile: "#17161F", sel: "#1E1D28", chip: "#2C2A39", card: "#1F1E2A" },
        light: { bg: rgba(230, 226, 236, 0.78), tile: "#EFECF3", sel: "#F3F1F6", chip: "#DDD9E5", card: "#F3F1F6" }
    },

    // Gloss overlay.
    sheen: {
        dark: { top: rgba(255, 255, 255, 0.12), mid: rgba(255, 255, 255, 0.02), edge: rgba(255, 255, 255, 0.22), outline: rgba(255, 255, 255, 0.1), glow: rgba(255, 255, 255, 0.06) },
        light: { top: rgba(255, 255, 255, 0.38), mid: rgba(255, 255, 255, 0.06), edge: rgba(255, 255, 255, 0.75), outline: rgba(255, 255, 255, 0.35), glow: rgba(255, 255, 255, 0) }
    },

    shadow: {
        dark: { y: 18, blur: 60, color: rgba(10, 6, 20, 0.5) },
        light: { y: 18, blur: 50, color: rgba(40, 30, 70, 0.2) }
    },
    lockShadow: {
        dark: { y: 24, blur: 80, color: rgba(10, 6, 20, 0.45) },
        light: { y: 24, blur: 70, color: rgba(40, 30, 70, 0.25) }
    },
    lockWallpaper: {
        dark: { blur: 22, saturate: 1.2, brightness: 0.78, scale: 1.08 },
        light: { blur: 18, saturate: 1.2, brightness: 0.92, scale: 1.08 }
    },

    // Per-state extras, filled in by the state tasks.
    layout: {
        // Notification centre height terms (reference 3.5, R28). hMin/hMax mirror geom.center so
        // lib/notifs.js centerHeight() needs only this object.
        center: {
            hMin: 170, hMax: 620,
            pad: 14, header: 36, gap: 10, bottom: 16,
            groupHeader: 28, card: 64, cardGap: 6, groupGap: 12,
            stackPad1: 7, stackPad2: 14
        }
    }
};

function resolve(tokens, mode, level, glass) {
    var m = mode === "light" ? "light" : "dark";
    var p = tokens.palette[m];
    var mat = glass
        ? (tokens.glassLevels[level] || tokens.glassLevels["ciekłe"])[m]
        : tokens.solid[m];
    var sheen = tokens.sheen[m];
    var shadow = tokens.shadow[m];
    var lockShadow = tokens.lockShadow[m];
    var pick = function (v, fallback) { return v !== undefined ? v : fallback; };

    var fg = hex(p.fg);
    var fgMuted = hex(p.fgMuted);
    var sel = hex(mat.sel);
    var chip = hex(mat.chip);
    var tile = hex(mat.tile);
    var islandBg = hex(mat.bg);
    var accent = hex(p.accent);

    return {
        islandBg: islandBg,
        ring: hex(p.ring),
        shadowColor: hex(shadow.color),
        lockShadowColor: hex(lockShadow.color),
        tile: tile,
        sel: sel,
        hover: sel,
        card: hex(pick(mat.card, mat.sel)),
        chip: chip,
        track: hex(pick(p.track, mat.chip)),
        sliderFill: fg,
        fg: fg,
        fgMuted: fgMuted,
        fgDim: hex(p.fgDim),
        fgSoft: hex(pick(p.fgSoft, p.fg)),
        fgLock: hex(pick(p.fgLock, p.fgMuted)),
        accent: accent,
        accentSoft: withAlpha(accent, tokens.accentAlpha.soft),
        accentHalo: withAlpha(accent, tokens.accentAlpha.halo),
        focusRing: withAlpha(accent, tokens.accentAlpha.focus),
        onAccent: hex(p.onAccent),
        inverseBg: hex(p.inverseBg),
        inverseFg: hex(p.inverseFg),
        danger: hex(p.danger),
        dotInactive: hex(p.dotInactive),
        line: hex(p.line),
        divider: hex(p.divider),
        scrimDim: hex(p.scrimDim),
        lockField: hex(pick(p.lockField, mat.tile)),
        lockFieldRing: hex(p.lockFieldRing),
        lockGlass: hex(pick(p.lockGlass, mat.bg)),
        sheenTop: hex(sheen.top),
        sheenMid: hex(sheen.mid),
        sheenEdge: hex(sheen.edge),
        sheenOutline: hex(sheen.outline),
        sheenGlow: hex(sheen.glow),
        sheen: glass ? mat.sheen : 0,
        shadowY: shadow.y,
        shadowBlur: shadow.blur,
        shadowPad: shadow.blur + shadow.y,
        lockShadowY: lockShadow.y,
        lockShadowBlur: lockShadow.blur,
        lockWallpaper: clone(tokens.lockWallpaper[m])
    };
}
