import QtQuick
import Quickshell
import "./modules"
import "./components"

ShellRoot {
    id: root

    Variants {
        model: Quickshell.screens
        delegate: Bar {
            leftItems: [
                Workspaces {}
            ]
            centerItems: [
                DynamicIsland {}
            ]
            rightItems: [
                DateTime {}
            ]
        }
    }
}
