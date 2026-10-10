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

// The picture of a notification (R30): its image, else its appIcon (a path or file:// / image:// URL
// as is, a theme icon name through `iconPath`), else "" for the initial fallback.
function iconSource(snap, iconPath) {
    if (snap.image)
        return snap.image;
    if (!snap.appIcon)
        return "";
    if (snap.appIcon.charAt(0) === "/" || /^(file|image):\/\//.test(snap.appIcon))
        return snap.appIcon;
    return iconPath(snap.appIcon);
}

// The same for a stored snapshot, which outlives its Notification: the image://qsimage/ URL of it is dead
// by then, any other image (path, image://icon/...) is not.
function storedSource(snap, iconPath) {
    var image = /^image:\/\/qsimage\//.test(snap.image) ? "" : snap.image;
    return iconSource({ image: image, appIcon: snap.appIcon }, iconPath);
}
