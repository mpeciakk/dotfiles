import QtQuick
import Quickshell
import "services"

ShellRoot {
    settings.watchFiles: true

    // Referenced once so the singletons load at startup: IslandState (and its IPC handler),
    // Niri, whose event stream must have delivered the focused workspace before the first request,
    // and Apps, whose DesktopEntries load asynchronously (a first launcher query would find none).
    Component.onCompleted: {
        IslandState.current;
        Niri.focusedId;
        Apps.list;
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen

            required property var modelData

            Wallpaper { modelData: perScreen.modelData }
            Strut { modelData: perScreen.modelData }
            Island { modelData: perScreen.modelData }
        }
    }
}
