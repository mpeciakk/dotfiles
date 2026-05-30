import Quickshell
import QtQuick
import "modules"

ShellRoot {
    settings.watchFiles: true

    Variants {
        model: Quickshell.screens

        Bar {}
    }

    Variants {
        model: Quickshell.screens

        Border {}
    }

    LauncherPanel {}

    NotificationPanel {}
}
