.pragma library

// Control-panel slider arithmetic. Pure: no imports, no QML types, tested under node.

var NOTCH = 120;   // angleDelta of one wheel notch; touchpads send many smaller deltas per gesture

function clamp(f, min) {
    return Math.max(min, Math.min(1, f));
}

// The new fraction after a wheel event, or null when nothing should change. `current` is the real
// value (not the displayed fill: a muted volume still has its stored level), the change is
// `step * angleDeltaY / 120`, so smooth scrolling moves proportionally. A zero or missing delta
// (horizontal tilt) is ignored. The result never moves against the wheel: a value above 1
// (overamplified volume) is left alone by wheel-up and capped to 1 by wheel-down, one below `min`
// (a brightness floor) is left alone by wheel-down.
function wheelFraction(current, angleDeltaY, step, min) {
    if (!angleDeltaY || !isFinite(angleDeltaY) || !isFinite(current))
        return null;
    var next = clamp(current + step * angleDeltaY / NOTCH, min);
    if ((angleDeltaY > 0 && next < current) || (angleDeltaY < 0 && next > current))
        return null;
    return next;
}

// The fraction under the pointer at `x` on a track `width` wide, within [min, 1]; null without a width.
function dragFraction(x, width, min) {
    if (!(width > 0) || !isFinite(x))
        return null;
    return clamp(x / width, min);
}

// A leading-and-trailing throttle for a slow, unordered sink (brightnessctl): the first request is
// sent at once, later ones only keep the last value pending until the next tick, and a release
// flushes what is pending. State: {pending, cooling, last}; each step returns {state, send} with
// `send` the value to hand to the sink or null. `last` is the last requested value.
function idle() {
    return { pending: null, cooling: false, last: null };
}

function request(state, value) {
    if (!state.cooling)
        return { state: { pending: null, cooling: true, last: value }, send: value };
    return { state: { pending: value, cooling: true, last: value }, send: null };
}

// The cooldown timer fired: send what is pending (and keep cooling), or end the cooldown.
function tick(state) {
    if (state.pending !== null)
        return { state: { pending: null, cooling: true, last: state.last }, send: state.pending };
    return { state: { pending: null, cooling: false, last: state.last }, send: null };
}

// The pointer was released: send what is pending now.
function flush(state) {
    return { state: { pending: null, cooling: state.cooling, last: state.last }, send: state.pending };
}

// Where a wheel step starts: the last requested value while a request is cooling, else the real one.
function base(state, real) {
    return state.cooling ? state.last : real;
}
