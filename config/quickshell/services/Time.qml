pragma Singleton

import QtQuick
import Quickshell

// Current time as "hh:mm". Ticks per minute (see precision) — that's all the bar
// displays, so there's no reason to wake up every second.
Singleton {
    readonly property string timeStr: Qt.formatDateTime(clock.date, "hh:mm")
    readonly property string dateStr: Qt.formatDateTime(clock.date, "dddd, MMMM d, yyyy")

    // The panel header's date, in Polish whatever the session locale ("sobota", "10 października").
    readonly property string weekdayStr: clock.date.toLocaleString(Qt.locale("pl_PL"), "dddd")
    readonly property string dayMonthStr: clock.date.toLocaleString(Qt.locale("pl_PL"), "d MMMM")

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }
}
