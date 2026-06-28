#!/usr/bin/env bash
# Lists VPN endpoints (OpenVPN + Tailscale) for the quickshell launcher menu.
# Output: one tab-separated line per item:
#     <active 1|0>\t<label>\t<sublabel>\t<command>
# `command` is a shell snippet the launcher runs (via sh -c) to toggle that
# endpoint; the launcher re-runs `list` afterwards so the active state refreshes.
# Deliberately depends only on coreutils/awk/grep/sed (no jq).
set -o pipefail

# --- shared config (single source of truth, host-agnostic) ---
# Read VPN settings from ~/.config/dotfiles/config.json so the same script runs
# unchanged on every host. Parsed with sed/grep (the file format is ours and
# stable) to keep this dependency-free. Falls back to safe defaults if absent.
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/config.json"

cfg_str() {  # cfg_str <key> <default> — first "key": "value" string in CONFIG
    local v=""
    [[ -r "$CONFIG" ]] && v=$(sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$CONFIG" | head -1)
    printf '%s' "${v:-$2}"
}

PRIVILEGED=$(cfg_str privileged doas)            # e.g. doas / sudo
VPN_CTL=$(cfg_str vpnCtl /usr/local/bin/vpn-ctl) # privileged OpenVPN helper

emit() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4"; }

# --- OpenVPN client instances (systemd) ---
# /etc/openvpn/client is root-only, so a user-run glob can't list configs and a
# stopped instance gets unloaded (vanishes from `systemctl list-units`). So read
# the explicit list of OpenVPN config names from config.json (vpn.openvpn[]) and
# union it with whatever is currently loaded. State comes from `systemctl is-active`.
OVPN_NAMES=()
if [[ -r "$CONFIG" ]]; then
    # Flatten newlines so the openvpn array is matched whether it's on one line
    # or several, then pull the quoted names from inside the [ ... ] brackets.
    while IFS= read -r n; do
        [[ -n "$n" ]] && OVPN_NAMES+=("$n")
    done < <(tr -d '\n' < "$CONFIG" \
                | grep -oE '"openvpn"[[:space:]]*:[[:space:]]*\[[^]]*\]' \
                | grep -oE '\[[^]]*\]' | grep -oE '"[^"]+"' | sed 's/"//g')
fi

while read -r unit; do
    n="${unit#openvpn-client@}"
    n="${n%.service}"
    [[ -n "$n" ]] && OVPN_NAMES+=("$n")
done < <(systemctl list-units --all --type=service --no-legend --plain 'openvpn-client@*.service' 2>/dev/null | awk '{print $1}' | grep -E '^openvpn-client@.+\.service$')

while IFS= read -r n; do
    [[ -z "$n" ]] && continue
    if systemctl is-active --quiet "openvpn-client@${n}"; then
        emit 1 "$n" "OpenVPN" "$PRIVILEGED $VPN_CTL ovpn-down '$n'"
    else
        emit 0 "$n" "OpenVPN" "$PRIVILEGED $VPN_CTL ovpn-up '$n'"
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
