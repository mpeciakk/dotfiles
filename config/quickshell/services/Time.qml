pragma Singleton

import QtQuick
import Quickshell

// Current time as "hh:mm". Ticks per minute (see precision) — that's all the bar
// displays, so there's no reason to wake up every second.
Singleton {
    readonly property string timeStr: Qt.formatDateTime(clock.date, "hh:mm")

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }
}
