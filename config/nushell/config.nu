use std/util "path add"

$env.config.show_banner = false

let shims_dir = (
  if ( $env | get -o ASDF_DATA_DIR | is-empty ) {
    $env.XDG_DATA_HOME | path join 'toolchains/asdf'
  } else {
    $env.ASDF_DATA_DIR
  } | path join 'shims'
)
$env.PATH = ( $env.PATH | split row (char esep) | where { |p| $p != $shims_dir } | prepend $shims_dir )

path add ~/.local/bin/

source ~/.local/share/atuin/init.nu
source ~/.local/share/zoxide/init.nu
source ~/.local/share/asdf/init.nu
source $"($nu.cache-dir)/carapace.nu"

alias c = clear
alias e = exit
alias g = git
alias ga = git add .
alias gs = git status -s
alias gc = git commit -m
alias gfp = git fetch and git pull
alias cd = z

alias l = ls
alias la = ls -a
alias ll = ls -l
alias lsal = ls -a -l
alias ldu = ls --du
alias ladu = ls --du -a

alias cat = bat

def cc [...args] {
    with-env {
        ANTHROPIC_BASE_URL: "https://opencode.ai/zen/v1/messages",
        ANTHROPIC_AUTH_TOKEN: "",
        ANTHROPIC_API_KEY: "sk-HtPWKq1554bA5ap1ulHJkHMIAIqCusDptdoCrDO3TBR8Ust3zeHa9j65oLwipBtj",
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: 1
    } {
        claude ...$args
    }
}
