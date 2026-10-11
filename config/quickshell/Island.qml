import QtQuick
import Quickshell
import Quickshell.Wayland

// The island's full-screen surface on one screen. Input is limited to the shape,
// except in modal states, where the whole surface catches clicks (click-outside closes), and in
// the line (fullscreen there, or hidden), where input is the hover zone at the top centre (plus the body while it grows).
PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    readonly property string baseState: IslandState.output === root.screen.name ? IslandState.current : "rest"
    // The line (reference 2.6) is an override, not an IslandState state: only at rest, and not while the
    // pointer is on the hover zone or the island body (which is taller than the zone). Leaving both ends
    // `hovered` after Theme.motion.lineLeaveDelayMs.
    readonly property bool lineWanted: IslandState.lineRequested(root.screen.name) && root.baseState === "rest"
    property bool hovered: false
    property bool zoneHovered: false
    property bool bodyHovered: false
    readonly property bool pointerOn: root.zoneHovered || root.bodyHovered
    onPointerOnChanged: {
        if (root.pointerOn) {
            lineLeave.stop();
            root.hovered = true;
        } else {
            lineLeave.restart();
        }
    }
    readonly property bool line: root.lineWanted && !root.hovered
    readonly property string effState: root.line ? "line" : root.baseState
    readonly property bool modalHere: IslandState.modal && IslandState.output === root.screen.name
    // The lock's way in (DESIGN W12): no key and no click reaches a window until the lock is on.
    readonly property bool wayIn: IslandState.lockPhase === "in"
    readonly property string maskMode: root.modalHere || root.wayIn ? "full" : root.lineWanted ? "line" : "shape"
    readonly property var geo: IslandState.geometryFor(root.effState)

    function reportMask(): void {
        IslandState.reportMask(root.screen.name, root.maskMode);
    }

    onMaskModeChanged: root.reportMask()
    onLineChanged: IslandState.reportLine(root.screen.name, root.line)
    onDevicePixelRatioChanged: IslandState.reportRatio(root.screen.name, root.devicePixelRatio)
    Component.onCompleted: {
        root.reportMask();
        IslandState.reportLine(root.screen.name, root.line);
        IslandState.reportRatio(root.screen.name, root.devicePixelRatio);
    }

    Connections {
        target: IslandState

        function onOutputChanged(): void {
            root.reportMask();
        }
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "wyspa"
    // The way in takes the keyboard on the focused output with no item holding focus: typed keys are dropped.
    WlrLayershell.keyboardFocus: Quickshell.env("WYSPA_TEST") !== "1" && (root.modalHere || root.wayIn && Niri.focusedOutput === root.screen.name) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // While the line is wanted, the input is the hover zone plus the body (which is inside the zone as the
    // line, and keeps the pointer from slipping out of the mask while it grows). Nothing else: the rest of
    // the screen stays click-through, a fullscreen window included.
    mask: Region {
        item: root.maskMode === "full" ? stage : shape.body

        Region {
            item: root.maskMode === "line" ? hoverZone : shape.body
        }
    }

    // Blur (W1) covers the body and both concave ears (an ear = rect minus ellipse),
    // only while the island is glass and not collapsed to the line. A zero-sized ear
    // is an empty region, so the ears drop out when `animEar` is 0.
    // `shape` is also a Region property name, so Regions read through these aliases.
    readonly property Item islandBody: shape.body
    readonly property real cornerRadius: shape.animR
    readonly property real earSize: shape.animEar
    property Region blurShape: Region {
        Region {
            item: root.islandBody
            bottomLeftRadius: root.cornerRadius
            bottomRightRadius: root.cornerRadius
        }
        Region {
            x: root.islandBody.x - root.earSize
            y: 0
            width: root.earSize
            height: root.earSize
        }
        Region {
            shape: RegionShape.Ellipse
            intersection: Intersection.Subtract
            x: root.islandBody.x - 2 * root.earSize
            y: 0
            width: 2 * root.earSize
            height: 2 * root.earSize
        }
        Region {
            x: root.islandBody.x + root.islandBody.width
            y: 0
            width: root.earSize
            height: root.earSize
        }
        Region {
            shape: RegionShape.Ellipse
            intersection: Intersection.Subtract
            x: root.islandBody.x + root.islandBody.width
            y: 0
            width: 2 * root.earSize
            height: 2 * root.earSize
        }
    }
    BackgroundEffect.blurRegion: Theme.glass && root.effState !== "line" && !IslandState.lockHides ? root.blurShape : null

    Timer {
        id: mediaLeave
        interval: Theme.motion.mediaLeaveMs
        onTriggered: {
            if (root.effState === "media")
                IslandState.close();
        }
    }

    Timer {
        id: lineLeave
        interval: Theme.motion.lineLeaveDelayMs
        onTriggered: root.hovered = false
    }

    FocusScope {
        id: stage
        anchors.fill: parent
        focus: root.modalHere && !root.wayIn
        Keys.onEscapePressed: IslandState.close()

        Item {
            id: hoverZone
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            width: Theme.geom.hoverZone.w
            height: Theme.geom.hoverZone.h

            HoverHandler {
                onHoveredChanged: root.zoneHovered = hovered
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.modalHere
            onClicked: IslandState.close()
        }

        // The power menu dims the screen (reference 3.8). A Rectangle takes no input, so the catcher above
        // still gets every click; the island body is declared after it and paints over it.
        Rectangle {
            anchors.fill: parent
            color: Theme.scrimDim
            opacity: root.effState === "power" ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.motion.dimMs
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.motion.easeCurve
                }
            }
        }

        IslandShape {
            id: shape
            anchors.fill: parent
            w: root.geo.w
            h: root.geo.h
            r: root.geo.r
            ears: root.geo.ears
            lineMode: root.effState === "line"
            // Hidden from the lock's way in (it fades out as the lock overlay's card grows out of it) until the card
            // docks again on the way back (Lock.qml).
            states: State {
                name: "lockHidden"
                when: IslandState.lockHides
                PropertyChanges { shape.opacity: 0 }
            }
            transitions: [
                Transition {
                    to: "lockHidden"
                    NumberAnimation { property: "opacity"; duration: Theme.reducedMotion ? 0 : Theme.layout.lock.exitOpacityMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.easeCurve }
                },
                Transition {
                    from: "lockHidden"
                    NumberAnimation { property: "opacity"; duration: Theme.reducedMotion ? 0 : Theme.layout.lock.earMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.easeCurve }
                }
            ]

            IslandContent {
                id: content
                anchors.fill: parent
                target: root.effState
                output: root.screen.name
                onShownChanged: IslandState.reportShown(root.screen.name, content.shown)
                Component.onCompleted: IslandState.reportShown(root.screen.name, content.shown)
            }

            HoverHandler {
                onHoveredChanged: root.bodyHovered = hovered
            }

            // The pointer on the island body (the shape's content area fills it). Leaving it while in the
            // media state closes that after Theme.motion.mediaLeaveMs; coming back cancels the close. Media
            // opened by IPC with the pointer elsewhere has no leave and so stays open. Always enabled: a
            // disabled handler clears `hovered` and a re-enabled one would only see the pointer on its next move.
            HoverHandler {
                onHoveredChanged: {
                    if (hovered || root.effState !== "media")
                        mediaLeave.stop();
                    else
                        mediaLeave.restart();
                }
            }
        }
    }

    // The lock's way in and way back (Lock.qml, DESIGN W12), above the island; it takes no input itself (the full mask of the way in only catches clicks).
    Loader {
        id: lockLoader

        anchors.fill: parent
        active: IslandState.lockPhase !== ""
        sourceComponent: LockOverlay {
            screen: root.screen
            devicePixelRatio: root.devicePixelRatio
        }
    }

    // A sleep lock (Lock.qml) replaces a playing overlay with a fresh one, which at zero durations is at its end look
    // from its first frame. Both writes are plain setters: no frame between the unmount and the mount.
    Connections {
        target: IslandState

        function onLockRemounted(): void {
            lockLoader.active = false;
            lockLoader.active = Qt.binding(() => IslandState.lockPhase !== "");
        }
    }
}
