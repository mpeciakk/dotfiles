use std/util "path add"

path add ~/.local/bin/

source ~/.local/share/atuin/init.nu
source ~/.local/share/zoxide/init.nu
source ~/.local/share/asdf/init.nu
source $"($nu.cache-dir)/carapace.nu"

# Put asdf's shims first on PATH (deduped so re-sourcing doesn't stack entries).
# ASDF_DATA_DIR wins if set; otherwise fall back to XDG (with a HOME default so
# this still works on a bare TTY/SSH session where XDG_DATA_HOME isn't exported).
let xdg_data = ($env | get -o XDG_DATA_HOME | default ($env.HOME | path join '.local/share'))
let asdf_env = ($env | get -o ASDF_DATA_DIR | default "")
let asdf_data = if ($asdf_env | is-empty) { $xdg_data | path join 'toolchains/asdf' } else { $asdf_env }
let shims_dir = ($asdf_data | path join 'shims')
$env.PATH = ($env.PATH | split row (char esep) | where {|p| $p != $shims_dir} | prepend $shims_dir)
