# The media state: opens at its fixed 380x56. On a machine with no real track playing it shows the
# "Nic nie gra" placeholder; in test mode the player controls only log, never touch a player.
call island open media
wait_ms 700
expect island current media
shot media
call island close
