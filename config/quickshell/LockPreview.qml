import QtQuick
import QtQuick.Effects
import Quickshell
import "states" as States

// The lock card for screenshots, WITHOUT locking (tests/smoke/19-lock-preview.sh): an ordinary window with the
// card over the wallpaper blurred as the lock screen blurs it (Theme.lockWallpaper, at its locked end). No
// WlSessionLock, no PAM, nothing of IslandState's lock path: a submitted password goes nowhere.
// It lives next to shell.qml because Quickshell resolves the root singletons (Theme) only inside the folder of
// the file it runs. Run: qs -p <config dir>/LockPreview.qml -d
ShellRoot {
    FloatingWindow {
        id: win

        readonly property var wp: Theme.lockWallpaper

        title: "Wyspa lock preview"
        // Twice the card: room to show the blurred wallpaper round it.
        implicitWidth: Theme.geom.lock.w * 2
        implicitHeight: Theme.geom.lock.h * 2
        // Fixed size: niri opens the window floating, centred.
        minimumSize: Qt.size(win.implicitWidth, win.implicitHeight)
        maximumSize: Qt.size(win.implicitWidth, win.implicitHeight)
        color: "black"

        Item {
            anchors.fill: parent
            clip: true

            Image {
                anchors.fill: parent
                source: Theme.wallpaper ? "file://" + Theme.wallpaper : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                scale: win.wp.scale
                layer.enabled: true
                layer.effect: MultiEffect {
                    autoPaddingEnabled: false
                    blurEnabled: true
                    blur: 1
                    blurMax: win.wp.blur
                    saturation: win.wp.saturate - 1
                    brightness: win.wp.brightness - 1
                }
            }
        }

        States.LockCard {
            anchors.centerIn: parent
            width: Theme.geom.lock.w
            height: Theme.geom.lock.h
            onSubmitted: console.info("lock preview: submitted, nothing authenticates")
        }
    }
}
