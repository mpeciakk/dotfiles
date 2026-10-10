import QtQuick
import QtQuick.Layouts
import ".."
import "../components" as Components
import "../lib/island.js" as L

// Volume / brightness OSD (reference 3.2): icon, a track whose accent fill follows the value,
// and the value in percent. What it shows is set by IslandState (osdKind/osdValue/osdMuted).
// Muted volume (unspecified in the reference): volume-x, an empty track and "—".
Item {
    id: root

    // Set by IslandContent for every state layer.
    property bool active: false
    property string output: ""

    readonly property var spec: Theme.layout.osd
    readonly property bool muted: IslandState.osdMuted
    readonly property real fraction: root.muted ? 0 : Math.max(0, Math.min(1, IslandState.osdValue))

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.spec.padX
        anchors.rightMargin: root.spec.padX
        spacing: root.spec.gap

        Components.Icon {
            name: L.osdIcon(IslandState.osdKind, IslandState.osdValue, root.muted, root.spec.volumeHighFrom)
            size: root.spec.icon
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.spec.barH
            radius: root.spec.barRadius
            color: Theme.track
            clip: true

            Rectangle {
                width: parent.width * root.fraction
                height: parent.height
                radius: root.spec.barRadius
                color: Theme.accent

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.motion.osdBarMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.motion.enterCurve
                    }
                }
            }
        }

        Text {
            Layout.preferredWidth: root.spec.valueW
            horizontalAlignment: Text.AlignRight
            text: root.muted ? "—" : Math.round(IslandState.osdValue * root.spec.percent)
            color: Theme.fg
            font.family: Theme.fonts.mono
            font.pixelSize: root.spec.valueFont
        }
    }
}
