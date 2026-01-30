import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import ".."
import "../services"
import "../common"

Popup {
    width: 650
    height: 83 + 16

    Tabs {
        id: settingsTabs
        Layout.fillWidth: true
        tabsModel: [
            {
                icon: "cloud",
                label: "Weather"
            },
            {
                icon: "settings",
                label: "System"
            },
            {
                icon: "wallpaper",
                label: "Wallpaper"
            }
        ]
    }
}
