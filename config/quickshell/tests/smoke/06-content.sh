expect island contentState rest
call island open launcher
expect island contentState ""
wait_ms 600
expect island contentState launcher
call island close
wait_ms 600
expect island contentState rest
