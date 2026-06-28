# dotfiles

Personal Arch Linux dotfiles for a [niri](https://github.com/YaLTeR/niri) (Wayland,
scrollable-tiling) session with a custom [QuickShell](https://quickshell.org)
desktop shell, managed with [dotter](https://github.com/SuperCuber/dotter).

## What's here

| Path | What |
|------|------|
| `config/niri/` | niri compositor (split into `input/output/layout/workspace/window_rules/bindings`) |
| `config/quickshell/` | the desktop shell (bar, launcher, lock, notifications, …) — see its own `CLAUDE.md` |
| `config/dotfiles/config.json` | **shared runtime config** read by the shell (wallpaper, VPN, lock) + wallpapers |
| `config/nushell/` | nushell (login shell) split into `config/aliases/completions/init` |
| `config/uwsm/env` | host-agnostic session env (GPU env is per-host, see below) |
| `config/{kitty,nvim,atuin,mpv,wireplumber,Kvantum,…}` | misc app configs |
| `hosts/<name>/` | per-host hardware (monitor layout, GPU env) |
| `themes/` | MacTahoe GTK/icon/KDE themes as git submodules |
| `applications/` | `Hidden=true` stubs that hide stock desktop entries from the launcher |

## Dependencies

Core: `niri`, `uwsm`, `quickshell` (`qs`), `nushell`, `dotter`.
Shell/session: `kitty`, `wtype`, `pipewire` + `wireplumber`, `polkit-gnome`,
`1password` (SSH agent + autostart), `qt6ct` + `kvantum`.
Tools sourced by nushell: `atuin`, `zoxide`, `asdf`, `carapace`, `bat`.
VPN (optional): `tailscale`, `openvpn`. Fonts: a JetBrainsMono Nerd Font.

No `jq` required — scripts parse JSON without it.

## Install on a new host

```sh
git clone --recurse-submodules <repo-url> ~/dotfiles
cd ~/dotfiles

# select this machine's host package (see "Per-host" below)
cp .dotter/local.toml.example .dotter/local.toml
$EDITOR .dotter/local.toml          # set packages = ["default", "host-<name>"]

dotter deploy
```

If you cloned without `--recurse-submodules`, fetch the themes with
`git submodule update --init`.

## Shared runtime config

Host-agnostic personal settings live in `config/dotfiles/config.json`, deployed to
`~/.config/dotfiles/config.json` and read at runtime by the shell (hot-reloads on
change; falls back to built-in defaults if missing):

```json
{
  "wallpaper": "~/.config/dotfiles/wp2.jpg",
  "vpn": { "backend": "tailscale", "privileged": "doas",
           "vpnCtl": "/usr/local/bin/vpn-ctl", "openvpn": ["animativ"] },
  "lock": { "name": "", "avatar": "", "timeout": 300 }
}
```

- `Config.qml` reads `wallpaper` and `lock.*`.
- `config/quickshell/menus/vpn.sh` reads `vpn.openvpn[]`, `vpn.privileged`, `vpn.vpnCtl`.

This file is the same on every host; edit it to change wallpaper/VPN endpoints.

## Per-host hardware

Things that differ per machine (monitors, GPU) live under `hosts/<name>/` and are
deployed by a per-host dotter package selected in the (gitignored) `.dotter/local.toml`:

- `hosts/<name>/niri-output.kdl` → `~/.config/niri/output.kdl` (monitor layout;
  `config.kdl` does `include "output.kdl"`).
- `hosts/<name>/uwsm-gpu-env` → `~/.config/uwsm/env.d/gpu` (GPU vars; uwsm
  auto-sources `env*.d/*`).

To add a machine: copy `hosts/_template` → `hosts/<name>`, fill in the files
(`niri msg outputs` lists connectors), add a `[host-<name>.files]` block in
`.dotter/global.toml` (template is commented there), and select it in `local.toml`.

## Known caveats

- **niri Ctrl shortcuts via `wtype`** (`config/niri/bindings.kdl`): `Mod+C/V/X/…`
  synthesize `Ctrl+key` by spawning `wtype`. This is fragile (timing/focus
  dependent); a system-level remapper (`keyd`/`xremap`) would be more robust.
- **Lock `unlock` IPC** (`config/quickshell/modules/Lock.qml`): `qs ipc call lock
  unlock` clears the lock without authentication — a deliberate recovery hatch,
  reachable only by processes already running as you.
