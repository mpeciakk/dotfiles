#!/usr/bin/env bash
# Lists VPN endpoints (OpenVPN + Tailscale) for the quickshell launcher menu.
# Output: one tab-separated line per item:
#     <active 1|0>\t<label>\t<sublabel>\t<command>
# `command` is a shell snippet the launcher runs (via sh -c) to toggle that
# endpoint; the launcher re-runs `list` afterwards so the active state refreshes.
# Deliberately depends only on coreutils/awk/grep/sed (no jq).
set -o pipefail

emit() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4"; }

# --- OpenVPN client instances (systemd) ---
# /etc/openvpn/client is root-only, so a user-run glob can't list configs and a
# stopped instance gets unloaded (vanishes from `systemctl list-units`). So keep
# an explicit list of OpenVPN config names here, and union it with whatever is
# currently loaded. State for each comes from `systemctl is-active`.
OVPN_NAMES=(animativ)

while read -r unit; do
    n="${unit#openvpn-client@}"
    n="${n%.service}"
    [[ -n "$n" ]] && OVPN_NAMES+=("$n")
done < <(systemctl list-units --all --type=service --no-legend --plain 'openvpn-client@*.service' 2>/dev/null | awk '{print $1}' | grep -E '^openvpn-client@.+\.service$')

while IFS= read -r n; do
    [[ -z "$n" ]] && continue
    if systemctl is-active --quiet "openvpn-client@${n}"; then
        emit 1 "$n" "OpenVPN" "doas /usr/local/bin/vpn-ctl ovpn-down '$n'"
    else
        emit 0 "$n" "OpenVPN" "doas /usr/local/bin/vpn-ctl ovpn-up '$n'"
    fi
done < <(printf '%s\n' "${OVPN_NAMES[@]}" | sort -u)

# --- Tailscale profiles ---
ts_state=$(tailscale status --json 2>/dev/null | grep -m1 '"BackendState"' | sed 's/.*: *"\([^"]*\)".*/\1/')
ts_state=${ts_state:-Stopped}

if tailscale switch --list &>/dev/null; then
    while IFS= read -r line; do
        [[ "$line" =~ ^ID ]] && continue
        [[ -z "$line" ]] && continue
        id=$(awk '{print $1}' <<<"$line")
        name=$(awk '{print $2}' <<<"$line")
        if [[ "$line" == *"*"* ]]; then
            id="${id%\*}"
            [[ "$name" == "*" ]] && name=$(awk '{print $3}' <<<"$line")
            is_current=yes
        else
            is_current=no
        fi
        if [[ "$is_current" == "yes" && "$ts_state" == "Running" ]]; then
            emit 1 "$name" "Tailscale" "tailscale down"
        else
            emit 0 "$name" "Tailscale" "tailscale switch '$id' 2>/dev/null; tailscale up"
        fi
    done < <(tailscale switch --list 2>/dev/null | tail -n +2)
elif command -v tailscale &>/dev/null; then
    if [[ "$ts_state" == "Running" ]]; then
        emit 1 "default" "Tailscale" "tailscale down"
    else
        emit 0 "default" "Tailscale" "tailscale up"
    fi
fi
