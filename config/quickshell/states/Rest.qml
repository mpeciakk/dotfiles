import QtQuick
import QtQuick.Layouts
import ".."
import "../components" as Components
import "../services"

// The island at rest (reference 3.1): this output's workspace dots, the clock, an
// equaliser while a player is playing, and the unread badge. A click on the badge
// opens the notification centre, a click anywhere else the control panel (R19).
Item {
    id: root

    // Set by IslandContent for every state layer.
    property bool active: false
    property string output: ""

    readonly property var spec: Theme.layout.rest
    readonly property bool playing: Players.active?.isPlaying ?? false
    readonly property var dots: Niri.workspaces.filter(w => w.output === root.output).sort((a, b) => a.idx - b.idx)

    // Lets the island report that this layer is loaded and lit on its output (IPC `restLoaded`);
    // true from the start of the enter transition, false again once the island leaves rest.
    readonly property bool ready: root.active && root.output !== ""
    onReadyChanged: IslandState.reportRest(root.output, root.ready)

    MouseArea {
        anchors.fill: parent
        enabled: root.active
        onClicked: IslandState.request("control")
    }

    // Hovering the island while a player plays opens the media state (R31). A HoverHandler is passive, so
    // it takes no clicks from the MouseAreas; it acts on the pointer entering only, and only on the output
    // that has focus (IslandState.request opens the state there).
    HoverHandler {
        enabled: root.active && root.playing && root.output === Niri.focusedOutput

        onHoveredChanged: {
            if (hovered)
                IslandState.request("media");
        }
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: root.spec.gap

        Row {
            spacing: root.spec.dotsGap

            Repeater {
                model: root.dots

                Rectangle {
                    id: dot

                    required property var modelData

                    readonly property bool current: Niri.activeByOutput[root.output] === dot.modelData.id

                    width: dot.current ? root.spec.dotActiveW : root.spec.dot
                    height: root.spec.dot
                    radius: root.spec.dotRadius
                    color: dot.current ? Theme.accent : Theme.dotInactive

                    Behavior on width {
                        NumberAnimation {
                            duration: Theme.motion.bgColorMs
                            easing.type: Easing.InOutQuad
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.motion.bgColorMs
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
        }

        Text {
            text: Time.timeStr
            color: Theme.fg
            font.family: Theme.fonts.mono
            font.pixelSize: Theme.sizes.clockRest
            font.weight: Font.Medium
        }

        Row {
            id: eq

            visible: root.playing
            spacing: root.spec.eqGap

            Repeater {
                model: root.spec.eqDelayMs

                Item {
                    id: bar

                    required property int modelData

                    // Fraction of the full bar height; the bars run one cycle at shifted phases.
                    property real level: root.spec.eqScaleMin

                    width: root.spec.eqBarW
                    height: root.spec.eqH

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: parent.height * bar.level
                        color: Theme.accent
                    }

                    SequentialAnimation {
                        running: eq.visible && root.active

                        // A negative delay starts the cycle part-way in; the same steady state is a later start.
                        PauseAnimation { duration: (Theme.motion.eqMs + bar.modelData) % Theme.motion.eqMs }
                        SequentialAnimation {
                            loops: Animation.Infinite

                            NumberAnimation {
                                target: bar
                                property: "level"
                                to: 1
                                duration: Theme.motion.eqMs / 2
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: bar
                                property: "level"
                                to: root.spec.eqScaleMin
                                duration: Theme.motion.eqMs / 2
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            visible: Notifs.unread > 0
            implicitWidth: badgeRow.implicitWidth + 2 * root.spec.badgePad
            implicitHeight: root.spec.badgeH
            radius: root.spec.badgeRadius
            color: Theme.accentSoft

            Row {
                id: badgeRow

                anchors.centerIn: parent
                spacing: root.spec.badgeGap

                Components.Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: Notifs.dnd ? "moon" : "bell"
                    size: root.spec.badgeIcon
                    color: Theme.accent
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Notifs.unread
                    color: Theme.accent
                    font.family: Theme.fonts.mono
                    font.pixelSize: root.spec.badgeFont
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.active
                onClicked: IslandState.request("center")
            }
        }
    }
}
