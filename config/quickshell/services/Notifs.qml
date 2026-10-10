pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../lib/notifs.js" as N

// Becomes the desktop notification daemon. Every notification is snapshotted into `history`
// (popups are not tracked; the island's toast and centre render from the snapshots).
// `unread` feeds the island badge, `series` the toast's "+N", `dnd` silences the toast only.
Singleton {
    id: root

    property var history: []          // snapshots {id, appName, summary, body, appIcon, image, time}, newest first, max 50
    readonly property var groups: N.group(root.history)
    readonly property var latest: root.history[0] ?? null
    property int unread: 0
    property int series: 0            // notifications since the toast opened
    property bool dnd: false

    signal arrived(var snap)

    // Negative ids for IPC-injected snapshots never collide with the server's.
    property int injected: 0

    // The single arrival path (D-Bus server and IPC).
    function push(snap: var): void {
        root.history = [snap].concat(root.history).slice(0, 50);
        root.unread += 1;
        if (!root.dnd)
            root.series += 1;
        root.arrived(snap);
    }

    function markRead(): void {
        root.unread = 0;
    }

    function resetSeries(): void {
        root.series = 0;
    }

    function keep(h: var): void {
        root.history = h;
        root.unread = Math.min(root.unread, h.length);
    }

    function dismiss(id: int): void {
        root.keep(root.history.filter(s => s.id !== id));
    }

    function dismissApp(app: string): void {
        root.keep(root.history.filter(s => s.appName !== app));
    }

    function clearAll(): void {
        root.keep([]);
    }

    NotificationServer {
        id: server

        keepOnReload: false
        bodySupported: true
        imageSupported: true
        actionsSupported: false

        onNotification: notif => {
            root.push({
                id: notif.id,
                appName: notif.appName ?? "",
                summary: notif.summary ?? "",
                body: notif.body ?? "",
                appIcon: notif.appIcon ?? "",
                image: notif.image ?? "",
                time: new Date()
            });
        }
    }

    IpcHandler {
        target: "notifs"

        readonly property int count: root.history.length
        readonly property int unread: root.unread
        readonly property bool dndOn: root.dnd

        function inject(app: string, summary: string, body: string): void {
            root.injected -= 1;
            root.push({ id: root.injected, appName: app, summary: summary, body: body, appIcon: "", image: "", time: new Date() });
        }

        function dnd(on: bool): void {
            root.dnd = on;
        }

        function clear(): void {
            root.clearAll();
        }
    }
}
