pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "lib/theme.js" as T

Singleton {
    id: root

    property var host: ({})
    // The FileView loads asynchronously: until it has answered, `host` is not the config yet.
    property bool hostLoaded: false
    property string modeOverride: ""
    property string levelOverride: ""
    property string autoMode: ""
    property bool legibilityBoost: false
    // Set by Lock.qml for a lock that cannot wait for the way in (a pending sleep, DESIGN W14): everything animated
    // takes the reduced-motion path until the session is locked.
    property bool lockInstant: false

    readonly property var tokens: T.merge(T.defaults, root.host.island ?? null)
    readonly property string mode: root.modeOverride || root.autoMode || root.tokens.mode
    readonly property string glassLevel: root.levelOverride || root.tokens.glassLevel
    readonly property bool glass: root.tokens.glass
    readonly property bool reducedMotion: root.tokens.reducedMotion || root.lockInstant
    readonly property var c: T.resolve(root.tokens, root.mode, root.glassLevel, root.glass)
    readonly property var geom: root.tokens.geom
    readonly property var motion: root.tokens.motion
    readonly property var radii: root.tokens.radii
    readonly property var sizes: root.tokens.sizes
    readonly property var fonts: root.tokens.fonts
    readonly property var layout: root.tokens.layout
    readonly property var appColors: root.c.appColors
    readonly property var lockWallpaper: root.c.lockWallpaper
    readonly property string wallpaper: {
        if (!root.hostLoaded)
            return "";
        const p = T.wallpaperFor(root.host.wallpaper ?? "~/.config/dotfiles/wp2.jpg", root.mode);
        return p.startsWith("~") ? Quickshell.env("HOME") + p.slice(1) : p;
    }

    // The notch of `output` ({ w, h }, logical px) from the host config's top-level `notch`, or null.
    function notchFor(output: string): var {
        return T.notchFor(root.host.notch, output);
    }

    function setMode(m: string): void {
        root.modeOverride = m;
    }

    function setGlassLevel(l: string): void {
        root.levelOverride = l;
    }

    // One animated colour per resolved colour key: a theme or level change crossfades.
    // Over a wallpaper that fights its text the island gets denser (set by AutoTheme); the boost feeds the one mirror.
    property color islandBg: root.legibilityBoost
        ? T.raiseAlpha(root.c.islandBg, root.mode === "light" ? root.tokens.legibility.lightBoost : root.tokens.legibility.boost)
        : root.c.islandBg
    Behavior on islandBg { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color ring: root.c.ring
    Behavior on ring { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color shadowColor: root.c.shadowColor
    Behavior on shadowColor { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color lockShadowColor: root.c.lockShadowColor
    Behavior on lockShadowColor { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color tile: root.c.tile
    Behavior on tile { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color sel: root.c.sel
    Behavior on sel { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color hover: root.c.hover
    Behavior on hover { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color card: root.c.card
    Behavior on card { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color chip: root.c.chip
    Behavior on chip { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color track: root.c.track
    Behavior on track { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color sliderFill: root.c.sliderFill
    Behavior on sliderFill { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color fg: root.c.fg
    Behavior on fg { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color fgMuted: root.c.fgMuted
    Behavior on fgMuted { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color fgDim: root.c.fgDim
    Behavior on fgDim { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color fgSoft: root.c.fgSoft
    Behavior on fgSoft { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color fgLock: root.c.fgLock
    Behavior on fgLock { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color accent: root.c.accent
    Behavior on accent { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color accentSoft: root.c.accentSoft
    Behavior on accentSoft { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color accentHalo: root.c.accentHalo
    Behavior on accentHalo { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color focusRing: root.c.focusRing
    Behavior on focusRing { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    // The `onAccent` token as `accentFg`: a property named on<Capital> is parsed as a signal handler
    // (its binding never runs, it read black) and `Behavior on onAccent` segfaults.
    property color accentFg: root.c.onAccent
    Behavior on accentFg { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color inverseBg: root.c.inverseBg
    Behavior on inverseBg { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color inverseFg: root.c.inverseFg
    Behavior on inverseFg { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color danger: root.c.danger
    Behavior on danger { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color dotInactive: root.c.dotInactive
    Behavior on dotInactive { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color line: root.c.line
    Behavior on line { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color divider: root.c.divider
    Behavior on divider { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color scrimDim: root.c.scrimDim
    Behavior on scrimDim { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color lockField: root.c.lockField
    Behavior on lockField { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color lockFieldRing: root.c.lockFieldRing
    Behavior on lockFieldRing { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }
    property color lockGlass: root.c.lockGlass
    Behavior on lockGlass { ColorAnimation { duration: root.motion.themeFadeMs; easing.type: Easing.InOutQuad } }

    readonly property real shadowY: root.c.shadowY
    readonly property real shadowBlur: root.c.shadowBlur
    readonly property real shadowPad: root.c.shadowPad
    readonly property real lockShadowY: root.c.lockShadowY
    readonly property real lockShadowBlur: root.c.lockShadowBlur

    FileView {
        path: Quickshell.env("WYSPA_CONFIG") || `${Quickshell.env("HOME")}/.config/dotfiles/config.json`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.host = JSON.parse(text());
            } catch (e) {
                root.host = ({});
            }
            root.hostLoaded = true;
        }
        onLoadFailed: {
            root.host = ({});
            root.hostLoaded = true;
        }
    }

    IpcHandler {
        target: "theme"

        readonly property string mode: root.mode
        readonly property string level: root.glassLevel
        readonly property color fg: root.fg
        readonly property color islandBg: root.islandBg

        function setMode(m: string): void {
            root.setMode(m);
        }

        function setLevel(l: string): void {
            root.setGlassLevel(l);
        }
    }
}
