use std/util "path add"

path add ~/.local/bin/
path add ~/.cache/.bun/bin/

source ~/.local/share/atuin/init.nu
source ~/.local/share/zoxide/init.nu
source $"($nu.cache-dir)/carapace.nu"

