pragma Singleton

import QtQuick
import Quickshell

// Registry of launcher "action menus". Each menu is backed by a script in
// ../menus/ whose `list` subcommand prints one tab-separated line per item:
//     <active 1|0>\t<label>\t<sublabel>\t<command>
// The launcher renders the items (with the menu's icon + an active dot) and runs
// `command` (via sh -c) on select, then re-runs `list` to refresh the state.
// Add a menu: drop a script in ../menus/ and add an entry here.
Singleton {
    id: root

    // Absolute path of the menus directory, resolved from this file's location.
    readonly property string dir: Qt.resolvedUrl("../menus/").toString().replace(/^file:\/\//, "")

    readonly property var list: [
        {
            id: "vpn",
            title: "VPN",
            icon: "network-vpn",
            argv: ["bash", root.dir + "vpn.sh", "list"]
        },
        {
            id: "clipboard",
            title: "Clipboard",
            icon: "edit-paste",
            argv: ["bash", root.dir + "cliphist.sh", "list"]
        }
    ]

    function get(id: string): var {
        return root.list.find(m => m.id === id) ?? null;
    }
}
