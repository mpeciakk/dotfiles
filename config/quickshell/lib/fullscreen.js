.pragma library

// Which outputs show a fullscreen window right now. The Wayland toplevels know `fullscreen` and the
// screens a window is on but not its workspace; niri's windows know the workspace but not `fullscreen`.
// They are joined on title + appId (the only key the two share). An output counts when some fullscreen
// toplevel on it matches a niri window sitting on that output's ACTIVE workspace: a fullscreen window on a
// workspace the user has scrolled away from must not collapse the island. Two windows with the same title
// and appId are ambiguous, so any match on the active workspace is enough.
function fullscreenOutputs(toplevels, windows, activeByOutput) {
    var active = activeByOutput || {};
    var out = [];
    for (var t of toplevels || []) {
        if (!t || !t.fullscreen)
            continue;
        var twins = (windows || []).filter(w => w && w.title === t.title && w.app_id === t.appId);
        for (var name of t.screens || [])
            if (active[name] != null && !out.includes(name) && twins.some(w => w.workspace_id === active[name]))
                out.push(name);
    }
    return out;
}
