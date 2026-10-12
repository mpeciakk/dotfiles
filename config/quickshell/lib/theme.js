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

// The colour with its alpha raised by `by` (0..1), at most opaque.
function raiseAlpha(c, by) {
    return withAlpha(c, Math.min(1, parseInt(hex(c).slice(1, 3), 16) / 255 + by));
}

function isObject(x) {
    return x !== null && typeof x === "object" && !Array.isArray(x);
}

function positive(x) {
    return typeof x === "number" && isFinite(x) && x > 0;
}

// The notch of `output` from the host config's `notch` ({ "<output>": { w, h } }, logical px): { w, h }, or null
// when there is none (missing key, missing output, anything that is not two positive numbers).
function notchFor(hostNotch, output) {
    if (!isObject(hostNotch) || !Object.prototype.hasOwnProperty.call(hostNotch, output))
        return null;
    var n = hostNotch[output];
    return isObject(n) && positive(n.w) && positive(n.h) ? { w: n.w, h: n.h } : null;
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
    // Dark island over wallpaper brighter than `threshold`: alpha + `boost`. Light island over wallpaper darker than
    // `lightThreshold`: alpha + `lightBoost`. sampleSize: px the wallpaper is rescaled to for sampling.
    legibility: { threshold: 0.7, boost: 0.2, lightThreshold: 0.25, lightBoost: 0.18, sampleSize: 64 },
    glass: true,
    glassLevel: "ciekłe",           // "subtelne" | "mocne" | "ciekłe"
    reducedMotion: false,

    fonts: { ui: "JetBrainsMono Nerd Font", mono: "JetBrainsMono Nerd Font" },

    // shadowFullH: island height from which the shadow is full size; a lower island gets a proportionally smaller one.
    sizes: { iconStroke: 1.6, iconGrid: 24, ringWidth: 1, clockRest: 13, shadowFullH: 160 },

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
        notchSide: 124,         // rest beside a notch: each side of it (12 workspace dots left, clock + eq + badge right)
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
        exitCurve: [0.2, 0, 0, 1, 1, 1],    // fast start: the old content is mostly gone before the morph has grown much
        easeCurve: [0.25, 0.1, 0.25, 1, 1, 1],
        shakeCurve: [0.36, 0.07, 0.19, 0.97, 1, 1],
        lockMorphMs: 640,
        wallpaperMs: 700,
        themeFadeMs: 600,
        enterOpacityMs: 220,
        enterOpacityDelayMs: 160,
        enterScaleMs: 320,
        enterScaleDelayMs: 120,
        enterBlurMs: 220,
        enterBlurDelayMs: 160,
        exitOpacityMs: 80,
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

    // The session lock: idle-lock timeout in seconds when the host config has no lock.timeout (0 there disables it).
    lock: { timeoutDefault: 300 },

    // What the power menu runs (reference 3.8); overridable under "island.power.commands". The lock has no
    // command: it asks the session lock. Only components/PowerActions.qml perform() ever reads these.
    power: {
        commands: {
            suspend: ["systemctl", "suspend"],
            logout: ["niri", "msg", "action", "quit", "--skip-confirmation"],
            reboot: ["systemctl", "reboot"],
            poweroff: ["systemctl", "poweroff"]
        }
    },

    // Colours that do not depend on the glass level. Omitted keys are derived in
    // resolve(): fgSoft = fg, fgLock = fgMuted, track = chip, lockField = tile,
    // lockGlass = islandBg.
    // `accentAlternatives` + `accent` are the four app colours of notification icons (R30).
    palette: {
        dark: {
            ring: rgba(255, 255, 255, 0.07),
            fg: "#ECEAF2",
            fgMuted: "#A29DB3",
            fgDim: "#8B8699",
            fgLock: "#CFC8E0",
            accent: "#B9A7F5",
            accentAlternatives: ["#F1D6AE", "#8FD3C1", "#F2A7B8"],
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
            ring: rgba(255, 255, 255, 0.3),
            fg: "#1E1B2A",
            fgMuted: "#48435C",
            fgDim: "#5C5770",
            accent: "#4E3A9E",
            accentAlternatives: ["#8A5A1E", "#2F7A68", "#A23D5C"],
            onAccent: "#FFFFFF",
            inverseBg: "#1E1B2A",
            inverseFg: "#EFECF3",
            danger: "#B4405E",
            dotInactive: "#6E6984",
            line: rgba(30, 27, 42, 0.55),
            divider: "#D6D2DF",
            scrimDim: rgba(40, 30, 70, 0.22),
            track: "#CFCADA",
            lockFieldRing: rgba(30, 27, 42, 0.08)
        }
    },

    // Alpha of the colours derived from `accent`.
    accentAlpha: { soft: 0.18, halo: 0.2, focus: 0.9 },

    // Per glass level and theme. `card` falls back to `sel`.
    glassLevels: {
        "subtelne": {
            dark: { bg: rgba(16, 14, 26, 0.62), tile: "#17161F", sel: "#1E1D28", chip: "#2C2A39", card: "#1F1E2A" },
            light: { bg: rgba(230, 226, 236, 0.8), tile: "#EFECF3", sel: "#F3F1F6", chip: "#DDD9E5", card: "#F3F1F6" }
        },
        "mocne": {
            dark: { bg: rgba(16, 14, 26, 0.4), tile: rgba(255, 255, 255, 0.06), sel: rgba(255, 255, 255, 0.1), chip: rgba(255, 255, 255, 0.12) },
            light: { bg: rgba(232, 228, 238, 0.58), tile: rgba(255, 255, 255, 0.42), sel: rgba(255, 255, 255, 0.52), chip: rgba(30, 27, 42, 0.08) }
        },
        "ciekłe": {
            dark: { bg: rgba(22, 18, 36, 0.28), tile: rgba(255, 255, 255, 0.07), sel: rgba(255, 255, 255, 0.12), chip: rgba(255, 255, 255, 0.14) },
            light: { bg: rgba(234, 230, 240, 0.44), tile: rgba(255, 255, 255, 0.4), sel: rgba(255, 255, 255, 0.5), chip: rgba(30, 27, 42, 0.08) }
        }
    },

    // `glass: false` fallback: opaque-ish island, no blur.
    solid: {
        dark: { bg: rgba(16, 14, 26, 0.78), tile: "#17161F", sel: "#1E1D28", chip: "#2C2A39", card: "#1F1E2A" },
        light: { bg: rgba(230, 226, 236, 0.78), tile: "#EFECF3", sel: "#F3F1F6", chip: "#DDD9E5", card: "#F3F1F6" }
    },

    shadow: {
        dark: { y: 12, blur: 36, color: rgba(10, 6, 20, 0.38) },
        light: { y: 10, blur: 30, color: rgba(20, 16, 30, 0.16) }
    },
    lockShadow: {
        dark: { y: 24, blur: 80, color: rgba(10, 6, 20, 0.45) },
        light: { y: 24, blur: 70, color: rgba(40, 30, 70, 0.25) }
    },
    lockWallpaper: {
        dark: { blur: 12, saturate: 1, brightness: 1, scale: 1.08 },
        light: { blur: 10, saturate: 1, brightness: 1, scale: 1.08 }
    },

    // Per-state extras, filled in by the state tasks.
    layout: {
        // Rest (reference 3.1). eqDelayMs are the bars' phase offsets in the eq cycle.
        rest: {
            gap: 14, dotsGap: 4, dot: 5, dotActiveW: 14, dotRadius: 3,
            eqGap: 2, eqH: 12, eqBarW: 2, eqScaleMin: 0.35, eqDelayMs: [0, -300, -600],
            badgeGap: 5, badgeH: 22, badgePad: 8, badgeRadius: 11, badgeFont: 11, badgeIcon: 12
        },
        // OSD (reference 3.2). volumeHighFrom: volume at or above this shows volume-2, below it volume-1
        // (the 3-level split is unspecified in the reference).
        osd: {
            padX: 16, gap: 12, icon: 18, barH: 6, barRadius: 3, valueW: 28, valueFont: 12, volumeHighFrom: 0.5, percent: 100
        },
        // Toast (reference 3.4 variant B, R26). iconImage: size of an image / app icon inside the icon box
        // (unspecified in the reference); barInset/barH: the progress bar.
        toast: {
            padX: 16, gap: 14, icon: 44, iconRadius: 14, iconImage: 28, iconLetter: 16, textGap: 2,
            titleFont: 14, bodyFont: 12, chipH: 24, chipPad: 9, chipRadius: 12, chipFont: 11,
            barInset: 30, barH: 2
        },
        // Notification centre (reference 3.5, R28). The first block is the height terms of
        // lib/notifs.js centerHeight(); hMin/hMax mirror geom.center (the caller merges the live
        // geom.center bounds over them). groupHeader = groupHeadH + the gap below it.
        // cardIconImage and scrollW are unspecified in the reference.
        center: {
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
        },
        // Launcher (reference 3.6, R29). Unspecified in the reference: rowGap, iconImage, iconGlyph, dot,
        // emptyFont and the menu refresh (refreshes re-lists, refreshMs apart, after a command that stays open).
        launcher: {
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
        },
        // Control panel (reference 3.7, R24). clockLetterEm is the clock's letter-spacing in em; hitH is the
        // pointer target of a slider track and wheelStep the slider change per wheel notch (both unspecified);
        // toggleCols is the grid of the round toggles (3 toggles sit centred in it). brightnessThrottleMs is the
        // pause between brightnessctl calls while dragging or scrolling the brightness slider; brightnessMin is
        // the lowest fraction the slider can set. The reference is silent on both: the throttle avoids a
        // process per mouse move, the floor (many panels switch the backlight off at 0%) is a safety choice
        // the user can change.
        control: {
            pad: 16, gap: 10,
            headPadX: 6, headPadTop: 2, headPadBottom: 4, clockFont: 44, clockLetterEm: -0.03, dateFont: 13, dateGap: 2,
            tilePad: 12, tileGap: 10, tileCircle: 38, tileIcon: 17, tileTitleFont: 14, tileSubFont: 12, tileTextGap: 1,
            cardPadX: 14, cardPadY: 16, cardGap: 16, sliderGap: 12, sliderIcon: 17, trackH: 6, trackRadius: 3,
            valueW: 28, valueFont: 12, hitH: 24, wheelStep: 0.05, percent: 100, brightnessThrottleMs: 50, brightnessMin: 0.05,
            toggleCols: 4, togglePadY: 2, toggleGap: 6, toggle: 50, toggleIcon: 18, toggleLabelFont: 11
        },
        // Mini player (reference 3.7; prev/next sizes from 3.3), shared by the control panel and the lock screen.
        miniPlayer: {
            pad: 10, gap: 12, art: 40, artRadius: 12, textGap: 1, titleFont: 13, artistFont: 12,
            play: 38, playIcon: 14, skip: 32, skipIcon: 15, disabledOpacity: 0.4
        },
        // Media (reference 3.3). What it shares with the mini player (padding, gap, fonts, prev/next sizes) is
        // read from layout.miniPlayer; only what differs is here. The reference gives no eq scale range (the
        // rest eq's 0.35 is reused) and no size for the "Nic nie gra" placeholder (emptyFont).
        media: {
            art: 36, artRadius: 10, play: 36,
            eqGap: 2, eqH: 14, eqBarW: 2, eqMarginRight: 4, eqScaleMin: 0.35, eqDelayMs: [0, -200, -500, -700],
            emptyFont: 13
        },
        // Power menu (reference 3.8). The ring is an arc of radius ringRadius round the circle, starting at
        // ringStart degrees (12 o'clock) and sweeping ringSweep degrees when full. The focus ring (focusGap
        // outside the circle) is the keyboard focus (R22).
        power: {
            padTop: 16, padX: 18, padBottom: 18, gap: 14, headPadX: 4, titleFont: 14, hintFont: 12,
            gridGap: 8, buttonGap: 8, buttonPadY: 4, circle: 60, icon: 20,
            ringRadius: 28, ringWidth: 2.5, ringStart: -90, ringSweep: 360,
            labelFont: 12, keyFont: 10, focusWidth: 1.5, focusGap: 4, focusRadius: 18
        },
        // powerDone (reference 3.9): the "prototyp" demo marker is dropped.
        powerDone: {
            padX: 20, gap: 12, dot: 10, dotRadius: 5, haloWidth: 4, labelFont: 14
        },
        // Lock screen (reference 3.10, 4.6, R21, R32). The card is geom.lock; shakeSteps are the shake's x offsets,
        // one per shakeMs/5 step. Content enters after enterDelayMs (opacity, blur) and scales enterScaleLeadMs
        // earlier; exits have no delay. edge: the mini player's and the corner buttons' distance from the screen
        // edge; ringRadius: the hold ring round a corner button (its width, start and sweep come from layout.power).
        // The extras (mini player, corner buttons) fade in after extrasDelayMs and out at once.
        lock: {
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
            extrasDelayMs: 520, extrasMs: 300,
            // The unlock hand-off (DESIGN W12, reference LockLive): the lock goes handoffMs after the password is
            // accepted (0: at once, the overlay's first frame is the lock's look); from then the wallpaper fades out from
            // deskDelayMs over deskMs and the ears and the island come in from earDelayMs over earMs.
            handoffMs: 0, deskDelayMs: 240, deskMs: 420, earDelayMs: 420, earMs: 200,
            // Below this lock morph the card's rounded top corners have become the island's ears (lib/lock.js dock()).
            dockAt: 0.05
        }
    }
};

function resolve(tokens, mode, level, glass) {
    var m = mode === "light" ? "light" : "dark";
    var p = tokens.palette[m];
    var mat = glass
        ? (tokens.glassLevels[level] || tokens.glassLevels["ciekłe"])[m]
        : tokens.solid[m];
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
        appColors: [accent].concat(p.accentAlternatives.map(hex)),
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
        shadowY: shadow.y,
        shadowBlur: shadow.blur,
        shadowPad: shadow.blur + shadow.y,
        lockShadowY: lockShadow.y,
        lockShadowBlur: lockShadow.blur,
        lockWallpaper: clone(tokens.lockWallpaper[m])
    };
}
