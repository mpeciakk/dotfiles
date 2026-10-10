.pragma library

// Pure window-state helpers for niri's event stream. A window map is
// { id: window }; reducers never mutate their input and return the very same
// object for events they do not handle.

function withFocus(windows, id) {
    const out = {};
    for (const k of Object.keys(windows))
        out[k] = Object.assign({}, windows[k], { is_focused: windows[k].id === id });
    return out;
}

function reduceWindows(windows, ev) {
    if (ev.WindowsChanged) {
        const out = {};
        for (const win of ev.WindowsChanged.windows)
            out[win.id] = win;
        return out;
    }
    if (ev.WindowOpenedOrChanged) {
        const win = ev.WindowOpenedOrChanged.window;
        // niri does not send a separate focus change for the window that lost focus.
        const out = win.is_focused ? withFocus(windows, win.id) : Object.assign({}, windows);
        out[win.id] = win;
        return out;
    }
    if (ev.WindowClosed) {
        const out = Object.assign({}, windows);
        delete out[ev.WindowClosed.id];
        return out;
    }
    if (ev.WindowFocusChanged)
        return withFocus(windows, ev.WindowFocusChanged.id);
    if (ev.WindowFocusTimestampChanged) {
        const e = ev.WindowFocusTimestampChanged;
        if (!windows[e.id])
            return windows;
        return Object.assign({}, windows, {
            [e.id]: Object.assign({}, windows[e.id], { focus_timestamp: e.focus_timestamp })
        });
    }
    return windows;
}

// focus_timestamp is { secs, nanos } (or null/absent). Seconds are compared
// before nanos: secs * 1e9 stops being exact in a double after ~104 days of uptime.
function focusOrder(a, b) {
    const ta = a.focus_timestamp;
    const tb = b.focus_timestamp;
    if (ta && !tb)
        return -1;
    if (!ta && tb)
        return 1;
    if (ta && tb && (ta.secs !== tb.secs || ta.nanos !== tb.nanos))
        return ta.secs !== tb.secs ? tb.secs - ta.secs : tb.nanos - ta.nanos;
    return a.id - b.id;
}

// Most recently focused first; windows without a timestamp last; ties by id.
function sortWindows(windows) {
    return Object.keys(windows).map(k => windows[k]).sort(focusOrder);
}
