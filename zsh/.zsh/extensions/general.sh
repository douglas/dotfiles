##
## Configurations for both macOS and Linux
##

##
## Lazydocker
##
alias lzd='lazydocker'

##
## Thefuck
##
eval $(thefuck --alias f)

##
## Enable starship
##
eval "$(starship init zsh)"

##
## FNM
##
#eval "$(fnm env --use-on-cd)"

##
## Zoxide
##
eval "$(zoxide init --cmd cd zsh)"
