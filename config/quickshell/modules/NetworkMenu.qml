import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../components"
import "../services"

// Wi-Fi + Bluetooth management, shown in a bar Drawer (opened from the network
// indicator). Lists known Wi-Fi networks (scanning only while open) and paired
// Bluetooth devices; click a row to connect/disconnect. Existing connections
// only — no joining new networks or pairing new devices.
Item {
    id: root

    property bool active: false              // drawer open → enable Wi-Fi scanning
    readonly property int menuWidth: 300

    implicitWidth: menuWidth
    implicitHeight: col.implicitHeight

    // Scan for in-range known networks only while the drawer is open.
    Binding {
        target: Network.wifiDevice
        property: "scannerEnabled"
        value: root.active
        when: Network.wifiDevice !== null
    }

    // Saved networks in range, strongest first.
    readonly property var wifiNets: Network.wifiDevice
        ? (Network.wifiDevice.networks?.values ?? []).filter(n => n.known).sort((a, b) => (b.signalStrength ?? 0) - (a.signalStrength ?? 0))
        : []

    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool btReady: root.btAdapter?.enabled ?? false
    readonly property var btDevices: (Bluetooth.devices?.values ?? []).filter(d => d.paired)

    Column {
        id: col

        width: parent.width
        spacing: 4

        // ── Wi-Fi ──
        Text {
            text: "Wi-Fi"
            color: Colours.subtext0
            font.pixelSize: Config.font.sm
            font.bold: true
            leftPadding: 8
            bottomPadding: 2
        }

        Text {
            width: parent.width
            visible: root.wifiNets.length === 0
            text: "No known networks"
            color: Colours.overlay1
            font.pixelSize: Config.font.sm
            leftPadding: 8
            topPadding: 4
            bottomPadding: 4
        }

        Repeater {
            model: root.wifiNets

            delegate: ListRow {
                required property var modelData

                width: col.width
                rowHeight: 40
                label: modelData.name
                sublabel: Math.round((modelData.signalStrength ?? 0) * 100) + "%"
                dot: modelData.connected ? 1 : 0

                onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
            }
        }

        // ── Bluetooth ──
        Text {
            visible: root.btReady
            text: "Bluetooth"
            color: Colours.subtext0
            font.pixelSize: Config.font.sm
            font.bold: true
            leftPadding: 8
            topPadding: 8
            bottomPadding: 2
        }

        Text {
            width: parent.width
            visible: root.btReady && root.btDevices.length === 0
            text: "No paired devices"
            color: Colours.overlay1
            font.pixelSize: Config.font.sm
            leftPadding: 8
            topPadding: 4
            bottomPadding: 4
        }

        Repeater {
            model: root.btReady ? root.btDevices : []

            delegate: ListRow {
                required property var modelData

                width: col.width
                rowHeight: 40
                label: modelData.name
                sublabel: modelData.connected ? "Connected" : "Disconnected"
                dot: modelData.connected ? 1 : 0

                onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
            }
        }
    }
}
