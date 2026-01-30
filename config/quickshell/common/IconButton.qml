import QtQuick
import QtQuick.Layouts
import ".."
import "."

Item {
    id: root
    required property string icon
    signal clicked

    width: 24
    height: 24
    Layout.alignment: Qt.AlignVCenter

    Text {
        id: prevIcon
        anchors.centerIn: parent
        text: root.icon
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 24
        color: Config.text
        opacity: 0.9
        transformOrigin: Item.Center
        Behavior on scale {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
    }

    TapArea {
        anchors.fill: parent
        targetItem: prevIcon
        onClicked: mouse => root.clicked()
    }
}
