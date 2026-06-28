$env.CARAPACE_BRIDGES = 'fish'
mkdir $"($nu.cache-dir)"
carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"

$env.SSH_AUTH_SOCK = ($env.HOME | path join ".1password/agent.sock")
