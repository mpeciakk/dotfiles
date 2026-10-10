import QtQuick
import QtQuick.Layouts
import ".."

// What the power menu leaves behind (reference 3.9): an accent dot with its halo and the label of the
// confirmed button ("Wyłączanie…"). IslandState returns the island to rest after Theme.motion.powerDoneMs
// (R22). The "prototyp" demo marker of the reference is dropped.
Item {
    id: root

    // Set by IslandContent for every state layer.
    property bool active: false
    property string output: ""

    readonly property var spec: Theme.layout.powerDone

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.spec.padX
        anchors.rightMargin: root.spec.padX
        spacing: root.spec.gap

        Item {
            Layout.preferredWidth: root.spec.dot
            Layout.preferredHeight: root.spec.dot

            // The halo is a ring outside the dot that takes no room, like a box-shadow.
            Rectangle {
                anchors.centerIn: parent
                width: root.spec.dot + 2 * root.spec.haloWidth
                height: width
                radius: width / 2
                color: Theme.accentHalo
            }

            Rectangle {
                anchors.fill: parent
                radius: root.spec.dotRadius
                color: Theme.accent
            }
        }

        Text {
            Layout.fillWidth: true
            text: IslandState.powerLabel
            color: Theme.fg
            elide: Text.ElideRight
            font.family: Theme.fonts.ui
            font.pixelSize: root.spec.labelFont
            font.weight: Font.Medium
        }
    }
}
