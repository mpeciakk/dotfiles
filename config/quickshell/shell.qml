import QtQuick
import Quickshell

ShellRoot {
    settings.watchFiles: true

    // Referenced once so the singleton (and its IPC handler) loads at startup.
    Component.onCompleted: IslandState.current

    Variants {
        model: Quickshell.screens

        Wallpaper {}
    }
}
