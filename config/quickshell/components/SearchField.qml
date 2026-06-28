import QtQuick
import "../services"

// Rounded search input. Exposes `text`/`placeholder` and forwards the keys a
// list cares about as signals. The building block for SearchList (launcher,
// menus, config screens). Width is set by the parent (anchor it).
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: ""
    property alias font: input.font

    signal accepted
    signal escaped
    signal up
    signal down

    function forceActiveFocus(): void {
        input.forceActiveFocus();
    }

    implicitHeight: 44
    radius: Config.rounding.large
    color: Colours.surface0

    TextInput {
        id: input

        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        color: Colours.text
        font.pixelSize: 15
        selectByMouse: true
        selectionColor: Colours.mauve

        Keys.onUpPressed: root.up()
        Keys.onDownPressed: root.down()
        Keys.onReturnPressed: root.accepted()
        Keys.onEnterPressed: root.accepted()
        Keys.onEscapePressed: root.escaped()

        Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            visible: input.text === ""
            text: root.placeholder
            color: Colours.overlay0
            font: input.font
        }
    }
}
