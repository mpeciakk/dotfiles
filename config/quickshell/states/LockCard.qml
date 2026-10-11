import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import ".."
import "../components" as Components
import "../services"
import "../lib/lock.js" as L

// The lock card (reference 3.10, R3): clock, date, the password field (avatar letter, input, →), a status line
// and a bottom row with battery, Wi-Fi and only the COUNT of notifications. It knows nothing of PAM or of the
// session lock: a submit hands the typed text out through submitted() and clears the field; whoever owns the
// card authenticates and sets `busy` / `failed` and calls shake(). Usable outside a lock surface (the preview).
// The typed text is never logged, exposed as a property or copyable (password echo).
Item {
    id: root

    // The last attempt was refused: danger ring and status, until the user types again.
    property bool failed: false
    // The status line of a refused attempt: PAM's own messages, or the fixed text (lib/lock.js refusalText()).
    property string failedText: L.refusalText([])
    // An attempt is being checked: the field takes no edits and nothing is submitted.
    property bool busy: false
    // The card's corners: the lock screen morphs them from the rest island's to geom.lock.r.
    property real topRadius: Theme.geom.lock.r
    property real bottomRadius: Theme.geom.lock.r
    // Docked at the top edge (lib/lock.js dock()): the island's ears, outside the card's own width, and no ring
    // along the top. Never together with a topRadius.
    property real earSize: 0
    // The shadow, 0..1: it fades as the card docks into the island (whose fill no shadow shows through).
    property real shadowAmount: 1
    // The content: true = in (enter after the lock's delay), false = out (exit, no delay).
    property bool revealed: true
    // false: the content is in from the first frame (the unlock overlay, whose first frame is the one shown).
    property bool enterAnimated: true

    signal submitted(string password)

    readonly property var spec: Theme.layout.lock
    readonly property var steps: root.spec.shakeSteps
    // Typing hides the error (reference 4.5: typing clears err) and emptying the field does not bring it back;
    // the next submit resets `failed`.
    property bool typedSinceFailure: false
    readonly property bool showError: L.errorShown(root.failed, root.typedSinceFailure)
    onFailedChanged: if (root.failed) root.typedSinceFailure = false

    implicitWidth: Theme.geom.lock.w
    implicitHeight: Theme.geom.lock.h

    // The shake (reference 3.10): five eased steps of shakeMs / 5.
    function shake(): void {
        shakeAnim.restart();
    }

    function focusField(): void {
        field.forceActiveFocus();
    }

    function submit(): void {
        if (root.busy || field.text.length === 0)
            return;
        const typed = field.text;
        field.text = "";
        root.submitted(typed);
    }

    // One bottom-row item: an icon and its text.
    component Info: Row {
        property alias icon: infoIcon.name
        property alias label: infoText.text

        spacing: Theme.layout.lock.bottomItemGap

        Components.Icon {
            id: infoIcon

            anchors.verticalCenter: parent.verticalCenter
            color: Theme.fgLock
            size: Theme.layout.lock.bottomIcon
        }

        Text {
            id: infoText

            anchors.verticalCenter: parent.verticalCenter
            color: Theme.fgLock
            textFormat: Text.PlainText
            font.family: Theme.fonts.ui
            font.pixelSize: Theme.layout.lock.bottomFont
        }
    }

    RectangularShadow {
        anchors.fill: bg
        opacity: root.shadowAmount
        radius: root.bottomRadius
        blur: Theme.lockShadowBlur
        offset.y: Theme.lockShadowY
        color: Theme.lockShadowColor
    }

    // The body, for the shadow.
    Item {
        id: bg

        anchors.fill: parent
    }

    // Island material of the current level and theme (R3): fill and ring on one outline, the island's (IslandShape)
    // when docked: ears, and the ring open at the top edge. Floating, the rounded top corners and a top ring
    // (fading out as topRadius goes to 0, i.e. as the card docks).
    Shape {
        id: outline

        readonly property real e: root.earSize
        readonly property real tr: root.topRadius
        readonly property real br: root.bottomRadius
        readonly property real w: root.width
        readonly property real h: root.height

        x: -outline.e
        width: root.width + 2 * outline.e
        height: root.height
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: Theme.islandBg
            strokeColor: Theme.ring
            strokeWidth: Theme.sizes.ringWidth

            startX: outline.tr
            startY: 0
            PathArc { x: 0; y: outline.tr; radiusX: outline.tr; radiusY: outline.tr; direction: PathArc.Counterclockwise }
            PathArc { x: outline.e; y: outline.e + outline.tr; radiusX: outline.e; radiusY: outline.e; direction: PathArc.Clockwise }
            PathLine { x: outline.e; y: outline.h - outline.br }
            PathArc { x: outline.e + outline.br; y: outline.h; radiusX: outline.br; radiusY: outline.br; direction: PathArc.Counterclockwise }
            PathLine { x: outline.e + outline.w - outline.br; y: outline.h }
            PathArc { x: outline.e + outline.w; y: outline.h - outline.br; radiusX: outline.br; radiusY: outline.br; direction: PathArc.Counterclockwise }
            PathLine { x: outline.e + outline.w; y: outline.e + outline.tr }
            PathArc { x: 2 * outline.e + outline.w; y: outline.tr; radiusX: outline.e; radiusY: outline.e; direction: PathArc.Clockwise }
            PathArc { x: 2 * outline.e + outline.w - outline.tr; y: 0; radiusX: outline.tr; radiusY: outline.tr; direction: PathArc.Counterclockwise }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.alpha(Theme.ring, Theme.ring.a * Math.min(1, outline.tr / Theme.geom.lock.r))
            strokeWidth: Theme.sizes.ringWidth

            startX: outline.w - outline.tr
            startY: 0
            PathLine { x: outline.tr; y: 0 }
        }
    }

    // The content keeps the card's locked size; while the card morphs it is clipped to it.
    Item {
        anchors.fill: parent
        clip: true

        Item {
            id: content

            property real blur: root.spec.contentBlur

            anchors.centerIn: parent
            width: Theme.geom.lock.w
            height: Theme.geom.lock.h
            opacity: 0
            scale: root.spec.contentScaleFrom

            // The reveal and the hide are two Transitions, not Behaviors keyed on `revealed`: a Behavior could start
            // before its `revealed`-bound durations re-evaluated and run a quick reversal with the other timings.
            states: State {
                name: "revealed"
                when: root.revealed
                PropertyChanges { content.opacity: 1; content.scale: 1; content.blur: 0 }
            }

            transitions: [
                Transition {
                    to: "revealed"
                    enabled: root.enterAnimated
                    SequentialAnimation {
                        PauseAnimation { duration: root.spec.enterDelayMs }
                        NumberAnimation { property: "opacity"; duration: root.spec.enterOpacityMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.enterCurve }
                    }
                    SequentialAnimation {
                        PauseAnimation { duration: root.spec.enterDelayMs - root.spec.enterScaleLeadMs }
                        NumberAnimation { property: "scale"; duration: root.spec.enterScaleMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.enterCurve }
                    }
                    SequentialAnimation {
                        PauseAnimation { duration: root.spec.enterDelayMs }
                        NumberAnimation { property: "blur"; duration: root.spec.enterBlurMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.easeCurve }
                    }
                },
                Transition {
                    from: "revealed"
                    NumberAnimation { property: "opacity"; duration: root.spec.exitOpacityMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.easeCurve }
                    NumberAnimation { property: "scale"; duration: root.spec.exitScaleMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.easeCurve }
                    NumberAnimation { property: "blur"; duration: root.spec.exitBlurMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.easeCurve }
                }
            ]

            layer.enabled: content.blur > 0
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: content.blur / root.spec.contentBlur
                blurMax: root.spec.contentBlur
            }

            Column {
                anchors.top: parent.top
                anchors.topMargin: root.spec.padTop
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Time.timeStr
                    color: Theme.fg
                    font.family: Theme.fonts.ui
                    font.pixelSize: root.spec.clockFont
                    font.weight: Font.Medium
                    font.letterSpacing: root.spec.clockLetterEm * root.spec.clockFont
                    font.features: ({ "tnum": 1 })
                    lineHeightMode: Text.FixedHeight
                    lineHeight: root.spec.clockFont
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    topPadding: root.spec.dateGap
                    text: Time.weekdayStr + ", " + Time.dayMonthStr
                    color: Theme.fgLock
                    font.family: Theme.fonts.ui
                    font.pixelSize: root.spec.dateFont
                }

                // The shake target (reference 3.10: the password wrapper).
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: root.spec.fieldW
                    height: root.spec.fieldGap + root.spec.fieldH

                    Item {
                        id: wrapper

                        y: root.spec.fieldGap
                        width: parent.width
                        height: root.spec.fieldH

                        // Focus (focus-within): an outline focusGap outside the field.
                        Rectangle {
                            anchors.fill: fieldBox
                            anchors.margins: -(root.spec.focusGap + root.spec.focusWidth)
                            radius: Theme.radii.lockField + root.spec.focusGap + root.spec.focusWidth
                            color: "transparent"
                            border.color: Qt.alpha(Theme.accent, root.spec.focusAlpha)
                            border.width: root.spec.focusWidth
                            visible: field.activeFocus
                        }

                        Rectangle {
                            id: fieldBox

                            anchors.fill: parent
                            radius: Theme.radii.lockField
                            color: Theme.lockField
                            border.color: root.showError ? Theme.danger : Theme.lockFieldRing
                            border.width: root.showError ? root.spec.errorRing : root.spec.fieldRing

                            Behavior on border.color {
                                ColorAnimation { duration: Theme.motion.buttonBgMs }
                            }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: root.spec.fieldPadX
                                anchors.rightMargin: root.spec.fieldPadX
                                spacing: root.spec.fieldInnerGap

                                Rectangle {
                                    id: avatar

                                    anchors.verticalCenter: parent.verticalCenter
                                    width: root.spec.avatar
                                    height: root.spec.avatar
                                    radius: root.spec.avatar / 2
                                    color: Theme.accent

                                    Text {
                                        anchors.centerIn: parent
                                        text: L.initial(Theme.host.lock?.name ?? "", Quickshell.env("USER"))
                                        color: Theme.accentFg
                                        font.family: Theme.fonts.ui
                                        font.pixelSize: root.spec.avatarFont
                                        font.weight: Font.DemiBold
                                    }
                                }

                                TextInput {
                                    id: field

                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - avatar.width - submitButton.width - 2 * parent.spacing
                                    height: root.spec.inputH
                                    verticalAlignment: TextInput.AlignVCenter
                                    echoMode: TextInput.Password
                                    inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhHiddenText
                                    readOnly: root.busy
                                    clip: true
                                    focus: true
                                    color: Theme.fg
                                    font.family: Theme.fonts.ui
                                    font.pixelSize: root.spec.inputFont
                                    font.letterSpacing: root.spec.inputLetterEm * root.spec.inputFont
                                    onAccepted: root.submit()
                                    onTextChanged: if (field.text.length > 0) root.typedSinceFailure = true

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        visible: field.text.length === 0
                                        text: "Hasło"
                                        color: Theme.fgMuted
                                        font.family: Theme.fonts.ui
                                        font.pixelSize: root.spec.inputFont
                                    }
                                }

                                Rectangle {
                                    id: submitButton

                                    anchors.verticalCenter: parent.verticalCenter
                                    width: root.spec.submit
                                    height: root.spec.submit
                                    radius: root.spec.submit / 2
                                    color: Theme.inverseBg
                                    Accessible.name: "Odblokuj"

                                    Components.Icon {
                                        anchors.centerIn: parent
                                        name: "arrow-right"
                                        color: Theme.inverseFg
                                        size: root.spec.submitIcon
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: root.submit()
                                    }
                                }
                            }
                        }
                    }

                    SequentialAnimation {
                        id: shakeAnim

                        readonly property int stepMs: Theme.motion.shakeMs / root.steps.length

                        NumberAnimation { target: wrapper; property: "x"; to: root.steps[0]; duration: shakeAnim.stepMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.shakeCurve }
                        NumberAnimation { target: wrapper; property: "x"; to: root.steps[1]; duration: shakeAnim.stepMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.shakeCurve }
                        NumberAnimation { target: wrapper; property: "x"; to: root.steps[2]; duration: shakeAnim.stepMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.shakeCurve }
                        NumberAnimation { target: wrapper; property: "x"; to: root.steps[root.steps.length - 2]; duration: shakeAnim.stepMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.shakeCurve }
                        NumberAnimation { target: wrapper; property: "x"; to: root.steps[root.steps.length - 1]; duration: shakeAnim.stepMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.shakeCurve }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: root.spec.fieldW
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    topPadding: root.spec.statusGap
                    height: root.spec.statusGap + root.spec.statusH
                    text: root.showError ? root.failedText : root.busy ? "Sprawdzanie…" : ""
                    color: root.showError ? Theme.danger : Theme.fgMuted
                    font.family: Theme.fonts.ui
                    font.pixelSize: root.spec.statusFont
                }
            }

            // Battery, Wi-Fi and the notification COUNT only (DESIGN §6: no content on the lock screen).
            Row {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: root.spec.padBottom
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: root.spec.bottomGap

                Info {
                    visible: Battery.available
                    icon: Battery.charging ? "battery-charging" : "battery"
                    label: Math.round(Battery.percentage * root.spec.percent) + "%"
                }

                Info {
                    visible: Network.connected
                    icon: "wifi"
                    label: Network.name
                }

                Info {
                    icon: "bell"
                    label: L.notifCount(Notifs.unread)
                }
            }
        }
    }
}
