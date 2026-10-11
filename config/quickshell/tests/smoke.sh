#!/usr/bin/env bash
# Usage: tests/smoke.sh <check-file>
# Starts this config as its own quickshell instance in test mode, sources the
# check file (call / expect / wait_ms / shot, $DIR, $CFG), fails on any logged
# warning or error not listed in tests/smoke/allowed-warnings.txt, and always
# kills the instance.
set -uo pipefail
# A check file marked `# smoke: private-bus` runs on its own session bus, so the test instance owns
# org.freedesktop.Notifications and `notify-send` never reaches the live shell.
if grep -q '^# smoke: private-bus$' "$1" && [ -z "${WYSPA_PRIVATE_BUS:-}" ]; then
    exec env WYSPA_PRIVATE_BUS=1 dbus-run-session -- "$0" "$@"
fi
DIR="$(cd "$(dirname "$0")/.." && pwd)"
FAILED=0
export WYSPA_TEST=1 QSG_RENDER_LOOP=threaded
CFG="$(mktemp /tmp/wyspa-config.XXXXXX.json)"
cp "$DIR/tests/fixtures/config.json" "$CFG"
export WYSPA_CONFIG="$CFG"
trap 'qs kill -p "$DIR" >/dev/null 2>&1; rm -f "$CFG"' EXIT

call() { qs ipc -p "$DIR" call "$@" >/dev/null 2>&1 || { echo "FAIL: call $*"; FAILED=1; }; }
expect() {
    local got
    got="$(qs ipc -p "$DIR" prop get "$1" "$2" 2>&1)"
    if [ "$got" == "$3" ]; then echo "ok: $1.$2 = $3"; else echo "FAIL: $1.$2 expected '$3' got '$got'"; FAILED=1; fi
}
wait_ms() { sleep "$(awk "BEGIN{print $1/1000}")"; }
shot() { "$DIR/tests/shot.sh" "$1" || FAILED=1; }

qs kill -p "$DIR" >/dev/null 2>&1
qs -p "$DIR" -d >/dev/null 2>&1
sleep 2
# shellcheck source=/dev/null
source "$1"
LOG="$(qs log -p "$DIR" 2>&1)"
BAD="$(printf '%s\n' "$LOG" | grep -E '\b(WARN|ERROR|FATAL|CRIT)' | grep -v -E -f <(grep -v -E '^\s*(#|$)' "$DIR/tests/smoke/allowed-warnings.txt") || true)"
if [ -n "$BAD" ]; then echo "FAIL: instance logged:"; echo "$BAD"; FAILED=1; fi
exit $FAILED
