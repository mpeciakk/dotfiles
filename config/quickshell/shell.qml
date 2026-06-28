import Quickshell
import Quickshell.Io
import QtQuick
import "modules"
import "services"

ShellRoot {
    id: root

    settings.watchFiles: true

    // Global launcher state. The per-monitor LauncherPanels below open only on
    // the output the user is on (captured when toggled), so the single keyboard
    // grab lands on the active monitor without ever moving a layer surface
    // between outputs (which is slow and drops keyboard focus on niri).
    property bool launcherOpen: false
    property string launcherOutput: ""
    property string launcherMenu: ""     // non-empty ⇒ open straight into this menu

    Variants {
        model: Quickshell.screens

        Wallpaper {}
    }

    // Before Bar so the static frame draws under the bar (same Top layer).
    Variants {
        model: Quickshell.screens

        Border {}
    }

    Variants {
        model: Quickshell.screens

        Bar {}
    }

    Variants {
        model: Quickshell.screens

        Osd {}
    }

    Variants {
        model: Quickshell.screens

        LauncherPanel {
            active: root.launcherOpen && screen !== null && screen.name === root.launcherOutput
            startMenu: root.launcherMenu
            onClosedByUser: root.launcherOpen = false
        }
    }

    NotificationPanel {}

    Lock {}

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            if (root.launcherOpen) {
                root.launcherOpen = false;
            } else {
                root.launcherMenu = "";
                root.launcherOutput = Niri.focusedOutput;
                root.launcherOpen = true;
            }
        }
        function open(): void {
            root.launcherMenu = "";
            root.launcherOutput = Niri.focusedOutput;
            root.launcherOpen = true;
        }
        function close(): void {
            root.launcherOpen = false;
        }
        // Open straight into a registered menu, e.g. `qs ipc call launcher menu vpn`.
        function menu(id: string): void {
            root.launcherMenu = id;
            root.launcherOutput = Niri.focusedOutput;
            root.launcherOpen = true;
        }
    }
}
