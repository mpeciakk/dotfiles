import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../components"
import "../services"

// The app launcher as a centred notch on the primary screen, toggled over IPC:
//   qs ipc call launcher toggle
// Bind that to a key in niri to open it. One instance (in shell.qml), not per
// monitor, so there's a single IPC target and keyboard grab.
Drawer {
    id: panel

    screen: Quickshell.screens[0] ?? null
    modal: true
    keyboardFocus: WlrKeyboardFocus.OnDemand
    anchorX: screen ? screen.width / 2 : 0

    onShownChanged: shown ? launcher.activate() : launcher.reset()

    Launcher {
        id: launcher

        onClose: panel.close()
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            panel.toggle();
        }
        function open(): void {
            panel.open();
        }
        function close(): void {
            panel.close();
        }
    }
}
