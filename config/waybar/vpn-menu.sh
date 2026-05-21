#!/usr/bin/env bash
set -euo pipefail

entries=()

for cfg in /etc/openvpn/client/*.conf; do
    [[ -e "$cfg" ]] || continue
    n=$(basename "$cfg" .conf)
    systemctl is-active --quiet "openvpn-client@${n}" \
        && entries+=("● | OVPN | $n") || entries+=("○ | OVPN | $n")
done

ts_state=$(tailscale status --json 2>/dev/null | jq -r '.BackendState // "Stopped"')
current_profile=$(tailscale switch --list 2>/dev/null | awk '/\*/{print $1}')

while IFS= read -r line; do
    [[ "$line" =~ ^ID ]] && continue
    [[ -z "$line" ]] && continue

    id=$(awk '{print $1}' <<<"$line")
    name=$(awk '{print $2}' <<<"$line")
    
    # gwiazdka może być przy ID ("default*") lub jako osobne pole — sprawdź obie formy
    if [[ "$line" == *"*"* ]]; then
        # to jest aktywny profil
        # wytnij gwiazdkę z id jeśli przyklejona
        id="${id%\*}"
        # jeśli była osobnym polem, tailnet siedzi w kolumnie 3
        [[ "$name" == "*" ]] && name=$(awk '{print $3}' <<<"$line")
        is_current=yes
    else
        is_current=no
    fi

    if [[ "$is_current" == "yes" && "$ts_state" == "Running" ]]; then
        entries+=("● |  TS  | $name")
    else
        entries+=("○ |  TS  | $name")
    fi
done < <(tailscale switch --list 2>/dev/null | tail -n +2)

if ! tailscale switch --list &>/dev/null; then
    [[ "$ts_state" == "Running" ]] && entries+=("● |  TS  | default") \
                                   || entries+=("○ |  TS  | default")
fi

choice=$(printf '%s\n' "${entries[@]}" | fuzzel --dmenu --prompt='VPN > ')
[[ -z "$choice" ]] && exit 0

IFS='|' read -r state type name <<<"$choice"
# trim ewentualnych spacji
state="${state// /}"
type="${type// /}"
name="${name// /}"

case "$type" in
    OVPN)
        [[ "$state" == "●" ]] && doas /usr/local/bin/vpn-ctl ovpn-down "$name" \
                              || doas /usr/local/bin/vpn-ctl ovpn-up "$name"
        ;;
    TS)
        if [[ "$state" == "●" ]]; then
          tailscale down
        else
          current=$(tailscale switch --list 2>/dev/null | awk '/\*/{print $1}')
          if [[ "$current" != "$name" ]]; then
            tailscale switch "$name"
          fi
          tailscale up
        fi
        ;;
esac

pkill -RTMIN+8 waybar 2>/dev/null || true
