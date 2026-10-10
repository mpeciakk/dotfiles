# Line mode: `hide` collapses every screen's island to the line (reference 2.6). Test mode switches the real
# fullscreen detection off (services/Fullscreen.qml), so a fullscreen window on this machine must not put an
# output in the line: the line is driven by the IPC alone and lineOn is empty before and after.
# maskMode is the input mask: `line` (only the hover zone) in line mode, `shape`, `full` in a modal state.
OUTPUTS="$(niri msg -j outputs | python3 -I -c 'import json,sys; print(",".join(sorted(json.load(sys.stdin))))')"
expect island lineOn ""
# The reported mask follows the output the island was last opened on, so open (and close) it once first.
call island open launcher
wait_ms 700
expect island maskMode full
call island close
wait_ms 700
expect island maskMode shape
call island hide
wait_ms 700
expect island hidden true
expect island lineOn "$OUTPUTS"
expect island maskMode line
call island hide
wait_ms 700
expect island hidden false
expect island lineOn ""
expect island maskMode shape
# A modal state takes the whole surface even while the line is requested, and the line mask comes back after it.
call island hide
call island open launcher
wait_ms 700
expect island maskMode full
call island close
wait_ms 700
expect island lineOn "$OUTPUTS"
expect island maskMode line
# Last: niri's screenshot notification shows as a toast in this instance, and a toast is not the line.
shot line
