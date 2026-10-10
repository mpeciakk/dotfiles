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

function radiusFor(h, cap) {
    return Math.min(h / 2, cap);
}

function geometry(state, geom, ctx) {
    var ears = state !== "line";
    if (state === "center") {
        var c = geom.center;
        var h = Math.max(c.hMin, Math.min(c.hMax, ctx.centerHeight));
        return { w: c.w, h: h, r: radiusFor(h, c.r), ears: ears };
    }
    if (state === "rest" || (state !== "line" && !(state in PRIORITY)))
        state = ctx.badge ? "restBadge" : "rest";
    var g = geom[state];
    return { w: g.w, h: g.h, r: g.r, ears: ears };
}
