import QtQuick

// Clickable rounded surface with built-in hover/press/ripple feedback. Place
// content as children; handle `clicked` (the MouseEvent is forwarded). The
// StateLayer sits on top (translucent) so the ripple overlays content.
Rectangle {
    id: root

    property alias acceptedButtons: state.acceptedButtons
    property alias effectColor: state.effectColor
    property bool disabled: false

    signal clicked(var event)

    color: "transparent"

    StateLayer {
        id: state

        z: 1
        disabled: root.disabled
        onClicked: event => root.clicked(event)
    }
}
