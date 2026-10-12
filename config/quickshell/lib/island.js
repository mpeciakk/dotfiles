.pragma library

var PRIORITY = { rest: 0, media: 1, osd: 2, toast: 3, control: 4, power: 4, center: 4, powerDone: 4, launcher: 5 };

var MODAL = { launcher: true, control: true, power: true, center: true };

// Can the island leave `current` for `next`? Returning to rest is always allowed.
function accepts(current, next) {
    if (next === "rest") return true;
    if (!(next in PRIORITY)) return false;
    return PRIORITY[next] >= PRIORITY[current];
}

function isModal(state) {
    return state in MODAL;
}

// A modal state whose output is gone (unplugged): no surface is left to show it or to close it.
function stranded(state, output, outputNames) {
    return isModal(state) && outputNames.indexOf(output) < 0;
}

function radiusFor(h, cap) {
    return Math.min(h / 2, cap);
}

// `ctx.notch` ({ w, h } or null): the output has a notch. Rest sits beside it, as tall as it; every other state
// except the line grows by its height and offsets its content (`top`) below it.
function geometry(state, geom, ctx) {
    var ears = state !== "line";
    var notch = state === "line" ? null : ctx.notch;
    var top = notch ? notch.h : 0;
    if (state === "center") {
        var c = geom.center;
        var ch = Math.max(c.hMin, Math.min(c.hMax, ctx.centerHeight)) + top;
        return { w: c.w, h: ch, r: radiusFor(ch, c.r), ears: ears, top: top };
    }
    if (state === "rest" || (state !== "line" && !(state in PRIORITY)))
        state = ctx.badge ? "restBadge" : "rest";
    var g = geom[state];
    if (notch && (state === "rest" || state === "restBadge"))
        return { w: notch.w + 2 * geom.notchSide + (g.w - geom.rest.w), h: notch.h, r: notch.h / 2, ears: ears, top: 0 };
    return { w: g.w, h: g.h + top, r: g.r, ears: ears, top: top };
}

// The strip tiled windows leave at the top of an output: the notch height there (kept while hidden, given back
// only by a fullscreen window), else geom.exclusive, given back in line mode (fullscreen or hidden).
function exclusiveZone(geom, notch, fullscreen, hidden) {
    if (notch)
        return fullscreen ? 0 : notch.h;
    return fullscreen || hidden ? 0 : geom.exclusive;
}

// The OSD icon: a sun for brightness; for volume by mute, level and `highFrom`.
function osdIcon(kind, value, muted, highFrom) {
    if (kind === "brightness")
        return "sun";
    if (muted || value <= 0)
        return "volume-x";
    return value >= highFrom ? "volume-2" : "volume-1";
}
