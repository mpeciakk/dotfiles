pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

// Network state from Quickshell's native NetworkManager binding. Drives the bar
// indicator and the Wi-Fi management drawer (NetworkMenu). `available` is false
// — and the bar widget hidden — when the backend isn't NetworkManager.
Singleton {
    id: root

    readonly property bool available: Networking.backend === NetworkBackendType.NetworkManager

    readonly property var wifiDevice: (Networking.devices?.values ?? []).find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDevice: (Networking.devices?.values ?? []).find(d => d.type === DeviceType.Wired) ?? null

    readonly property bool wiredConnected: root.wiredDevice?.connected ?? false
    readonly property bool wifiConnected: root.wifiDevice?.connected ?? false
    readonly property bool connected: root.wiredConnected || root.wifiConnected
    readonly property string type: root.wiredConnected ? "ethernet" : root.wifiConnected ? "wifi" : ""

    // The Wi-Fi network currently connected (name/signal for the bar tooltip).
    readonly property var activeWifi: root.wifiDevice ? ((root.wifiDevice.networks?.values ?? []).find(n => n.connected) ?? null) : null
    readonly property string name: root.type === "ethernet" ? (root.wiredDevice?.network?.name ?? "Wired") : (root.activeWifi?.name ?? "")

    // Nerd Font glyph for the current link state (bar widget).
    function glyph(): string {
        if (root.type === "ethernet")
            return String.fromCodePoint(0xf0200);   // ethernet
        if (root.connected)
            return String.fromCodePoint(0xf05a9);   // wifi
        return String.fromCodePoint(0xf05aa);        // wifi-off
    }
}
