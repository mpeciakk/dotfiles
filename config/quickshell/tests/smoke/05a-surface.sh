expect island maskMode shape
shot surface-rest
call island open launcher
wait_ms 700
expect island maskMode full
shot surface-launcher
call island close
wait_ms 700
expect island maskMode shape
call island open toast
wait_ms 700
expect island maskMode shape
call island close
