pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Becomes the desktop notification daemon and exposes the currently-shown
// notifications as `list`. Notifications are kept ("tracked") until they expire
// or are dismissed.
Singleton {
    id: root

    readonly property alias list: server.trackedNotifications
    readonly property int count: list.values.length

    NotificationServer {
        id: server

        keepOnReload: false
        bodySupported: true
        imageSupported: true
        actionsSupported: false

        onNotification: notif => {
            notif.tracked = true;
        }
    }
}
