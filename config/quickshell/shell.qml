import QtQuick
import Quickshell

ShellRoot {
    settings.watchFiles: true

    Variants {
        model: Quickshell.screens

        Wallpaper {}
    }
}
