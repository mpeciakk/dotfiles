import QtQuick
import "../services"

// A single icon glyph from the Nerd Font, rendered as text so it's coloured
// directly (no recolouring/effects needed — crisp and visible on the dark bar).
// Set `text` to a glyph, e.g. `String.fromCodePoint(0xf0582)`, and `size`.
Text {
    property int size: 18

    color: Colours.text
    font.family: "JetBrainsMono Nerd Font Mono"   // Mono = single-cell, centred glyphs
    font.pixelSize: size
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
