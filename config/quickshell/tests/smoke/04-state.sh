expect island current rest
expect island targetW 200
call island open launcher
expect island current launcher
expect island targetW 680
expect island targetH 356
call island open toast
expect island current launcher
call island close
expect island current rest
call island open osd
expect island current osd
wait_ms 1000
call island open osd
wait_ms 1000
expect island current osd
wait_ms 800
expect island current rest
call island toggle control
expect island current control
call island toggle control
expect island current rest
call island open bogus
expect island current rest
call island open toString
expect island current rest
call island toggle constructor
expect island current rest
call island hide
expect island hidden true
call island hide
expect island hidden false
