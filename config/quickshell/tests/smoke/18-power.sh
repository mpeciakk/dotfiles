# The power menu: opens at its fixed 540x180 over a dimmed screen. Never presses a button (no pointer
# injection here, and a button would suspend, log out, reboot or power off the machine): only the state is
# opened and closed, and the shot shows the five buttons, the danger one and no hold ring at rest.
call island open power
wait_ms 700
expect island current power
call island close
wait_ms 500
expect island current rest
call island open power
wait_ms 700
shot power
