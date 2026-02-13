##
## Configurations for both macOS and Linux
##

##
## Lazydocker
##
alias lzd='lazydocker'

##
## Lazygit
##
alias lzg='Lazygit'

##
## Enable starship
##
eval "$(starship init zsh)"

##
## FNM
##
#eval "$(fnm env --use-on-cd)"

##
## Mise
##
eval "$(mise activate zsh)"

##
## Golang
##
export GOPATH=$HOME
export PATH="$PATH:$GOPATH/bin"

##
## Zoxide
##
eval "$(zoxide init --cmd cd zsh)"
