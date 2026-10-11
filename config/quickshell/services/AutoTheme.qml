pragma Singleton

import QtQuick
import Quickshell
import ".."
import "../lib/autotheme.js" as A

// Automatic theme mode (reference R34). For island.modeSource "sun" the mode follows sunrise/sunset at
// island.location (re-evaluated every minute; no location, or polar day/night, gives "" and Theme falls back
// to island.mode); for "wallpaper" it follows the mean luminance of the wallpaper, with hysteresis. Either way
// the result reaches Theme through autoMode; a manual `setMode` still wins there. Independently of the source,
// `boost` says the dark island sits over a bright patch of wallpaper and needs a denser background.
Singleton {
    id: root

    readonly property string wallpaperSource: Theme.wallpaper ? "file://" + Theme.wallpaper : ""

    readonly property var sun: A.sunTimes(clock.date, Theme.tokens.location.lat, Theme.tokens.location.lon)
    readonly property string sunMode: !root.sun ? "" : clock.date.getTime() >= root.sun.sunrise.getTime() && clock.date.getTime() < root.sun.sunset.getTime() ? "light" : "dark"
    property string wallpaperMode: ""

    readonly property string mode: Theme.tokens.modeSource === "sun" ? root.sunMode : Theme.tokens.modeSource === "wallpaper" ? root.wallpaperMode : ""

    // The island is centred at the top edge; the first screen stands for all of them.
    readonly property var screen: Quickshell.screens[0]
    // The wallpaper's native size, read once by the probe, and the wallpaper it belongs to.
    property size nativeSize: Qt.size(0, 0)
    property string sizedFor: ""
    readonly property bool sized: root.sizedFor === root.wallpaperSource
    readonly property var crop: root.sized && root.screen
        ? A.islandCrop(root.nativeSize.width, root.nativeSize.height, root.screen.width, root.screen.height, Theme.geom.rest.w, Theme.geom.rest.h)
        : null
    readonly property real regionLuminance: region.colors.length > 0 ? root.luminanceOf(region.colors[0]) : 0
    readonly property bool boost: Theme.mode === "dark" && root.regionLuminance > Theme.tokens.legibility.threshold

    function luminanceOf(c: color): real {
        return A.luminance(c.r * 255, c.g * 255, c.b * 255);
    }

    Binding {
        target: Theme
        property: "autoMode"
        value: root.mode
    }

    Binding {
        target: Theme
        property: "legibilityBoost"
        value: root.boost
    }

    SystemClock {
        id: clock

        enabled: Theme.tokens.modeSource === "sun"
        precision: SystemClock.Minutes
    }

    // depth 0 averages the whole image into one colour.
    ColorQuantizer {
        source: Theme.tokens.modeSource === "wallpaper" ? root.wallpaperSource : ""
        depth: 0
        rescaleSize: Theme.tokens.legibility.sampleSize

        onColorsChanged: {
            if (colors.length > 0)
                root.wallpaperMode = A.nextMode(root.wallpaperMode, root.luminanceOf(colors[0]), Theme.tokens.wallpaperLight, Theme.tokens.wallpaperDark);
        }
    }

    // Only to learn the wallpaper's native size, which the crop under the island is measured in. The size is
    // stored on Ready and the source cleared, so the decoded bitmap is released at once.
    Image {
        id: probe

        source: root.sized ? "" : root.wallpaperSource
        asynchronous: true
        visible: false

        onStatusChanged: {
            if (probe.status === Image.Ready) {
                root.nativeSize = probe.sourceSize;
                root.sizedFor = root.wallpaperSource;
            }
        }
    }

    ColorQuantizer {
        id: region

        source: root.crop ? root.wallpaperSource : ""
        imageRect: root.crop ? Qt.rect(root.crop.x, root.crop.y, root.crop.width, root.crop.height) : Qt.rect(0, 0, 0, 0)
        depth: 0
        rescaleSize: Theme.tokens.legibility.sampleSize
    }
}
