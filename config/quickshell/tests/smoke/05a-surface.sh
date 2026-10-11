expect island maskMode shape
call island open launcher
wait_ms 700
expect island maskMode full
call island close
wait_ms 700
expect island maskMode shape
call island open toast
wait_ms 700
expect island maskMode shape
call island close
wait_ms 700
shot surface-rest
call island open launcher
wait_ms 700
shot surface-launcher
