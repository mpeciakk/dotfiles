# The control panel: 520 wide and as tall as its content, which depends on the tiles/sliders/player the machine
# has; two notifications add the compact section below it (DESIGN W20: gap 10 + pad 20 + head 22 + 2 x 34 = 120).
# Light mode is the Theme IPC (not a panel click); in test mode the panel never touches real audio,
# backlight, player or radio state, so only the island state and the shots are checked.
call island open control
wait_ms 700
expect island current control
expect island targetW 520
H="$(qs ipc -p "$DIR" prop get island targetH 2>&1)"
call notifs inject Slack "Nowa wiadomość" "Hej"
call notifs inject Mail "Faktura za październik" "PDF w załączniku"
wait_ms 700
expect island current control
expect island targetH "$((H + 120))"
call theme setMode light
wait_ms 800
expect theme mode light
call theme setMode dark
wait_ms 800
expect theme mode dark
shot control-dark
call theme setMode light
wait_ms 800
shot control-light
