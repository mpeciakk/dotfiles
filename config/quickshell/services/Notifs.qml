pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../lib/notifs.js" as N

// Becomes the desktop notification daemon. Every notification that is not `transient` is snapshotted into `history`
// and stays `tracked` (its Notification object alive) while its card is there: a replacement from the app
// (`replaces_id`) then arrives as property changes on that object (no new `notification` signal) and updates the card
// in place; a card the user or the cap removes calls `dismiss()` on the object; a close by the app removes the card.
// A transient notification is toast only: not in `history`, not in `unread`.
// `unread` feeds the island badge, `series` the toast's "+N", `dnd` silences the toast only.
Singleton {
    id: root

    property var history: []          // snapshots {id, appName, summary, body, appIcon, image, time}, newest first, max 50
    readonly property var groups: N.group(root.history)
    property var latest: null         // the newest snapshot, a transient one included: what the toast shows
    property int unread: 0
    property int series: 0            // notifications since the toast opened
    property bool dnd: false

    // id -> Notification of every card in `history` that came from the server (a plain object, not reactive).
    property var tracked: ({})

    signal arrived(var snap)

    // Negative ids for IPC-injected snapshots never collide with the server's.
    property int injected: 0

    // What the toast announces: the newest snapshot and the series. Every arrival goes through it.
    function announce(snap: var): void {
        root.latest = snap;
        if (!root.dnd)
            root.series += 1;
        root.arrived(snap);
    }

    // The arrival path of a notification that goes into the history (D-Bus server and IPC).
    function push(snap: var): void {
        const c = N.cap(N.replaceById(root.history, snap), 50);
        root.release(c.dropped);
        root.history = c.kept;
        root.unread = N.clampUnread(root.unread + 1, c.kept.length);
        root.announce(snap);
    }

    // The app replaced a card: same card, new content, on top. Not an arrival (no series, no unread, no `arrived`).
    function refresh(notif: var): void {
        if (root.tracked[notif.id] !== notif)
            return;
        const snap = root.snapshot(notif);
        root.history = N.replaceById(root.history, snap);
        root.latest = snap;
    }

    // dismiss() on the objects of cards that leave by our choice (the user, the cap).
    function release(ids: var): void {
        for (const id of ids) {
            const notif = root.tracked[id];
            delete root.tracked[id];
            if (notif)
                notif.dismiss();
        }
    }

    // The app closed the notification: the card goes, nothing is called back on the object. Our own dismiss()
    // closes it too, but release() has forgotten the object by then and its card is handled by the caller.
    function forget(id: int): void {
        if (!(id in root.tracked))
            return;
        delete root.tracked[id];
        root.keep(N.removeById(root.history, id));
    }

    function snapshot(notif: var): var {
        return {
            id: notif.id,
            appName: notif.appName ?? "",
            summary: notif.summary ?? "",
            body: notif.body ?? "",
            appIcon: notif.appIcon ?? "",
            image: notif.image ?? "",
            time: new Date()
        };
    }

    function markRead(): void {
        root.unread = 0;
    }

    function resetSeries(): void {
        root.series = 0;
    }

    function keep(h: var): void {
        root.history = h;
        root.unread = N.clampUnread(root.unread, h.length);
    }

    function dismiss(id: int): void {
        root.release([id]);
        root.keep(N.removeById(root.history, id));
    }

    function dismissApp(app: string): void {
        root.release(root.history.filter(s => s.appName === app).map(s => s.id));
        root.keep(root.history.filter(s => s.appName !== app));
    }

    function clearAll(): void {
        root.release(root.history.map(s => s.id));
        root.keep([]);
    }

    NotificationServer {
        id: server

        keepOnReload: false
        bodySupported: true
        imageSupported: true
        actionsSupported: false

        onNotification: notif => {
            const snap = root.snapshot(notif);
            if (notif.transient) {
                root.announce(snap);
                return;
            }
            notif.tracked = true;
            root.tracked[notif.id] = notif;
            for (const prop of ["appName", "appIcon", "summary", "body", "image"])
                notif[prop + "Changed"].connect(() => root.refresh(notif));
            notif.closed.connect(() => root.forget(notif.id));
            root.push(snap);
        }
    }

    IpcHandler {
        target: "notifs"

        readonly property int count: root.history.length
        readonly property int unread: root.unread
        readonly property string top: root.history[0]?.summary ?? ""
        readonly property int series: root.series
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
