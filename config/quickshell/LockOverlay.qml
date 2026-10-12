import QtQuick
import QtQuick.Effects
import "components" as Components
import "states" as States
import "services"
import "lib/lock.js" as L
import "lib/power.js" as P

// The lock overlay (DESIGN W12), inside each screen's island window (already there, full-screen, overlay layer: a
// window of its own took ~170 ms to its first frame). It plays the lock both ways where the lock surface cannot: the
// protocol shows no window while the session is locked, and a surface hidden by the lock gets no new frame, so at the
// unlock the compositor shows its last one. IslandState.lockPhase (set by Lock.qml): "in" = the way in over the
// windows (the lock follows when it has played), "locked" = under the lock, "back" = the way back after the unlock.
// `up` is the locked look: the card in the middle (its content in), the extras, the wallpaper blurred over the
// windows. Up from its first frame on (it enters from the island: the card docked at the rest island's place,
// nothing else), down on the way back. Its last frame before the lock covered it is the locked look, which is what
// the compositor shows again at the unlock. No input: the island window's mask never covers it.
Item {
    id: over

    // The screen whose island window this is.
    property var screen: null

    readonly property var wp: Theme.lockWallpaper
    readonly property var spec: Theme.layout.lock
    readonly property var rest: IslandState.geometryFor("rest", over.screen ? over.screen.name : "")
    // As the island's ears (IslandShape animEar at rest); the card trades them for rounded corners off the edge.
    readonly property real ear: Math.min(Theme.geom.ear, over.rest.h - over.rest.r)
    readonly property var dock: L.dock(over.morph, over.spec.dockAt)
    // False for the first frame, so the way in starts from the island.
    property bool entered: false
    readonly property bool up: over.entered && IslandState.lockPhase !== "back"

    // 0 = the rest island and the plain wallpaper, 1 = the card and the blurred wallpaper (both ways alike).
    property real morph: over.up ? 1 : 0
    Behavior on morph {
        NumberAnimation {
            duration: Theme.reducedMotion ? 0 : Theme.motion.lockMorphMs
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.motion.morphCurve
        }
    }
    property real veil: over.up ? 1 : 0
    Behavior on veil {
        NumberAnimation {
            duration: Theme.reducedMotion ? 0 : Theme.motion.wallpaperMs
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.motion.morphCurve
        }
    }
    // The wallpaper's opacity, the card's and the extras', set by the "up" state below: each way has its own
    // timing, so Transitions (a Behavior's durations could lag the flip).
    property real desk: 0
    property real cardFade: 1
    property real extrasFade: 0

    Component.onCompleted: over.entered = true

    states: State {
        name: "up"
        when: over.up
        PropertyChanges { over.desk: 1; over.extrasFade: 1; over.cardFade: 1 }
    }

    transitions: [
        // The way in: the wallpaper covers the windows, the extras come after the card.
        Transition {
            to: "up"
            NumberAnimation { target: over; property: "desk"; duration: Theme.reducedMotion ? 0 : over.spec.deskMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.easeCurve }
            // Already 1 on a fresh way in; back from a cross-fade when a lock comes during the way back.
            NumberAnimation { target: over; property: "cardFade"; duration: Theme.reducedMotion ? 0 : over.spec.earMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.easeCurve }
            SequentialAnimation {
                PauseAnimation { duration: Theme.reducedMotion ? 0 : over.spec.extrasDelayMs }
                NumberAnimation { target: over; property: "extrasFade"; duration: Theme.reducedMotion ? 0 : over.spec.extrasMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.easeCurve }
            }
        },
        // The way back: the extras go with the card's content, the windows come back from deskDelayMs, the card
        // cross-fades with the island from earDelayMs.
        Transition {
            from: "up"
            NumberAnimation { target: over; property: "extrasFade"; duration: Theme.reducedMotion ? 0 : over.spec.exitOpacityMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.easeCurve }
            SequentialAnimation {
                PauseAnimation { duration: Theme.reducedMotion ? 0 : over.spec.deskDelayMs }
                NumberAnimation { target: over; property: "desk"; duration: Theme.reducedMotion ? 0 : over.spec.deskMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.easeCurve }
            }
            SequentialAnimation {
                PauseAnimation { duration: Theme.reducedMotion ? 0 : over.spec.earDelayMs }
                NumberAnimation { target: over; property: "cardFade"; to: 0; duration: Theme.reducedMotion ? 0 : over.spec.earMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.easeCurve }
            }
        }
    ]

    Item {
        anchors.fill: parent
        clip: true
        opacity: over.desk

        Image {
            anchors.fill: parent
            source: Theme.wallpaper ? "file://" + Theme.wallpaper : ""
            fillMode: Image.PreserveAspectCrop
            // Synchronous, so the first frame has it. Cheap: the same url and sourceSize as Wallpaper.qml's,
            // so it comes from the pixmap cache.
            asynchronous: false
            sourceSize.width: over.screen ? over.screen.width * over.screen.devicePixelRatio : 0
            sourceSize.height: over.screen ? over.screen.height * over.screen.devicePixelRatio : 0
            scale: 1 + (over.wp.scale - 1) * over.veil
            layer.enabled: true
            layer.effect: MultiEffect {
                autoPaddingEnabled: false
                blurEnabled: true
                blur: over.veil
                blurMax: over.wp.blur
                saturation: (over.wp.saturate - 1) * over.veil
                brightness: (over.wp.brightness - 1) * over.veil
            }
        }
    }

    States.LockCard {
        id: overCard

        width: over.rest.w + (Theme.geom.lock.w - over.rest.w) * over.morph
        height: over.rest.h + (Theme.geom.lock.h - over.rest.h) * over.morph
        x: (over.width - overCard.width) / 2
        y: (over.height - Theme.geom.lock.h) / 2 * over.dock.top
        topRadius: Theme.geom.lock.r * over.dock.top
        earSize: over.ear * over.dock.ear
        bottomRadius: over.rest.r + (Theme.geom.lock.r - over.rest.r) * over.morph
        shadowAmount: over.morph
        opacity: over.cardFade
        revealed: over.up
        // Not busy: the status line stays empty, as on the lock surface at rest.
        busy: false
    }

    // The extras as the lock surface shows them (no input here).
    Item {
        anchors.fill: parent
        opacity: over.extrasFade

        Components.MiniPlayer {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: over.spec.edge
            width: over.spec.playerW
            height: over.spec.playerH
            radius: over.spec.playerRadius
            color: Theme.lockGlass
            border.color: Theme.ring
            border.width: Theme.sizes.ringWidth
            visible: Players.hasPlayer
            player: Players.active
        }

        Row {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: over.spec.edge
            spacing: over.spec.cornerGap

            Repeater {
                model: ["sleep", "off"]

                Rectangle {
                    id: overCorner

                    required property string modelData

                    width: over.spec.cornerButton
                    height: over.spec.cornerButton
                    radius: over.spec.cornerButton / 2
                    color: Theme.lockGlass
                    border.color: Theme.ring
                    border.width: Theme.sizes.ringWidth

                    Components.Icon {
                        anchors.centerIn: parent
                        name: P.item(overCorner.modelData).icon
                        size: over.spec.cornerIcon
                    }
                }
            }
        }
    }
}
