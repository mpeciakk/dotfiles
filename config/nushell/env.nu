# Ensure the tool-init files sourced by init.nu always exist. nushell `source`
# is parse-time, so a missing file breaks startup — on a host where a tool isn't
# set up yet, leave an empty stub so the shell still starts (generate the real
# init during host setup, e.g. `atuin init nu | save -f ~/.local/share/atuin/init.nu`).
for tool in [atuin zoxide asdf] {
    let init = ($env.HOME | path join '.local/share' $tool 'init.nu')
    if not ($init | path exists) {
        mkdir ($init | path dirname)
        '' | save --force $init
    }
}

# Carapace completion bridge: generate once, not on every shell startup (the old
# unconditional `save --force` respawned carapace each launch). Refresh after a
# carapace upgrade with: carapace _carapace nushell | save -f ($nu.cache-dir)/carapace.nu
$env.CARAPACE_BRIDGES = 'fish'
let carapace_init = ($nu.cache-dir | path join 'carapace.nu')
if not ($carapace_init | path exists) {
    mkdir $nu.cache-dir
    carapace _carapace nushell | save --force $carapace_init
}

# Use the 1Password SSH agent (e.g. for git over SSH) from nushell.
$env.SSH_AUTH_SOCK = ($env.HOME | path join '.1password/agent.sock')
