.pragma library

// Notification history helpers (reference 3.5, 4.3, R28, R30).

// items newest-first -> [{app, items}]: groups ordered by their newest item, items newest-first.
function group(items) {
    var out = [];
    var byApp = {};
    for (var i = 0; i < items.length; i++) {
        var app = items[i].appName;
        if (!Object.prototype.hasOwnProperty.call(byApp, app)) {
            byApp[app] = { app: app, items: [] };
            out.push(byApp[app]);
        }
        byApp[app].items.push(items[i]);
    }
    return out;
}

// Height of the notification centre. `expanded` maps app -> bool; `L` = layout.center tokens.
function centerHeight(groups, expanded, L) {
    if (groups.length === 0)
        return L.hMin;
    var listH = L.groupGap * (groups.length - 1);
    for (var i = 0; i < groups.length; i++) {
        var n = groups[i].items.length;
        var open = expanded[groups[i].app] === true;
        var shown = open ? n : 1;
        var pad = open || n < 2 ? 0 : (n > 2 ? L.stackPad2 : L.stackPad1);
        listH += L.groupHeader + shown * L.card + (shown - 1) * L.cardGap + pad;
    }
    return Math.min(L.hMax, L.pad + L.header + L.gap + listH + L.bottom);
}

// Stable hash of the app name -> one of `colors`.
function appColor(appName, colors) {
    var h = 0;
    for (var i = 0; i < appName.length; i++)
        h = (h * 31 + appName.charCodeAt(i)) >>> 0;
    return colors[h % colors.length];
}

function initial(appName) {
    return appName.length > 0 ? appName.charAt(0).toUpperCase() : "?";
}
