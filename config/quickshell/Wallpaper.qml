import QtQuick
import Quickshell
import Quickshell.Wayland

// Desktop wallpaper, one per screen (Variants in shell.qml). A click-through
// background layer-shell window showing Theme.wallpaper. Replaces swaybg — stop
// the external wallpaper daemon so they don't stack.
PanelWindow {
    id: root

    property var modelData
    screen: modelData

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell-wallpaper"   // matched by niri's place-within-backdrop layer-rule
    exclusionMode: ExclusionMode.Ignore
    color: "black"

    Image {
        anchors.fill: parent
        source: Theme.wallpaper ? "file://" + Theme.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        // Decode at the monitor's physical resolution, not the file's native size
        // (a 4K wallpaper on a 1080p output would otherwise hold a 4K bitmap). The window's pixel ratio is the
        // real (fractional) scale; screen.devicePixelRatio is rounded up (2 at 1.5), a 1.8x larger decode.
        // Keep Lock.qml's and LockOverlay.qml's sourceSize the same: the pixmap cache shares the decode.
        sourceSize.width: root.screen ? root.screen.width * root.devicePixelRatio : 0
        sourceSize.height: root.screen ? root.screen.height * root.devicePixelRatio : 0
    }
}
