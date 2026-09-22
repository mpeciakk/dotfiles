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
| `config/herdr/` | [herdr](https://herdr.dev) terminal workspace manager: `config.toml`, the herdr-lazy plugin list + lockfile, per-plugin configs |
| `config/{kitty,nvim,atuin,mpv,wireplumber,…}` | misc app configs |
| `hosts/<name>/` | per-host hardware (monitor layout, GPU env) |
| `applications/` | `Hidden=true` stubs that hide stock desktop entries from the launcher |

## Dependencies

Core: `niri`, `uwsm`, `quickshell` (`qs`), `nushell`, `dotter`.
Shell/session: `kitty`, `keyd` (Super→Ctrl remaps), `pipewire` + `wireplumber`,
`polkit-gnome`, `1password` (SSH agent + autostart), `qt6ct`.
Clipboard/media: `cliphist` + `wl-clipboard` (clipboard history), `playerctl` (media keys).
Tools sourced by nushell: `atuin`, `zoxide`, `asdf`, `carapace`, `bat`.
VPN (optional): `tailscale`, `openvpn`. Fonts: a JetBrainsMono Nerd Font.

No `jq` required — scripts parse JSON without it.

## Install on a new host

```sh
git clone <repo-url> ~/dotfiles
cd ~/dotfiles

# select this machine's host package (see "Per-host" below)
cp .dotter/local.toml.example .dotter/local.toml
$EDITOR .dotter/local.toml          # set packages = ["default", "host-<name>"]

dotter deploy
```

nushell sources tool-init files from `~/.local/share/<tool>/init.nu`; generate
them once per host for the tools you use (a missing one degrades gracefully to an
empty stub, so the shell still starts):

```sh
mkdir -p ~/.local/share/{atuin,zoxide}
atuin init nu  | save -f ~/.local/share/atuin/init.nu
zoxide init nushell | save -f ~/.local/share/zoxide/init.nu
```

### herdr plugins

`config/herdr/plugins.list` declares the plugin set and `plugins.lock` pins it to exact
commits; [herdr-lazy](https://github.com/natori-hrj/herdr-lazy) reads them in place via
`HERDR_LAZY_LIST` (set in `config/uwsm/env`), so neither file is symlinked. On a new host,
after `dotter deploy` and a fresh graphical session (the export has to be in the
environment herdr's server inherits):

```sh
herdr plugin install natori-hrj/herdr-lazy   # only the manager; the rest comes from the lock
herdr-lazy restore                           # exact commits from plugins.lock ("sync" takes the latest)
```

`herdr-lazy` is not on `$PATH` — it lives in herdr's plugin dir under a hashed name; run it
from the manage pane (`prefix+shift+l`) or via `herdr plugin list --json`. Several plugins
(mirror, navigator, lazy) build from source and herdr builds with a minimal `PATH` that
excludes `~/.cargo/bin`, so the host needs a system `cargo`/`rustc` (`/usr/bin`), not just
rustup. `herdr integration status` should report `claude: current` — it reads that from
`.claude/hooks/herdr-agent-state.sh`, which this repo already deploys.

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
- `hosts/pc/herdr-mirror-hosts.toml` → `~/.config/herdr-mirror/hosts.toml` (which
  machine herdr-mirror mirrors — `target` names the *other* host and its `~/.ssh/config`
  alias, so this one can never be shared).

`.dotter/local.toml` is also read by `.claude/hooks/prompt-context`, which names
the machine in every Claude Code session — both hosts report hostname `ciek`, so
the selected `host-*` package is the only thing that tells them apart. A checkout
without that file — run directly, not through the deployed
`~/.claude/hooks/` symlink — reports `[CTX] unknown (…)`.

To add a machine: copy an existing `hosts/<host>` dir (e.g. `hosts/mac`) to
`hosts/<name>`, fill in the files (`niri msg outputs` lists connectors), add a
`[host-<name>.files]` block in `.dotter/global.toml`, and select it in `local.toml`.

## Known caveats

- **Super shortcuts via `keyd`** (`config/keyd/default.conf`): `Mod+C/V/X/…` are
  remapped to the matching `Ctrl+key` at the evdev layer by `keyd` (a root systemd
  service), not by niri — so they're deliberately absent from `bindings.kdl`.
  Copy/paste use `Ctrl/Shift+Insert` so terminals copy while `Ctrl+C` stays SIGINT.
  Needs `keyd` installed and `keyd.service` enabled on a fresh host.
- **herdr's own state is not in this repo.** Only `config.toml` and the per-plugin configs
  are; `session.json`, `plugins.json`, `plugins/github/*`, the logs and sockets under
  `~/.config/herdr`, and everything in `~/.local/state/herdr*` are per-host runtime state.
  `plugins.list`/`plugins.lock` are pointed at, not symlinked: herdr-lazy replaces the lock
  with `rename(2)`, which would swap a symlink for a regular file and silently detach it
  from the repo. If herdr ever rewrites `config.toml` the same way (`herdr config
  reset-keys`, onboarding), check `ls -l ~/.config/herdr/config.toml` still points here.
- **Lock `unlock` IPC** (`config/quickshell/modules/Lock.qml`): `qs ipc call lock
  unlock` clears the lock without authentication — a deliberate recovery hatch,
  reachable only by processes already running as you.
