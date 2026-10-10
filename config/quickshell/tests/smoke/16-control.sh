# The control panel: opens at its fixed 520x440 and keeps that height whatever tiles/sliders the machine
# lacks. Light mode is the Theme IPC (not a panel click); in test mode the panel never touches real audio,
# backlight, player or radio state, so only the island state and the shots are checked.
call island open control
wait_ms 700
expect island current control
expect island targetW 520
expect island targetH 440
shot control-dark
call theme setMode light
wait_ms 800
expect theme mode light
shot control-light
call theme setMode dark
call island close
