# The lock screen, WITHOUT locking: never calls `island lock` (it would lock the live session). The running test
# instance only proves the recovery hatch is there and harmless: `island unlock` while nothing is locked changes
# nothing. Then the card is shown in an ordinary window (LockPreview.qml) for one shot.
PREVIEW="$DIR/LockPreview.qml"
expect island locked false
call island unlock
expect island locked false

# smoke.sh's EXIT trap kills only $DIR: chain the preview's kill in front of it, so a failing or interrupted
# step never leaves the preview window up.
PREV_EXIT="$(trap -p EXIT)"; PREV_EXIT="${PREV_EXIT#trap -- \'}"; PREV_EXIT="${PREV_EXIT%\' EXIT}"
trap "qs kill -p \"\$PREVIEW\" >/dev/null 2>&1; $PREV_EXIT" EXIT

qs kill -p "$DIR" >/dev/null 2>&1
qs -p "$PREVIEW" -d >/dev/null 2>&1
sleep 2
# smoke.sh reads only $DIR's log: the preview's load errors and warnings are checked here.
PREVIEW_BAD="$(qs log -p "$PREVIEW" 2>&1 | grep -E '\b(WARN|ERROR|FATAL|CRIT)' | grep -v -E -f <(grep -v -E '^\s*(#|$)' "$DIR/tests/smoke/allowed-warnings.txt") || true)"
if [ -n "$PREVIEW_BAD" ]; then echo "FAIL: preview logged:"; echo "$PREVIEW_BAD"; FAILED=1; else echo "ok: preview loaded cleanly"; fi
shot lock-preview
qs kill -p "$PREVIEW" >/dev/null 2>&1
