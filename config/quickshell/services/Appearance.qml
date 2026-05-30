pragma Singleton

import QtQuick
import Quickshell

// Motion tokens, mirroring caelestia's Material 3 "expressive" curves and
// durations but kept self-contained (no Caelestia.Config dependency). Bezier
// arrays are flat control-point lists for Easing.BezierSpline; spatial curves
// overshoot (control y > 1) for a springy feel.
Singleton {
    readonly property QtObject anim: QtObject {
        readonly property QtObject durations: QtObject {
            readonly property int small: 200
            readonly property int normal: 400
            readonly property int large: 600
            readonly property int expressiveFastSpatial: 350
            readonly property int expressiveDefaultSpatial: 500
            readonly property int expressiveSlowSpatial: 650
            readonly property int expressiveFastEffects: 150
            readonly property int expressiveDefaultEffects: 200
            readonly property int expressiveSlowEffects: 300
        }

        readonly property QtObject curves: QtObject {
            readonly property var standard: [0.2, 0, 0, 1, 1, 1]
            readonly property var emphasized: [0.05, 0, 0.133333, 0.06, 0.166667, 0.4, 0.208333, 0.82, 0.25, 1, 1, 1]
            readonly property var expressiveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1]
            readonly property var expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
            readonly property var expressiveSlowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1]
            readonly property var expressiveDefaultEffects: [0.34, 0.8, 0.34, 1, 1, 1]
            readonly property var expressiveSlowEffects: [0.34, 0.88, 0.34, 1, 1, 1]
        }
    }
}
