##
## Configurations for both macOS and Linux
##

##
## Lazydocker / Lazygit (abbreviations defined in zsh.sh)
##

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
