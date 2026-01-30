pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property color base: "#aa1e1e2e"
    readonly property color base_solid: "#1e1e2e"
    readonly property color surface: "#aa313244"
    readonly property color surface_solid: "#313244"
    readonly property color text: "#cdd6f4"
    readonly property color accent: "#89b4fa"
    readonly property color accent_variant: "#5589b4fa"
    readonly property color urgent: "#f38ba8"

    readonly property int radius_inner: 6
    readonly property int radius_outer: 12

    readonly property string font_family: "JetBrainsMono Nerd Font"

    readonly property font font: Qt.font({
        family: font_family,
        pointSize: 11
    })

    readonly property font font_small: Qt.font({
        family: font_family,
        pointSize: 10
    })

    readonly property font font_bold: Qt.font({
        family: font_family,
        pointSize: 11,
        bold: true
    })

    readonly property int padding: 8

    readonly property var icons: {
        "firefox": "󰈹",
        "youtube": ""
    }
}
