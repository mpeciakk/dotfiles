#!/usr/bin/env bash
active=()

# WireGuard
for iface in $(wg show interfaces 2>/dev/null); do
    active+=("WG: $iface")
done

# OpenVPN (systemd)
while read -r unit _; do
    [[ -z "$unit" ]] && continue
    name="${unit#openvpn-client@}"; name="${name%.service}"
    active+=("OVPN: $name")
done < <(systemctl list-units --type=service --state=active --no-legend 'openvpn-client@*.service' 2>/dev/null)

# Tailscale
ts_json=$(tailscale status --json 2>/dev/null || echo '{}')
if echo "$ts_json" | jq -e '.BackendState=="Running"' >/dev/null; then
    profile=$(echo "$ts_json" | jq -r '.CurrentTailnet.Name // .User[(.Self.UserID|tostring)].LoginName // "tailnet"' | cut -d@ -f1)
    active+=("TS: $profile")
fi

# ZeroTier
while read -r line; do
    active+=("ZT: $line")
done < <(zerotier-cli -j listnetworks 2>/dev/null | jq -r '.[] | select(.status=="OK") | "\(.name // .nwid)"')

count=${#active[@]}
if (( count == 0 )); then
    jq -cn '{text:"󰦝", tooltip:"VPN: brak", class:"off", alt:"off"}'
else
    tooltip=$(printf '%s\n' "${active[@]}")
    jq -cn --arg t "󰒘 $count" --arg tt "$tooltip" \
        '{text:$t, tooltip:$tt, class:"on", alt:"on"}'
fi
