import QtQuick
import Quickshell
import "services"

ShellRoot {
    settings.watchFiles: true

    // Referenced once so the singletons load at startup: IslandState (and its IPC handler),
    // Niri, whose event stream must have delivered the focused workspace before the first request,
    // Apps, whose DesktopEntries load asynchronously (a first launcher query would find none), and
    // Fullscreen, whose toplevel list fills asynchronously (detection must be live from the start), and
    // AutoTheme, which feeds Theme the automatic mode and the legibility boost (nothing else reads it).
    Component.onCompleted: {
        IslandState.current;
        Niri.focusedId;
        Apps.list;
        Fullscreen.outputs;
        AutoTheme.mode;
    }

    // The session lock: one WlSessionLock, which makes its own surface per screen.
    Lock {}

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
