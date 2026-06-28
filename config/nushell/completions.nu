# carapace-backed external completer, wired into nushell's completion engine.
# This overrides the default completer that carapace's own init installs, adding
# alias-aware completion (so `g`, `gs`, `ga` complete as their expanded command)
# and a docker carve-out. Sourced after init.nu (which loads carapace.nu), so
# this assignment wins.
let carapace_completer = {|spans: list<string>|
    CARAPACE_LENIENT=1 carapace $spans.0 nushell ...$spans | from json
}

$env.config.completions.external.enable = true
$env.config.completions.external.completer = {|spans|
    # Expand a leading alias to its real command so completions match it
    # (e.g. `ga ` -> `git add . `), keeping the rest of the typed words.
    let expanded = scope aliases | where name == $spans.0 | get -o 0.expansion
    let spans = if $expanded != null {
        $spans | skip 1 | prepend ($expanded | split row ' ')
    } else { $spans }

    match $spans.0 {
        docker => null                      # no carapace for docker; nushell falls back
        _ => (do $carapace_completer $spans)
    }
}
