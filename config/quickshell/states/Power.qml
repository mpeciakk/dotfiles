import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import ".."
import "../components" as Components
import "../lib/power.js" as P

// The power menu (reference 3.8, R18, R22): five round buttons. Zablokuj and Uśpij act at once; Wyloguj,
// Restart and Wyłącz must be held for Theme.motion.holdMs while a ring fills, and letting go early rewinds
// it. Keyboard: left/right move the focus, Enter acts like the pointer, the letters L S O R P act like a
// press on that button (the risky three still need the hold).
// Every key, pointer, focus, layer and timer event goes to P.reduce() (lib/power.js), which decides what
// happens; this file applies the answer. Nothing here runs a command: a confirmed button goes through
// PowerActions.perform(), the one gate (components/PowerActions.qml), which in test mode (WYSPA_TEST=1) only
// logs what it would do. tests/power.test.mjs keeps both true.
Item {
    id: root

    // Set by IslandContent for every state layer.
    property bool active: false
    property string output: ""

    readonly property var spec: Theme.layout.power

    // The state of lib/power.js: the button being held ("" = none), the button the keyboard is on, and
    // whether its focus ring shows.
    property var menu: P.initial()
    readonly property string holding: root.menu.holding
    readonly property int focused: root.menu.focused
    readonly property bool keyboard: root.menu.keyboard

    Components.PowerActions {
        id: actions
    }

    // Hands one event to the reducer and applies its effect; true when a key was used.
    function dispatch(ev: var): bool {
        const pressing = ev.type === "keyDown" || ev.type === "pointerPress" || ev.type === "pointerClick";
        if (pressing && !root.active)
            return false;
        const r = P.reduce(root.menu, ev);
        root.menu = r.state;
        if (r.effect.type === "start")
            holdTimer.restart();
        else if (r.effect.type === "cancel")
            holdTimer.stop();
        else if (r.effect.type === "finish")
            root.finish(r.effect.kind);
        return r.handled;
    }

    // The button is confirmed: powerDone shows its label and the action runs at once.
    function finish(kind: string): void {
        holdTimer.stop();
        if (!root.active || !IslandState.request("powerDone"))
            return;
        IslandState.powerLabel = P.label(kind);
        actions.perform(kind);
    }

    onActiveChanged: {
        root.dispatch({ type: "active", on: root.active });
        if (root.active)
            root.forceActiveFocus();
    }

    // A release that goes to another item (the focus moved away) would never reach Keys.onReleased.
    onActiveFocusChanged: {
        if (!root.activeFocus)
            root.dispatch({ type: "focusLost" });
    }

    Timer {
        id: holdTimer

        interval: Theme.motion.holdMs
        onTriggered: root.dispatch({ type: "timerElapsed" })
    }

    Keys.onPressed: event => {
        const chord = (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) !== 0;
        event.accepted = root.dispatch({ type: "keyDown", code: event.key, repeat: event.isAutoRepeat, chord: chord });
    }

    Keys.onReleased: event => root.dispatch({ type: "keyUp", code: event.key, repeat: event.isAutoRepeat })

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: root.spec.padTop
        anchors.leftMargin: root.spec.padX
        anchors.rightMargin: root.spec.padX
        anchors.bottomMargin: root.spec.padBottom
        spacing: root.spec.gap

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: root.spec.headPadX
            Layout.rightMargin: root.spec.headPadX

            Text {
                text: "Zasilanie"
                color: Theme.fg
                font.family: Theme.fonts.ui
                font.pixelSize: root.spec.titleFont
                font.weight: Font.DemiBold
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: root.holding !== "" ? "trzymaj…" : "Esc zamyka · strzałki + Enter"
                color: Theme.fgMuted
                font.family: Theme.fonts.ui
                font.pixelSize: root.spec.hintFont
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: root.spec.gridGap
            uniformCellSizes: true

            Repeater {
                model: P.ITEMS

                Item {
                    id: btn

                    required property var modelData
                    required property int index

                    readonly property bool held: root.holding === btn.modelData.id
                    readonly property color tint: btn.modelData.danger ? Theme.danger : Theme.fg
                    // 0 = ring empty, 1 = full; fills linearly over holdMs, rewinds over holdCancelMs.
                    property real progress: btn.held ? 1 : 0

                    Layout.fillWidth: true
                    Layout.preferredHeight: col.implicitHeight

                    Behavior on progress {
                        NumberAnimation {
                            duration: btn.held ? Theme.motion.holdMs : Theme.motion.holdCancelMs
                            easing.type: btn.held ? Easing.Linear : Easing.BezierSpline
                            easing.bezierCurve: Theme.motion.easeCurve
                        }
                    }

                    // Keyboard focus (focus-visible): drawn round the whole button.
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -root.spec.focusGap
                        radius: root.spec.focusRadius
                        color: "transparent"
                        border.color: Theme.focusRing
                        border.width: root.spec.focusWidth
                        visible: root.keyboard && root.focused === btn.index
                    }

                    Column {
                        id: col

                        width: parent.width
                        topPadding: root.spec.buttonPadY
                        bottomPadding: root.spec.buttonPadY
                        spacing: root.spec.buttonGap

                        Rectangle {
                            id: circle

                            anchors.horizontalCenter: parent.horizontalCenter
                            width: root.spec.circle
                            height: root.spec.circle
                            radius: root.spec.circle / 2
                            color: btn.held ? Theme.chip : area.containsMouse ? Theme.hover : Theme.tile

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.motion.buttonBgMs
                                }
                            }

                            Shape {
                                anchors.fill: parent
                                visible: btn.progress > 0
                                preferredRendererType: Shape.CurveRenderer

                                ShapePath {
                                    strokeColor: btn.modelData.danger ? Theme.danger : Theme.accent
                                    strokeWidth: root.spec.ringWidth
                                    fillColor: "transparent"
                                    capStyle: ShapePath.RoundCap

                                    PathAngleArc {
                                        centerX: root.spec.circle / 2
                                        centerY: root.spec.circle / 2
                                        radiusX: root.spec.ringRadius
                                        radiusY: root.spec.ringRadius
                                        startAngle: root.spec.ringStart
                                        sweepAngle: root.spec.ringSweep * btn.progress
                                    }
                                }
                            }

                            Components.Icon {
                                anchors.centerIn: parent
                                name: btn.modelData.icon
                                color: btn.tint
                                size: root.spec.icon
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: btn.modelData.label
                            color: Theme.fgSoft
                            font.family: Theme.fonts.ui
                            font.pixelSize: root.spec.labelFont
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: btn.modelData.hold ? "przytrzymaj " + btn.modelData.key : btn.modelData.key
                            color: Theme.fgDim
                            font.family: Theme.fonts.mono
                            font.pixelSize: root.spec.keyFont
                        }
                    }

                    MouseArea {
                        id: area

                        anchors.fill: parent
                        hoverEnabled: true
                        onPressed: root.dispatch({ type: "pointerPress", kind: btn.modelData.id })
                        onClicked: root.dispatch({ type: "pointerClick", kind: btn.modelData.id })
                        onReleased: root.dispatch({ type: "pointerRelease", kind: btn.modelData.id })
                        onCanceled: root.dispatch({ type: "pointerRelease", kind: btn.modelData.id })
                        onExited: root.dispatch({ type: "pointerRelease", kind: btn.modelData.id })
                    }
                }
            }
        }
    }
}
