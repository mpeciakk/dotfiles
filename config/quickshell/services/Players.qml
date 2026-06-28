pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The "active" MPRIS player: a currently-playing one if any, else the first
// available. Used by the Media widget (lock screen, and later a dashboard).
Singleton {
    id: root

    readonly property var all: Mpris.players ? Mpris.players.values.filter(p => p) : []
    readonly property MprisPlayer active: {
        const ps = root.all;
        return ps.find(p => p.isPlaying) ?? (ps.length > 0 ? ps[0] : null);
    }
    readonly property bool hasPlayer: root.active !== null
}
