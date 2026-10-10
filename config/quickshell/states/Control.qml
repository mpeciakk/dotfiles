import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking as QsNetworking
import ".."
import "../services"
import "../components" as Components
import "../lib/slider.js" as S

// The control panel (reference 3.7, R24): clock and date, Wi-Fi / Bluetooth tiles, volume and brightness
// sliders, round toggles (Skupienie = DND, Motyw, Zasilanie) and a mini player. What the machine lacks is
// left out and the content stays top-aligned: no NetworkManager hides the Wi-Fi tile, no BlueZ adapter the
// Bluetooth tile (both gone: the row is gone), no backlight the brightness slider, no player the mini player.
// In test mode (WYSPA_TEST=1) nothing real is ever changed: every action only logs what it would do.
Item {
    id: root

    // Set by IslandContent for every state layer.
    property bool active: false
    property string output: ""

    readonly property var spec: Theme.layout.control
    readonly property bool testMode: Quickshell.env("WYSPA_TEST") === "1"
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var btDevice: (root.adapter?.devices?.values ?? []).find(d => d.connected) ?? null
    // Aliased: an unqualified `Network` would be Quickshell.Networking's type, not the Network service.
    readonly property bool wifiOn: QsNetworking.Networking.wifiEnabled ?? false
    readonly property real innerW: width - 2 * root.spec.pad
    readonly property bool darkMode: Theme.mode === "dark"

    // The one place the panel changes anything; test mode only logs.
    function perform(what: string, action: var): void {
        if (root.testMode)
            console.info("control (test mode): would " + what);
        else
            action();
    }

    function percent(fraction: real): int {
        return Math.round(fraction * root.spec.percent);
    }

    // Brightness goes to brightnessctl through a leading-and-trailing throttle (lib/slider.js): one call
    // per tick at most, the last requested value always sent (also on release), and a wheel step starts
    // from the last requested value while one is pending, not from the lagging sysfs value.
    property var brightnessQ: S.idle()
    readonly property real brightnessBase: S.base(root.brightnessQ, Brightness.value)

    function sendBrightness(f: real): void {
        root.perform("set the brightness to " + root.percent(f) + "%", () => Brightness.set(f));
    }

    function requestBrightness(f: real): void {
        const r = S.request(root.brightnessQ, f);
        root.brightnessQ = r.state;
        if (r.send !== null) {
            root.sendBrightness(r.send);
            brightnessTimer.restart();
        }
    }

    function flushBrightness(): void {
        const r = S.flush(root.brightnessQ);
        root.brightnessQ = r.state;
        if (r.send !== null)
            root.sendBrightness(r.send);
    }

    Timer {
        id: brightnessTimer

        interval: root.spec.brightnessThrottleMs
        repeat: true
        onTriggered: {
            const r = S.tick(root.brightnessQ);
            root.brightnessQ = r.state;
            if (r.send !== null)
                root.sendBrightness(r.send);
            else
                brightnessTimer.stop();
        }
    }

    // A tile of the Wi-Fi / Bluetooth row: an accent circle (dimmed while off) with a title and a status line.
    // Informational only: it shows the radio's actual state and never changes it.
    component Tile: Rectangle {
        id: tile

        property string icon
        property string title
        property string sub
        property bool checked: true

        readonly property var spec: Theme.layout.control

        implicitHeight: tile.spec.tileCircle + 2 * tile.spec.tilePad
        radius: Theme.radii.tile
        color: Theme.tile

        Row {
            anchors.fill: parent
            anchors.margins: tile.spec.tilePad
            spacing: tile.spec.tileGap

            Rectangle {
                width: tile.spec.tileCircle
                height: tile.spec.tileCircle
                radius: tile.spec.tileCircle / 2
                color: tile.checked ? Theme.accent : Theme.sel

                Components.Icon {
                    anchors.centerIn: parent
                    name: tile.icon
                    color: tile.checked ? Theme.onAccent : Theme.fg
                    size: tile.spec.tileIcon
                }
            }

            Column {
                width: parent.width - tile.spec.tileCircle - tile.spec.tileGap
                anchors.verticalCenter: parent.verticalCenter
                spacing: tile.spec.tileTextGap

                Text {
                    width: parent.width
                    text: tile.title
                    elide: Text.ElideRight
                    color: Theme.fg
                    font.family: Theme.fonts.ui
                    font.pixelSize: tile.spec.tileTitleFont
                    font.weight: Font.Medium
                }

                Text {
                    width: parent.width
                    text: tile.sub
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: Theme.fgMuted
                    font.family: Theme.fonts.ui
                    font.pixelSize: tile.spec.tileSubFont
                }
            }
        }
    }

    // An icon, a track filled to `fraction` and the value. A click or drag on the track and the wheel
    // ask for a new fraction through `moved` (`settled` when the pointer is released); the fill only ever
    // follows `fraction`. A wheel step starts from `value`, the real level (a muted volume keeps its stored
    // level while `fraction` shows an empty track), and `min` is the lowest fraction the row can request.
    component SliderRow: Item {
        id: slider

        property string icon
        property real fraction: 0
        property real value: slider.fraction
        property real min: 0
        property string valueText
        property bool animated: true
        signal moved(real fraction)
        signal settled

        readonly property var spec: Theme.layout.control

        function clamp(f: real): real {
            return Math.max(0, Math.min(1, f));
        }

        // Pure slider arithmetic answers null when nothing should change (zero wheel delta, no width).
        function request(f: var): void {
            if (f !== null)
                slider.moved(f);
        }

        implicitHeight: slider.spec.sliderIcon

        Components.Icon {
            id: sliderIcon

            anchors.verticalCenter: parent.verticalCenter
            name: slider.icon
            color: Theme.fgMuted
            size: slider.spec.sliderIcon
        }

        Rectangle {
            id: track

            anchors.left: sliderIcon.right
            anchors.leftMargin: slider.spec.sliderGap
            anchors.right: valueLabel.left
            anchors.rightMargin: slider.spec.sliderGap
            anchors.verticalCenter: parent.verticalCenter
            height: slider.spec.trackH
            radius: slider.spec.trackRadius
            color: Theme.track
            clip: true

            Rectangle {
                width: parent.width * slider.clamp(slider.fraction)
                height: parent.height
                radius: slider.spec.trackRadius
                color: Theme.sliderFill

                Behavior on width {
                    enabled: slider.animated && !hitArea.pressed
                    NumberAnimation {
                        duration: Theme.motion.osdBarMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.motion.enterCurve
                    }
                }
            }
        }

        MouseArea {
            id: hitArea

            anchors.left: track.left
            anchors.right: track.right
            anchors.verticalCenter: track.verticalCenter
            height: slider.spec.hitH
            onPressed: mouse => slider.request(S.dragFraction(mouse.x, width, slider.min))
            onPositionChanged: mouse => {
                if (pressed)
                    slider.request(S.dragFraction(mouse.x, width, slider.min));
            }
            onReleased: slider.settled()
            onCanceled: slider.settled()
            onWheel: wheel => slider.request(S.wheelFraction(slider.value, wheel.angleDelta.y, slider.spec.wheelStep, slider.min))
        }

        Text {
            id: valueLabel

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: slider.spec.valueW
            horizontalAlignment: Text.AlignRight
            text: slider.valueText
            color: Theme.fgMuted
            font.family: Theme.fonts.mono
            font.pixelSize: slider.spec.valueFont
        }
    }

    // A round toggle with its label underneath; accent while checked.
    component RoundToggle: Column {
        id: toggle

        property string icon
        property string label
        property bool checked: false
        signal clicked

        readonly property var spec: Theme.layout.control

        spacing: toggle.spec.toggleGap

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: toggle.spec.toggle
            height: toggle.spec.toggle
            radius: toggle.spec.toggle / 2
            color: toggle.checked ? Theme.accent : Theme.tile

            MouseArea {
                anchors.fill: parent
                onClicked: toggle.clicked()
            }

            Components.Icon {
                anchors.centerIn: parent
                name: toggle.icon
                color: toggle.checked ? Theme.onAccent : Theme.fg
                size: toggle.spec.toggleIcon
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: toggle.label
            color: Theme.fgMuted
            font.family: Theme.fonts.ui
            font.pixelSize: toggle.spec.toggleLabelFont
        }
    }

    // Top-aligned: a Column packs from the top and the island stays 440 tall whatever is hidden.
    Column {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: root.spec.pad
        anchors.topMargin: root.spec.pad
        width: root.innerW
        spacing: root.spec.gap

        Item {
            width: parent.width
            height: clock.implicitHeight + root.spec.headPadTop + root.spec.headPadBottom

            Text {
                id: clock

                anchors.left: parent.left
                anchors.leftMargin: root.spec.headPadX
                anchors.bottom: parent.bottom
                anchors.bottomMargin: root.spec.headPadBottom
                text: Time.timeStr
                color: Theme.fg
                font.family: Theme.fonts.mono
                font.pixelSize: root.spec.clockFont
                font.weight: Font.DemiBold
                font.letterSpacing: root.spec.clockLetterEm * root.spec.clockFont
            }

            Column {
                anchors.right: parent.right
                anchors.rightMargin: root.spec.headPadX
                anchors.bottom: parent.bottom
                anchors.bottomMargin: root.spec.headPadBottom
                spacing: root.spec.dateGap

                Text {
                    anchors.right: parent.right
                    text: Time.weekdayStr
                    color: Theme.fg
                    font.family: Theme.fonts.ui
                    font.pixelSize: root.spec.dateFont
                }

                Text {
                    anchors.right: parent.right
                    text: Time.dayMonthStr
                    color: Theme.fgMuted
                    font.family: Theme.fonts.ui
                    font.pixelSize: root.spec.dateFont
                }
            }
        }

        Row {
            // Two equal columns; a lone tile keeps its column. Both hidden: the row (and its gap) is gone.
            readonly property real cellW: (root.innerW - root.spec.gap) / 2

            visible: wifiTile.visible || btTile.visible
            spacing: root.spec.gap

            Tile {
                id: wifiTile

                width: parent.cellW
                visible: Network.available
                icon: "wifi"
                title: "Wi-Fi"
                sub: root.wifiOn ? (Network.activeWifi?.name ?? "Niepołączono") : "Wyłączone"
                checked: root.wifiOn
            }

            Tile {
                id: btTile

                width: parent.cellW
                visible: root.adapter !== null
                icon: "bluetooth"
                title: "Bluetooth"
                sub: root.adapter?.enabled ? (root.btDevice?.name ?? "Włączony") : "Wyłączony"
                checked: root.adapter?.enabled ?? false
            }
        }

        Rectangle {
            width: parent.width
            height: sliders.implicitHeight + 2 * root.spec.cardPadY
            radius: Theme.radii.tile
            color: Theme.tile

            Column {
                id: sliders

                x: root.spec.cardPadX
                y: root.spec.cardPadY
                width: parent.width - 2 * root.spec.cardPadX
                spacing: root.spec.cardGap

                SliderRow {
                    width: parent.width
                    icon: Audio.muted ? "volume-x" : "volume-1"
                    fraction: Audio.muted ? 0 : Audio.volume
                    value: Audio.volume
                    valueText: Audio.muted ? "—" : root.percent(Audio.volume)
                    onMoved: f => root.perform("set the volume to " + root.percent(f) + "%", () => Audio.setVolume(f))
                }

                SliderRow {
                    width: parent.width
                    visible: Brightness.available
                    icon: "sun"
                    fraction: Brightness.value
                    value: root.brightnessBase
                    min: root.spec.brightnessMin
                    valueText: root.percent(Brightness.value)
                    animated: false
                    onMoved: f => root.requestBrightness(f)
                    onSettled: root.flushBrightness()
                }
            }
        }

        Item {
            width: parent.width
            height: toggles.height + 2 * root.spec.togglePadY

            Row {
                id: toggles

                readonly property real cellW: (parent.width - (root.spec.toggleCols - 1) * root.spec.gap) / root.spec.toggleCols

                anchors.centerIn: parent
                spacing: root.spec.gap

                RoundToggle {
                    width: toggles.cellW
                    icon: "moon"
                    label: "Skupienie"
                    checked: Notifs.dnd
                    onClicked: root.perform("switch Do Not Disturb " + (Notifs.dnd ? "off" : "on"), () => Notifs.dnd = !Notifs.dnd)
                }

                RoundToggle {
                    width: toggles.cellW
                    icon: "sun-moon"
                    label: "Motyw"
                    checked: !root.darkMode
                    onClicked: root.perform("switch the theme to " + (root.darkMode ? "light" : "dark"), () => Theme.setMode(root.darkMode ? "light" : "dark"))
                }

                RoundToggle {
                    width: toggles.cellW
                    icon: "power"
                    label: "Zasilanie"
                    onClicked: IslandState.request("power")
                }
            }
        }

        Components.MiniPlayer {
            width: parent.width
            visible: Players.hasPlayer
            player: Players.active
        }
    }
}
