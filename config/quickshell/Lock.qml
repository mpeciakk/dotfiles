pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import "components" as Components
import "states" as States
import "services"
import "lib/lock.js" as L
import "lib/power.js" as P

// The session lock (reference 3.10, DESIGN §6 "Blokada", R3, R21, R32, W12): a WlSessionLock with a surface per
// screen, and the lock overlay that animates both ways where the lock surface cannot. The protocol shows no window
// while the session is locked, and a surface hidden by the lock gets no new frame, so at the unlock the compositor
// shows its last one. Locking: the overlay plays the whole way in over the windows (the wallpaper fades in and blurs,
// the island becomes the card, its content and the mini player and Uśpij / Wyłącz buttons come in), then the lock
// goes on with a surface whose first frame is that same look. Unlocking: PAM (assets/pam.d/passwd) says yes, the
// lock goes at once, and the overlay, kept under the lock with that look as its last frame, plays the way back.
//
// engageLock() is the ONE place that locks: the power menu's Zablokuj (IslandState.lockRequested), the IPC
// `island lock` (IslandState.lockAsked), the idle monitor and a sleep (below) all end there, and it decides through
// L.engage(): in test mode (WYSPA_TEST=1) it only logs. tests/lock.test.mjs pins this. A request first closes the
// island, so no modal state (the launcher's field, the power menu's keys) receives the password typed next.
//
// Before every sleep (DESIGN W14: lid, Uśpij, `systemctl suspend`): logind's PrepareForSleep, watched by `monitor`,
// asks for the lock, and the sleep delay inhibitor (`inhibitor`) keeps logind waiting (5 s at most) until the lock is
// secure, then lets go until the wake. The way in plays at zero durations (Theme.lockInstant) and the lock goes on
// once every island window has presented a frame of its end look, so the frame niri shows at the unlock after the
// wake is the lock's look.
//
// Recovery: `qs ipc -p <config dir> call island unlock` drops the lock at once, without PAM (unlockNow()).
// If the shell dies while locked, the compositor keeps the screen locked and blank.
Scope {
    id: root

    readonly property bool testMode: Quickshell.env("WYSPA_TEST") === "1"
    readonly property var idle: L.idle(Theme.host.lock?.timeout, Theme.tokens.lock.timeoutDefault, root.testMode)
    // The last attempt was refused (the card shows it until the user types).
    property bool failed: false
    // What the card says about it: the attempt's PAM messages (pam_faillock's "account locked"), else the fixed text.
    property string failedText: L.refusalText([])
    // The attempt's PAM messages so far (the prompt excluded); PAM sends them before the prompt.
    property var attemptMessages: []
    // The typed text, held only from submit until PAM asks for it.
    property string pending: ""
    // The password was accepted; the lock goes handoffMs later.
    property bool unlocking: false
    // The way in (DESIGN W12): 0 none, 1 the overlay is playing it (the lock follows when it ends), 2 it ended.
    property int prelude: 0
    property string preludeFor: ""
    // The hand-off overlay is playing the morph back to rest (from the unlock for the morph or the wallpaper's fade,
    // whichever is longer). It outlives the lock.
    property bool handoff: false
    // The island is back (its fade-in started); false from accept() until earDelayMs after the unlock.
    property bool islandBack: true
    // Whether the session is locked, for bindings. WlSessionLock's `locked` reads right but does not notify an unlock
    // (Quickshell 0.3.2 session_lock.cpp unlock() emits lockStateChanged only `if (this->isLocked())`, i.e. never
    // after unlocking), so a binding on it stays true: the island stayed hidden, the idle monitor off, IPC `locked`
    // true. Set on every lock (engageLock) and unlock (released()); imperative reads of sessionLock.locked are fine.
    property bool lockOn: false
    onLockOnChanged: IslandState.reportLocked(root.lockOn)
    // logind is about to sleep (PrepareForSleep true until false), and whether the session lock is secure.
    property bool sleepPending: false
    readonly property bool lockSecure: root.lockOn && sessionLock.secure
    // Test mode starts neither the monitor nor the inhibitor (lib/lock.js: only an explicit false test mode does).
    readonly property bool watchSleep: L.sleepWatched(root.testMode)
    readonly property bool holdInhibitor: L.inhibitorWanted(root.testMode, root.sleepPending, root.lockSecure)
    onHoldInhibitorChanged: root.syncInhibitor()
    // The outputs whose window has presented a frame of the overlay's end look since a sleep lock began.
    property var framed: ({})
    // From the way in (the island fades out as the overlay's card grows out of it), through the lock, until
    // earDelayMs after the unlock.
    readonly property bool hidesIsland: root.prelude !== 0 || root.lockOn || !root.islandBack
    onHidesIslandChanged: IslandState.reportLockHides(root.hidesIsland)
    // For the lock overlay in each island window (LockOverlay.qml): "in", "locked", "back" or "".
    readonly property string lockPhase: root.lockOn ? "locked" : root.handoff ? "back" : root.prelude !== 0 ? "in" : ""
    onLockPhaseChanged: IslandState.reportLockPhase(root.lockPhase)

    // A refused attempt: every surface's card shakes.
    signal attemptFailed

    function engageLock(source: string): void {
        // A request between an accepted password and the unlock (handoffMs, 0 by default: one event-loop turn): the
        // session is still locked, so there is nothing to lock again; cancel the unlock instead of dropping the request.
        if (L.keepsLocked(root.testMode, sessionLock.locked, root.unlocking)) {
            console.info("lock: request before the unlock, staying locked (" + source + ")");
            releaseTimer.stop();
            root.stopHandoff();
            root.unlocking = false;
            return;
        }
        const d = L.engage(root.testMode, sessionLock.locked);
        console.info(d.message + " (" + source + ")");
        if (!d.engage)
            return;
        // First the way in on the overlay (L.lockStep): this returns, and preludeTimer comes back here to lock. A
        // request during it waits for the same lock. During the hand-off the overlay turns round from where it is.
        // A sleep: the instant mode goes on before the island closes, so the close morph of an open state (the power
        // menu's Uśpij) is at zero durations too and leaves no stale frame in flight.
        const sleep = source === "sleep";
        const wasInstant = Theme.lockInstant;
        if (sleep)
            Theme.lockInstant = true;
        IslandState.close();
        const step = L.lockStep(root.prelude, Theme.reducedMotion, sleep, wasInstant);
        if (step === "snap") {
            // A sleep: logind waits 5 s at most. The way in plays at zero durations, on a fresh overlay when one is
            // mounted already, and the lock follows when every window has presented a frame of it (or at the cap).
            preludeTimer.stop();
            root.framed = ({});
            IslandState.reportLockFrameWait(true);
            const mounted = root.prelude !== 0 || root.handoff;
            root.prelude = 1;
            root.stopHandoff();
            root.preludeFor = source;
            if (mounted)
                IslandState.remountLock();
            frameCapTimer.restart();
            return;
        }
        if (step === "prelude") {
            // The way in first, then the hand-off stops: the phase goes straight from "back" to "in" (no "" between,
            // which would drop the overlay for a frame).
            root.prelude = 1;
            root.stopHandoff();
            root.preludeFor = source;
            preludeTimer.restart();
            return;
        }
        if (step === "wait")
            return;
        root.failed = false;
        root.unlocking = false;
        sessionLock.locked = true;
        root.lockOn = sessionLock.locked;
        // A sleep lock is done waiting (the way back plays at its normal speed).
        frameCapTimer.stop();
        IslandState.reportLockFrameWait(false);
        Theme.lockInstant = false;
        // Only now: the phase goes straight from "in" to "locked" (a "" between dropped the overlay and showed the
        // windows for a moment before the lock).
        preludeTimer.stop();
        root.prelude = 0;
        root.stopHandoff();
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
        root.attemptMessages = [];
        if (!pam.start()) {
            root.pending = "";
            root.refuse();
        }
    }

    function refuse(): void {
        console.info("lock: authentication failed");
        root.failedText = L.refusalText(root.attemptMessages);
        root.failed = true;
        root.attemptFailed();
    }

    // PAM said yes: releaseTimer drops the lock at once (handoffMs) and the overlay plays the whole way back from its
    // last frame, the lock's look.
    function accept(): void {
        console.info("lock: authentication succeeded");
        root.unlocking = true;
        root.islandBack = false;
        releaseTimer.restart();
    }

    function stopHandoff(): void {
        handoffEnd.stop();
        islandTimer.stop();
        root.handoff = false;
        root.islandBack = true;
    }

    // The recovery hatch (`island unlock`): at once, no PAM, no morph. Harmless while not locked.
    function unlockNow(): void {
        console.info("lock: unlock hatch");
        if (pam.active)
            pam.abort();
        root.pending = "";
        releaseTimer.stop();
        preludeTimer.stop();
        root.prelude = 0;
        frameCapTimer.stop();
        IslandState.reportLockFrameWait(false);
        Theme.lockInstant = false;
        root.stopHandoff();
        sessionLock.locked = false;
        root.released();
    }

    // A line of the logind monitor: a sleep start records it and asks for the lock; the wake clears it.
    function onSleepSignal(line: string): void {
        const kind = L.sleepSignal(line);
        if (kind === "start") {
            root.sleepPending = true;
            root.engageLock("sleep");
        } else if (kind === "resume") {
            root.sleepPending = false;
        }
    }

    // Starts or stops the delay inhibitor to match holdInhibitor. A restart after an exit comes here too, so a release
    // during a pending sleep is never undone. `running = true` is asked for whenever it is wanted, even while a
    // released process is still exiting (Quickshell keeps the request and starts again when it is gone): the retake
    // after a wake never waits for inhibitRestart.
    function syncInhibitor(): void {
        if (root.holdInhibitor)
            inhibitor.running = true;
        else if (!root.holdInhibitor && inhibitor.running)
            inhibitor.running = false;
    }

    // (Re)starts the monitor. A restart has seen no events: a stale `sleepPending` must not outlive it.
    function syncMonitor(): void {
        if (root.watchSleep && !monitor.running) {
            root.sleepPending = false;
            monitor.running = true;
        }
    }

    Component.onCompleted: {
        root.syncMonitor();
        root.syncInhibitor();
    }

    // The session is unlocked (by us, or by the compositor): what the lock held goes.
    function released(): void {
        root.lockOn = false;
        root.unlocking = false;
        root.failed = false;
        root.pending = "";
    }

    Timer {
        id: releaseTimer

        interval: Theme.reducedMotion ? 0 : Theme.layout.lock.handoffMs
        // The hand-off first: the unlock clears `secure` at once, and with no hand-off yet the overlay would go and
        // come back already at its end (no animation at all).
        onTriggered: {
            root.handoff = !Theme.reducedMotion;
            handoffEnd.restart();
            islandTimer.restart();
            sessionLock.locked = false;
            root.released();
        }
    }

    // The way in has played (L.lockInMs: the morph, the wallpaper, the card's content and the extras): lock.
    Timer {
        id: preludeTimer

        interval: L.lockInMs(Theme.motion, Theme.layout.lock)
        onTriggered: {
            root.prelude = 2;
            root.engageLock(root.preludeFor);
        }
    }

    // The sleep lock's way in is waiting for its frames: after the cap the lock goes on anyway (logind's 5 s is the
    // limit; a refused or slow frame must not eat it).
    Timer {
        id: frameCapTimer

        interval: Theme.tokens.lock.sleepFrameCapMs
        onTriggered: {
            root.prelude = 2;
            root.engageLock(root.preludeFor);
        }
    }

    Timer {
        id: inhibitRestart

        interval: Theme.tokens.lock.sleepRestartMs
        onTriggered: root.syncInhibitor()
    }

    Timer {
        id: monitorRestart

        interval: Theme.tokens.lock.sleepRestartMs
        onTriggered: root.syncMonitor()
    }

    // The sleep delay inhibitor: logind waits (5 s at most) for it to go before it suspends. `sleep infinity` is only
    // what it holds on to; the lock lives as long as the process does.
    Process {
        id: inhibitor

        command: ["systemd-inhibit", "--what=sleep", "--mode=delay", "--who=wyspa", "--why=lock the session before sleep", "sleep", "infinity"]
        onExited: inhibitRestart.restart()
    }

    // PrepareForSleep on the system bus (the line format is lib/lock.js sleepSignal's).
    Process {
        id: monitor

        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1", "--object-path", "/org/freedesktop/login1"]
        stdout: SplitParser {
            onRead: line => root.onSleepSignal(line)
        }
        onExited: monitorRestart.restart()
    }

    Timer {
        id: handoffEnd

        // The morph, the wallpaper's fade or the card's cross-fade with the island, whichever ends last.
        interval: Theme.reducedMotion ? 0 : Math.max(Theme.motion.lockMorphMs, Theme.layout.lock.deskDelayMs + Theme.layout.lock.deskMs, Theme.layout.lock.earDelayMs + Theme.layout.lock.earMs)
        onTriggered: root.handoff = false
    }

    Timer {
        id: islandTimer

        interval: Theme.reducedMotion ? 0 : Theme.layout.lock.earDelayMs
        onTriggered: root.islandBack = true
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

        // A window of the island has presented a frame while a sleep lock waits for them: lock when all have.
        function onLockFramePresented(output: string): void {
            if (root.prelude !== 1 || !Theme.lockInstant)
                return;
            root.framed[output] = true;
            if (!L.framesPresented(Quickshell.screens.map(s => s.name), root.framed))
                return;
            frameCapTimer.stop();
            root.prelude = 2;
            root.engageLock(root.preludeFor);
        }
    }

    // Idle lock after the host's lock.timeout seconds (default lock.timeoutDefault; 0 disables it; never in test
    // mode). respectInhibitors: no lock while something inhibits idle (a fullscreen video).
    IdleMonitor {
        enabled: root.idle.enabled && !root.lockOn
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
        onPamMessage: root.attemptMessages = L.collectMessage(root.attemptMessages, pam.message, pam.responseRequired)
        // One refusal per attempt: error() is always followed by completed(PamResult.Error), which refuses.
        onCompleted: result => {
            root.pending = "";
            if (result === PamResult.Success)
                root.accept();
            else
                root.refuse();
        }
        onError: {
            root.pending = "";
        }
    }

    // The lock screen's Uśpij / Wyłącz go through the one power gate (test mode: it only logs).
    Components.PowerActions {
        id: actions
    }

    WlSessionLock {
        id: sessionLock

        // The compositor can end the lock on its own (finished, or another client holds the lock); that arrives only as a
        // secure-state change (see lockOn), emitted while `locked` still reads true but `secure` already false
        // (Quickshell 0.3.2 lock.cpp unlock() clears the manager's active lock before it emits). released() is
        // idempotent, so our own unlock passing here too is harmless.
        onSecureStateChanged: {
            if (!sessionLock.secure && root.lockOn)
                root.released();
        }

        surface: Component {
            WlSessionLockSurface {
                id: surface

                // The locked look from the first frame: the overlay played the way in (W12).
                readonly property bool shown: !root.unlocking
                readonly property var wp: Theme.lockWallpaper
                readonly property var spec: Theme.layout.lock
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
                Component.onCompleted: card.focusField()

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
                        // Synchronous, so the first frame has it (that frame must match the overlay's); a pixmap-cache hit.
                        asynchronous: false
                        sourceSize.width: surface.screen ? surface.screen.width * surface.screen.devicePixelRatio : 0
                        sourceSize.height: surface.screen ? surface.screen.height * surface.screen.devicePixelRatio : 0
                        scale: surface.wp.scale
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            autoPaddingEnabled: false
                            blurEnabled: true
                            blur: 1
                            blurMax: surface.wp.blur
                            saturation: surface.wp.saturate - 1
                            brightness: surface.wp.brightness - 1
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

                    // The centred card (R21), where the overlay's way in left it.
                    States.LockCard {
                        id: card

                        width: Theme.geom.lock.w
                        height: Theme.geom.lock.h
                        x: (surface.width - card.width) / 2
                        y: (surface.height - card.height) / 2
                        enterAnimated: false
                        revealed: surface.shown
                        failed: root.failed
                        failedText: root.failedText
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

                // The extras, in from the first frame; they take input only while locked and shown.
                Item {
                    id: extras

                    anchors.fill: parent
                    opacity: 0
                    enabled: sessionLock.locked && surface.shown

                    states: State {
                        name: "shown"
                        when: surface.shown
                        PropertyChanges { extras.opacity: 1 }
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
