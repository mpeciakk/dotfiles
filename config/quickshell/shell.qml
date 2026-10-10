import QtQuick
import Quickshell
import "services"

ShellRoot {
    settings.watchFiles: true

    // Referenced once so the singletons load at startup: IslandState (and its IPC handler),
    // and Niri, whose event stream must have delivered the focused workspace before the first request.
    Component.onCompleted: {
        IslandState.current;
        Niri.focusedId;
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
