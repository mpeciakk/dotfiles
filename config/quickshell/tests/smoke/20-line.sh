# Line mode: `hide` collapses every screen's island to the line (reference 2.6). A real fullscreen window
# may already put an output in the line, so lineOn is asserted relative to the baseline read first.
BASE="$(qs ipc -p "$DIR" prop get island lineOn 2>&1)"
OUTPUTS="$(niri msg -j outputs | python3 -I -c 'import json,sys; print(",".join(sorted(json.load(sys.stdin))))')"
call island hide
wait_ms 700
expect island hidden true
expect island lineOn "$OUTPUTS"
shot line
call island hide
wait_ms 700
expect island hidden false
# niri's screenshot notification shows as a toast on the focused output, and a toast is not the line.
call island close
wait_ms 700
expect island lineOn "$BASE"
