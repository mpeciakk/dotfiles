import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import ".."
import "../components" as Components
import "../lib/power.js" as P

// The power menu (reference 3.8, R18, R22): five round buttons. Zablokuj and Uśpij act at once; Wyloguj,
// Restart and Wyłącz must be held for Theme.motion.holdMs while a ring fills, and letting go early rewinds
// it. Keyboard: left/right move the focus, Enter acts like the pointer, the letters L S O R P act like a
// press on that button (the risky three still need the hold).
// perform() is the ONLY place that runs a command or asks for the session lock. In test mode
// (WYSPA_TEST=1) it only logs what it would do; tests/power.test.mjs keeps it that way.
Item {
    id: root

    // Set by IslandContent for every state layer.
    property bool active: false
    property string output: ""

    readonly property var spec: Theme.layout.power
    readonly property bool testMode: Quickshell.env("WYSPA_TEST") === "1"

    // The button being held ("" = none), the button the keyboard is on, and whether its focus ring shows.
    property string holding: ""
    property int focused: 0
    property bool keyboard: false

    // The one gate: what to do for `kind` is decided by P.plan(); test mode never executes and never locks.
    function perform(kind: string): void {
        const p = P.plan(kind, Theme.tokens.power.commands, root.testMode);
        console.info(p.message);
        if (!p.execute)
            return;
        if (p.lock)
            IslandState.lockRequested();
        else
            Quickshell.execDetached(p.argv);
    }

    // The button is confirmed: powerDone shows its label and the action runs at once.
    function finish(kind: string): void {
        holdTimer.stop();
        root.holding = "";
        if (!root.active || !IslandState.request("powerDone"))
            return;
        IslandState.powerLabel = P.label(kind);
        root.perform(kind);
    }

    // Press: a risky button starts its hold, the others act now.
    function press(kind: string): void {
        if (!root.active)
            return;
        if (P.isHold(kind)) {
            root.holding = kind;
            holdTimer.restart();
        } else {
            root.finish(kind);
        }
    }

    // Release (and the pointer leaving, and a cancelled grab): the ring rewinds, nothing runs.
    function release(kind: string): void {
        if (root.holding !== kind)
            return;
        holdTimer.stop();
        root.holding = "";
    }

    function indexOfKind(kind: string): int {
        return P.ITEMS.findIndex(it => it.id === kind);
    }

    onActiveChanged: {
        holdTimer.stop();
        root.holding = "";
        root.focused = 0;
        root.keyboard = false;
        if (root.active)
            root.forceActiveFocus();
    }

    Timer {
        id: holdTimer

        interval: Theme.motion.holdMs
        // Only a hold that is still on when it ends confirms.
        onTriggered: {
            if (root.holding !== "")
                root.finish(root.holding);
        }
    }

    Keys.onPressed: event => {
        if (!root.active)
            return;
        const kind = P.kindForKey(event.text);
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
            root.keyboard = true;
            root.focused = P.step(root.focused, event.key === Qt.Key_Left ? -1 : 1, P.ITEMS.length);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (!event.isAutoRepeat) {
                root.keyboard = true;
                root.press(P.ITEMS[root.focused].id);
            }
            event.accepted = true;
        } else if (kind !== "") {
            if (!event.isAutoRepeat) {
                root.keyboard = true;
                root.focused = root.indexOfKind(kind);
                root.press(kind);
            }
            event.accepted = true;
        }
    }

    Keys.onReleased: event => {
        if (event.isAutoRepeat)
            return;
        const kind = P.kindForKey(event.text);
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            root.release(P.ITEMS[root.focused].id);
        else if (kind !== "")
            root.release(kind);
    }

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
                        onPressed: {
                            root.keyboard = false;
                            if (btn.modelData.hold)
                                root.press(btn.modelData.id);
                        }
                        onClicked: {
                            if (!btn.modelData.hold)
                                root.press(btn.modelData.id);
                        }
                        onReleased: root.release(btn.modelData.id)
                        onCanceled: root.release(btn.modelData.id)
                        onExited: root.release(btn.modelData.id)
                    }
                }
            }
        }
    }
}
