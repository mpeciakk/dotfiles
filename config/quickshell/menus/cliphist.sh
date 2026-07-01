#!/usr/bin/env bash
set -o pipefail

emit() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4"; }

cliphist list | while IFS=$'\t' read -r id preview; do
    [[ -z "$id" ]] && continue
    label=${preview//$'\t'/ }
    emit 0 "$label" "Clipboard" "printf %s ${id} | cliphist decode | wl-copy; qs ipc call launcher close"
done
