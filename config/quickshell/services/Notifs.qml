pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Becomes the desktop notification daemon. `list` is the currently-shown
// (tracked) notifications driving the popups; `history` is a kept log of every
// notification (snapshotted so it survives expiry/dismissal) for the
// notification center. `dnd` suppresses popups (the notification still lands in
// history) — swaync-style.
Singleton {
    id: root

    readonly property alias list: server.trackedNotifications
    readonly property int count: list.values.length

    property bool dnd: false
    property var history: []          // snapshots, newest first

    // Enabling DND also dismisses the popups already on screen (not just future).
    onDndChanged: {
        if (root.dnd)
            for (const n of root.list.values)
                n.tracked = false;
    }

    function clearHistory(): void {
        root.history = [];
    }
    // Remove by identity (the history array mutates while the center is open, so
    // a captured index could point at the wrong card).
    function removeItem(item: var): void {
        const i = root.history.indexOf(item);
        if (i < 0)
            return;
        const h = root.history.slice();
        h.splice(i, 1);
        root.history = h;
    }

    NotificationServer {
        id: server

        keepOnReload: false
        bodySupported: true
        imageSupported: true
        actionsSupported: false

        onNotification: notif => {
            // Snapshot for history (kept after the popup is gone).
            root.history = [
                {
                    appName: notif.appName ?? "",
                    summary: notif.summary ?? "",
                    body: notif.body ?? "",
                    appIcon: notif.appIcon ?? "",
                    time: new Date()
                }
            ].concat(root.history).slice(0, 50);

            // Show the popup unless Do Not Disturb is on.
            if (!root.dnd)
                notif.tracked = true;
        }
    }
}
