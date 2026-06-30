#!/usr/bin/env bash
# Clipboard history for the quickshell launcher menu (backed by cliphist).
# Output: one tab-separated line per item:
#     <active 1|0>\t<label>\t<sublabel>\t<command>
# Selecting an item decodes that entry by id, puts it back on the clipboard, and
# closes the launcher (the wl-paste --watch cliphist store daemon then re-stores
# it at the top). Depends only on cliphist + wl-clipboard + coreutils.
set -o pipefail

emit() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4"; }

# cliphist list prints "<id>\t<preview>" newest-first. Restore by piping just the
# numeric id to `cliphist decode` (it reads the leading id), then to wl-copy.
cliphist list | while IFS=$'\t' read -r id preview; do
    [[ -z "$id" ]] && continue
    label=${preview//$'\t'/ }   # guard against stray tabs in the preview
    emit 0 "$label" "Clipboard" "printf %s ${id} | cliphist decode | wl-copy; qs ipc call launcher close"
done
