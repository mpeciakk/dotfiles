import QtQuick
import QtQuick.Effects

// Hosts one layer per state component and cross-fades them (§2.8): the layer of
// `target` enters, every other layer exits. Layers stay mounted. Each is as wide
// as its state's geometry from the start, centred, so nothing reflows during a morph.
Item {
    id: root

    // The state to show (named `target`: `state` would shadow Item.state).
    property string target: "rest"
    property string output: ""
    // state -> component url; every state task adds exactly one entry here.
    property var sources: ({
        rest: "states/Rest.qml",
        osd: "states/Osd.qml",
        toast: "states/Toast.qml",
        center: "states/Center.qml",
        launcher: "states/Launcher.qml",
        control: "states/Control.qml",
        media: "states/Media.qml",
        power: "states/Power.qml",
        powerDone: "states/PowerDone.qml"
    })

    // The state whose layer has fully entered; "" while a transition runs.
    readonly property string shown: root.settled ? root.target : ""

    property bool settled: true

    // Reduced motion (R25) is a plain crossfade: no delay, scale or blur.
    readonly property int enterMs: {
        if (Theme.reducedMotion)
            return Theme.motion.reducedFadeMs;
        const m = Theme.motion;
        const opacityEnd = m.enterOpacityDelayMs + m.enterOpacityMs;
        if (!(root.target in root.sources))
            return opacityEnd;
        return Math.max(opacityEnd, m.enterScaleDelayMs + m.enterScaleMs, m.enterBlurDelayMs + m.enterBlurMs);
    }

    onTargetChanged: {
        root.settled = false;
        enterTimer.restart();
    }

    Timer {
        id: enterTimer
        interval: root.enterMs
        onTriggered: root.settled = true
    }

    Repeater {
        model: Object.keys(root.sources)

        Item {
            id: slot

            required property string modelData

            readonly property bool lit: root.target === slot.modelData
            readonly property bool fancy: !Theme.reducedMotion
            readonly property var geo: IslandState.geometryFor(slot.modelData)

            // §2.8: only the enter has a delay; exits use the fast-start exit curve. The enter and the exit are
            // two Transitions, not Behaviors: a Behavior's durations are bindings on `lit`, and when `lit` flips
            // the animation could start before they re-evaluated, so rest -> media -> rest -> media ran with the
            // other direction's timings (media in at once, rest out after the enter delay, both visible).
            function pause(delay: int): int {
                return slot.fancy ? delay : 0;
            }

            function span(ms: int): int {
                return slot.fancy ? ms : Theme.motion.reducedFadeMs;
            }

            x: (root.width - slot.width) / 2
            y: 0
            width: slot.geo.w
            height: slot.geo.h
            transformOrigin: Item.Center
            enabled: slot.lit
            opacity: 0
            scale: slot.fancy ? Theme.motion.contentScaleFrom : 1
            property real blur: slot.fancy ? Theme.motion.contentBlur : 0

            states: State {
                name: "lit"
                when: slot.lit
                PropertyChanges { slot.opacity: 1; slot.scale: 1; slot.blur: 0 }
            }

            transitions: [
                Transition {
                    to: "lit"
                    SequentialAnimation {
                        PauseAnimation { duration: slot.pause(Theme.motion.enterOpacityDelayMs) }
                        NumberAnimation { property: "opacity"; duration: slot.span(Theme.motion.enterOpacityMs); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.enterCurve }
                    }
                    SequentialAnimation {
                        PauseAnimation { duration: slot.pause(Theme.motion.enterScaleDelayMs) }
                        NumberAnimation { property: "scale"; duration: slot.span(Theme.motion.enterScaleMs); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.enterCurve }
                    }
                    SequentialAnimation {
                        PauseAnimation { duration: slot.pause(Theme.motion.enterBlurDelayMs) }
                        NumberAnimation { property: "blur"; duration: slot.span(Theme.motion.enterBlurMs); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.easeCurve }
                    }
                },
                Transition {
                    from: "lit"
                    NumberAnimation { property: "opacity"; duration: slot.span(Theme.motion.exitOpacityMs); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.exitCurve }
                    NumberAnimation { property: "scale"; duration: slot.span(Theme.motion.exitScaleMs); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.exitCurve }
                    NumberAnimation { property: "blur"; duration: slot.span(Theme.motion.exitBlurMs); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.easeCurve }
                }
            ]

            Item {
                anchors.fill: parent
                layer.enabled: slot.blur > 0
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: slot.blur / Theme.motion.contentBlur
                    blurMax: Theme.motion.contentBlur
                }

                Loader {
                    id: loader
                    anchors.fill: parent
                    source: root.sources[slot.modelData]
                }

                Binding {
                    target: loader.item
                    property: "active"
                    value: slot.lit
                    when: loader.status === Loader.Ready
                }
                Binding {
                    target: loader.item
                    property: "output"
                    value: root.output
                    when: loader.status === Loader.Ready
                }
            }
        }
    }
}
