import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: bar
    Layout.fillWidth: true
    height: 12

    required property real progress

    signal release(real progress)

    property bool dragging: false
    property real dragFrac: 0.0

    readonly property int pad: 0
    readonly property real f: displayedFrac()
    readonly property real usableW: Math.max(1, width - pad * 2)

    function displayedFrac() {
        if (dragging) {
            return dragFrac;
        }

        return progress;
    }

    function clamp01(x) {
        return Math.max(0, Math.min(1, x));
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: bar.pad
        width: bar.usableW
        height: 4
        radius: 2
        color: Config.base_solid
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: bar.pad
        width: Math.max(6, bar.usableW * bar.f)
        height: 4
        radius: 2
        color: Config.accent
    }

    Rectangle {
        width: 8
        height: 8
        radius: 4
        color: Config.text
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(bar.pad, Math.min(bar.pad + bar.usableW - width, bar.pad + bar.usableW * bar.f - width / 2))
        opacity: (bar.progress > 0) ? 0.9 : 0.25
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: (bar.progress > 0)

        function updateDrag(mx) {
            bar.dragFrac = bar.clamp01((mx - bar.pad) / bar.usableW);
        }

        onPressed: {
            bar.dragging = true;
            updateDrag(mouse.x);
        }
        onPositionChanged: {
            if (bar.dragging) {
                updateDrag(mouse.x);
            }
        }
        onReleased: {
            updateDrag(mouse.x);
            bar.dragging = false;
            bar.release(bar.dragFrac);
        }
        onCanceled: bar.dragging = false
    }
}
