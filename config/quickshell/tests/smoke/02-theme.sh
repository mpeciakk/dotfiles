expect theme mode dark
expect theme level ciekłe
expect theme fg "#ffeceaf2"
call theme setMode light
wait_ms 120
MID="$(qs ipc -p "$DIR" prop get theme fg)"
if [ "$MID" == "#ffeceaf2" ] || [ "$MID" == "#ff1e1b2a" ]; then echo "FAIL: fg did not crossfade (got $MID at 120 ms)"; FAILED=1; else echo "ok: crossfade mid value $MID"; fi
wait_ms 700
expect theme fg "#ff1e1b2a"
expect theme mode light
call theme setLevel mocne
expect theme level mocne
