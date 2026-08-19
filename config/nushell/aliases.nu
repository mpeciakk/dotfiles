alias c = clear
alias e = exit
alias g = git
alias ga = git add .
alias gs = git status -s
alias gc = git commit -m
alias cd = z

def gfp [] { git fetch --all --prune; git pull }

alias l = ls
alias la = ls -a
alias ll = ls -l
alias lsal = ls -a -l
alias ldu = ls --du
alias ladu = ls --du -a

alias cat = bat

# Bypass permissions dostępny w cyklu Shift+Tab, ale NIE aktywny na starcie.
# Wariant --allow-* dokłada tryb do cyklu bez włączania go (docs: permission-modes),
# więc sesja startuje normalnie w auto mode, a bypass jest jedno Shift+Tab dalej.
# Ustawienie tego przez permissions.defaultMode włączałoby bypass od pierwszej
# sekundy każdej sesji i wypierało auto mode ze startu — dlatego alias, nie settings.
alias claude = ^claude --allow-dangerously-skip-permissions
