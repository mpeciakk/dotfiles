import QtQuick
import Quickshell
import Quickshell.Wayland

// Desktop wallpaper, one per screen (Variants in shell.qml). A click-through
// background layer-shell window showing Theme.wallpaper (it follows the mode when
// the config gives a dark/light pair). Replaces swaybg — stop the external
// wallpaper daemon so they don't stack.
PanelWindow {
    id: root

    property var modelData
    screen: modelData

    readonly property string url: Theme.wallpaper ? "file://" + Theme.wallpaper : ""

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

    // A new wallpaper fades in over the old one once decoded; the old one is released after the fade (a 4K bitmap
    // is ~33 MiB, DESIGN W17). The old url is still held by `front` when `back` takes it: a pixmap-cache hit. A change
    // while the previous one is still decoding or fading (or failed) leaves `back` on what it shows.
    Component.onCompleted: front.source = root.url
    onUrlChanged: {
        if (front.status === Image.Ready && !fade.running)
            back.source = front.source;
        fade.stop();
        front.opacity = 0;
        front.source = root.url;
    }

    Image {
        id: back

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        sourceSize.width: root.screen ? root.screen.width * root.devicePixelRatio : 0
        sourceSize.height: root.screen ? root.screen.height * root.devicePixelRatio : 0
    }

    Image {
        id: front

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        // Decode at the monitor's physical resolution, not the file's native size
        // (a 4K wallpaper on a 1080p output would otherwise hold a 4K bitmap). The window's pixel ratio is the
        // real (fractional) scale; screen.devicePixelRatio is rounded up (2 at 1.5), a 1.8x larger decode.
        // Keep Lock.qml's and LockOverlay.qml's sourceSize the same: the pixmap cache shares the decode.
        sourceSize.width: root.screen ? root.screen.width * root.devicePixelRatio : 0
        sourceSize.height: root.screen ? root.screen.height * root.devicePixelRatio : 0

        onStatusChanged: {
            if (front.status === Image.Ready && front.opacity < 1)
                fade.restart();
            else if (front.status === Image.Null)
                back.source = "";
        }

        NumberAnimation on opacity {
            id: fade

            running: false
            to: 1
            duration: Theme.reducedMotion ? 0 : Theme.motion.themeFadeMs
            easing.type: Easing.InOutQuad
            onFinished: back.source = ""
        }
    }
}
