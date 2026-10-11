pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import "components" as Components
import "states" as States
import "services"
import "lib/lock.js" as L
import "lib/power.js" as P

// The session lock (reference 3.10, DESIGN §6 "Blokada", R3, R21, R32): a WlSessionLock with a surface per
// screen. The wallpaper blurs, the card morphs in from the rest island's geometry to the centre of the screen,
// the mini player and the Uśpij / Wyłącz buttons fade in. PAM (assets/pam.d/passwd) checks the password; on
// success the card morphs back to rest and only then does the lock go.
//
// engageLock() is the ONE place that locks: the power menu's Zablokuj (IslandState.lockRequested), the IPC
// `island lock` (IslandState.lockAsked) and the idle monitor all end there, and it decides through L.engage():
// in test mode (WYSPA_TEST=1) it only logs. tests/lock.test.mjs pins this.
//
// Recovery: `qs ipc -p <config dir> call island unlock` drops the lock at once, without PAM (unlockNow()).
// If the shell dies while locked, the compositor keeps the screen locked and blank.
Scope {
    id: root

    readonly property bool testMode: Quickshell.env("WYSPA_TEST") === "1"
    readonly property var idle: L.idle(Theme.host.lock?.timeout, Theme.tokens.lock.timeoutDefault, root.testMode)
    // The last attempt was refused (the card shows it until the user types).
    property bool failed: false
    // The typed text, held only from submit until PAM asks for it.
    property string pending: ""
    // The reverse morph to rest is running; the lock goes when it ends.
    property bool unlocking: false

    // A refused attempt: every surface's card shakes.
    signal attemptFailed

    function engageLock(source: string): void {
        // A request during the reverse morph (the password was accepted, the card is leaving): the session is
        // still locked, so there is nothing to lock again; cancel the leaving instead of dropping the request.
        if (L.keepsLocked(root.testMode, sessionLock.locked, root.unlocking)) {
            console.info("lock: request during the unlock morph, staying locked (" + source + ")");
            releaseTimer.stop();
            root.unlocking = false;
            return;
        }
        const d =L.engage(root.testMode, sessionLock.locked);
        console.info(d.message + " (" + source + ")");
        if (!d.engage)
            return;
        root.failed = false;
        root.unlocking = false;
        sessionLock.locked = true;
    }

    function authenticate(typed: string): void {
        if (root.testMode) {
            console.info("lock (test mode): would authenticate");
            return;
        }
        if (pam.active || root.unlocking || !sessionLock.locked || typed.length === 0)
            return;
        root.failed = false;
        root.pending = typed;
        if (!pam.start()) {
            root.pending = "";
            root.refuse();
        }
    }

    function refuse(): void {
        console.info("lock: authentication failed");
        root.failed = true;
        root.attemptFailed();
    }

    // PAM said yes: the surfaces morph back to rest; releaseTimer drops the lock once they have.
    function accept(): void {
        console.info("lock: authentication succeeded");
        root.unlocking = true;
        releaseTimer.restart();
    }

    // The recovery hatch (`island unlock`): at once, no PAM, no morph. Harmless while not locked.
    function unlockNow(): void {
        console.info("lock: unlock hatch");
        if (pam.active)
            pam.abort();
        root.pending = "";
        releaseTimer.stop();
        sessionLock.locked = false;
    }

    Timer {
        id: releaseTimer

        interval: Theme.reducedMotion ? 0 : Theme.motion.lockMorphMs
        onTriggered: sessionLock.locked = false
    }

    Connections {
        target: IslandState

        function onLockRequested(): void {
            root.engageLock("power menu");
        }

        function onLockAsked(): void {
            root.engageLock("ipc");
        }

        function onUnlockAsked(): void {
            root.unlockNow();
        }
    }

    // Idle lock after the host's lock.timeout seconds (default lock.timeoutDefault; 0 disables it; never in test
    // mode). respectInhibitors: no lock while something inhibits idle (a fullscreen video).
    IdleMonitor {
        enabled: root.idle.enabled && !sessionLock.locked
        timeout: root.idle.timeout
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) root.engageLock("idle")
    }

    PamContext {
        id: pam

        config: "passwd"
        configDirectory: Quickshell.shellDir + "/assets/pam.d"

        onResponseRequiredChanged: {
            if (!pam.responseRequired)
                return;
            pam.respond(root.pending);
            root.pending = "";
        }
        onCompleted: result => {
            root.pending = "";
            if (result === PamResult.Success)
                root.accept();
            else
                root.refuse();
        }
        onError: {
            root.pending = "";
            root.refuse();
        }
    }

    // The lock screen's Uśpij / Wyłącz go through the one power gate (test mode: it only logs).
    Components.PowerActions {
        id: actions
    }

    WlSessionLock {
        id: sessionLock

        onLockStateChanged: {
            IslandState.reportLocked(sessionLock.locked);
            if (!sessionLock.locked) {
                root.unlocking = false;
                root.failed = false;
                root.pending = "";
            }
        }

        surface: Component {
            WlSessionLockSurface {
                id: surface

                // False for the first frame, so everything enters from its unlocked end.
                property bool entered: false
                readonly property bool shown: surface.entered && !root.unlocking
                readonly property var wp: Theme.lockWallpaper
                readonly property var spec: Theme.layout.lock
                readonly property var rest: IslandState.badge ? Theme.geom.restBadge : Theme.geom.rest

                // 0 = the rest island, 1 = the card (reference 3.10: 640 ms Curve S).
                property real morph: surface.shown ? 1 : 0
                Behavior on morph {
                    NumberAnimation {
                        duration: Theme.reducedMotion ? 0 : Theme.motion.lockMorphMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.motion.morphCurve
                    }
                }

                // 0 = the plain wallpaper, 1 = blurred, saturated, dimmed and scaled (700 ms Curve S).
                property real veil: surface.shown ? 1 : 0
                Behavior on veil {
                    NumberAnimation {
                        duration: Theme.reducedMotion ? 0 : Theme.motion.wallpaperMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.motion.morphCurve
                    }
                }

                // The corner buttons' hold (lib/power.js reduce, R32): pointer events and key releases only. A key
                // press is never handed over: a letter typed into the password field must not start a hold.
                property var hold: P.initial()

                function dispatch(ev: var): void {
                    const pressing = ev.type === "pointerPress" || ev.type === "pointerClick";
                    if (pressing && !(sessionLock.locked && surface.shown))
                        return;
                    const r = P.reduce(surface.hold, ev);
                    surface.hold = r.state;
                    if (r.effect.type === "start") {
                        holdTimer.restart();
                    } else if (r.effect.type === "cancel") {
                        holdTimer.stop();
                    } else if (r.effect.type === "finish") {
                        holdTimer.stop();
                        actions.perform(r.effect.kind);
                    }
                }

                color: "black"

                onShownChanged: surface.dispatch({ type: "active", on: surface.shown })
                Component.onCompleted: {
                    surface.entered = true;
                    card.focusField();
                }

                Timer {
                    id: holdTimer

                    interval: Theme.motion.holdMs
                    onTriggered: surface.dispatch({ type: "timerElapsed" })
                }

                Item {
                    anchors.fill: parent
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: Theme.wallpaper ? "file://" + Theme.wallpaper : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: surface.screen ? surface.screen.width * surface.screen.devicePixelRatio : 0
                        sourceSize.height: surface.screen ? surface.screen.height * surface.screen.devicePixelRatio : 0
                        scale: 1 + (surface.wp.scale - 1) * surface.veil
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            autoPaddingEnabled: false
                            blurEnabled: true
                            blur: surface.veil
                            blurMax: surface.wp.blur
                            saturation: (surface.wp.saturate - 1) * surface.veil
                            brightness: (surface.wp.brightness - 1) * surface.veil
                        }
                    }
                }

                // Key releases end a running hold (the safe side); the field keeps every key press.
                Item {
                    anchors.fill: parent

                    Keys.onReleased: event => {
                        surface.dispatch({ type: "keyUp", code: event.key, repeat: event.isAutoRepeat });
                        event.accepted = false;
                    }

                    // From the rest island (top centre, rest size and corners) to the centred card (R21).
                    States.LockCard {
                        id: card

                        width: surface.rest.w + (Theme.geom.lock.w - surface.rest.w) * surface.morph
                        height: surface.rest.h + (Theme.geom.lock.h - surface.rest.h) * surface.morph
                        x: (surface.width - card.width) / 2
                        y: (surface.height - Theme.geom.lock.h) / 2 * surface.morph
                        topRadius: Theme.geom.lock.r * surface.morph
                        bottomRadius: surface.rest.r + (Theme.geom.lock.r - surface.rest.r) * surface.morph
                        revealed: surface.shown
                        failed: root.failed
                        busy: pam.active || root.unlocking
                        onSubmitted: typed => root.authenticate(typed)

                        Connections {
                            target: root

                            function onAttemptFailed(): void {
                                card.shake();
                            }
                        }
                    }
                }

                // The extras fade in after the card and out at once; they take input only while locked and shown.
                Item {
                    anchors.fill: parent
                    opacity: surface.shown ? 1 : 0
                    enabled: sessionLock.locked && surface.shown

                    Behavior on opacity {
                        SequentialAnimation {
                            PauseAnimation { duration: surface.shown && !Theme.reducedMotion ? surface.spec.extrasDelayMs : 0 }
                            NumberAnimation {
                                duration: Theme.reducedMotion ? 0 : surface.spec.extrasMs
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Theme.motion.easeCurve
                            }
                        }
                    }

                    Components.MiniPlayer {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: surface.spec.edge
                        width: surface.spec.playerW
                        height: surface.spec.playerH
                        radius: surface.spec.playerRadius
                        color: Theme.lockGlass
                        border.color: Theme.ring
                        border.width: Theme.sizes.ringWidth
                        visible: Players.hasPlayer
                        player: Players.active
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: surface.spec.edge
                        spacing: surface.spec.cornerGap

                        Repeater {
                            model: ["sleep", "off"]

                            Rectangle {
                                id: corner

                                required property string modelData

                                readonly property var item: P.item(corner.modelData)
                                readonly property bool held: surface.hold.holding === corner.modelData
                                // 0 = ring empty, 1 = full; fills over holdMs, rewinds over holdCancelMs.
                                property real progress: corner.held ? 1 : 0

                                width: surface.spec.cornerButton
                                height: surface.spec.cornerButton
                                radius: surface.spec.cornerButton / 2
                                color: area.containsMouse ? Theme.hover : Theme.lockGlass
                                border.color: Theme.ring
                                border.width: Theme.sizes.ringWidth
                                Accessible.name: corner.item.label

                                Behavior on progress {
                                    NumberAnimation {
                                        duration: corner.held ? Theme.motion.holdMs : Theme.motion.holdCancelMs
                                        easing.type: corner.held ? Easing.Linear : Easing.BezierSpline
                                        easing.bezierCurve: Theme.motion.easeCurve
                                    }
                                }

                                Shape {
                                    anchors.fill: parent
                                    visible: corner.progress > 0
                                    preferredRendererType: Shape.CurveRenderer

                                    ShapePath {
                                        strokeColor: corner.item.danger ? Theme.danger : Theme.accent
                                        strokeWidth: Theme.layout.power.ringWidth
                                        fillColor: "transparent"
                                        capStyle: ShapePath.RoundCap

                                        PathAngleArc {
                                            centerX: surface.spec.cornerButton / 2
                                            centerY: surface.spec.cornerButton / 2
                                            radiusX: surface.spec.ringRadius
                                            radiusY: surface.spec.ringRadius
                                            startAngle: Theme.layout.power.ringStart
                                            sweepAngle: Theme.layout.power.ringSweep * corner.progress
                                        }
                                    }
                                }

                                Components.Icon {
                                    anchors.centerIn: parent
                                    name: corner.item.icon
                                    size: surface.spec.cornerIcon
                                }

                                MouseArea {
                                    id: area

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onPressed: surface.dispatch({ type: "pointerPress", kind: corner.modelData })
                                    onClicked: surface.dispatch({ type: "pointerClick", kind: corner.modelData })
                                    onReleased: surface.dispatch({ type: "pointerRelease", kind: corner.modelData })
                                    onCanceled: surface.dispatch({ type: "pointerRelease", kind: corner.modelData })
                                    onExited: surface.dispatch({ type: "pointerRelease", kind: corner.modelData })
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
