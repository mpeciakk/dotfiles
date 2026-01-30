pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import "../services"
import ".."

Item {
    id: root
    width: layout.width
    height: layout.height

    property int sizeSmall: 12
    property int sizeLarge: 28

    Rectangle {
        id: layout
        color: "transparent"

        implicitWidth: row.implicitWidth
        implicitHeight: row.implicitHeight + 16

        Row {
            id: row
            spacing: 5
            anchors.centerIn: parent

            Repeater {
                model: Niri.workspaces

                Rectangle {
                    id: wsBox

                    required property var model
                    required property int index

                    property int wid: index + 1
                    property bool hasActiveWindows: model.activeWindowId !== null
                    property bool isFocused: index === Niri.focusedWorkspaceIndex

                    property int prefHeight: 12
                    property int prefWidth: model.isFocused ? root.sizeLarge : root.sizeSmall

                    width: prefWidth
                    height: prefHeight
                    radius: prefHeight / 2

                    Behavior on width {
                        NumberAnimation {
                            duration: 400
                            easing.type: Easing.OutCubic
                        }
                    }

                    property color workspaceStateColor: {
                        if (isFocused) {
                            return Config.accent;
                        }

                        if (hasActiveWindows) {
                            return Config.accent_variant;
                        }

                        return Config.surface_solid;
                    }

                    color: workspaceStateColor

                    border.width: 0

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    property bool hovered: false

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Config.text
                        opacity: wsBox.hovered ? 0.18 : 0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                            }
                        }
                    }

                    SequentialAnimation {
                        id: bounceAnim
                        running: false
                        loops: 1

                        NumberAnimation {
                            target: wsBox
                            property: "scale"
                            to: 1.20
                            duration: 120
                            easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            target: wsBox
                            property: "scale"
                            to: 0.92
                            duration: 120
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            target: wsBox
                            property: "scale"
                            to: 1.0
                            duration: 130
                            easing.type: Easing.OutBounce
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: wsBox.hovered = true
                        onExited: wsBox.hovered = false
                        // onClicked: Niri.focusWorkspaceById(model.id)
                    }
                }
            }
        }
    }
}
