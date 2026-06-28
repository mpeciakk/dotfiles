use std/util "path add"

path add ~/.local/bin/

source ~/.local/share/atuin/init.nu
source ~/.local/share/zoxide/init.nu
source ~/.local/share/asdf/init.nu
source $"($nu.cache-dir)/carapace.nu"

let shims_dir = (
  if ( $env | get -o ASDF_DATA_DIR | is-empty ) {
    $env.XDG_DATA_HOME | path join 'toolchains/asdf'
  } else {
    $env.ASDF_DATA_DIR
  } | path join 'shims'
)
$env.PATH = ( $env.PATH | split row (char esep) | where { |p| $p != $shims_dir } | prepend $shims_dir )
