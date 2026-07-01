pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Laptop battery state for the bar indicator. `available` is false when there's
// no battery (desktops), so the bar widget hides. `percentage` is 0..1 (UPower
// convention — verified against /sys capacity).
Singleton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool available: root.device?.isLaptopBattery ?? false
    readonly property real percentage: root.device?.percentage ?? 0
    readonly property bool charging: root.device
        ? (root.device.state === UPowerDeviceState.Charging || root.device.state === UPowerDeviceState.PendingCharge)
        : false
    readonly property bool full: root.device ? root.device.state === UPowerDeviceState.FullyCharged : false
    readonly property bool low: root.available && !root.charging && !root.full && root.percentage <= 0.2

    // Nerd Font battery glyph for the current level/charge state.
    function glyph(): string {
        if (root.charging)
            return String.fromCodePoint(0xf0084);    // battery-charging
        if (root.percentage >= 0.95 || root.full)
            return String.fromCodePoint(0xf0079);    // battery (full)
        const level = Math.max(1, Math.round(root.percentage * 10));   // 1..9
        return String.fromCodePoint(0xf007a + (level - 1));            // battery-10 .. battery-90
    }
}
