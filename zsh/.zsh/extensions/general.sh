##
## Configurations for both macOS and Linux
##

##
## Enable starship
##
eval "$(starship init zsh)"

##
## Mise
##
eval "$(mise activate zsh)"

##
## Golang
##
export GOPATH=$HOME
export PATH="$PATH:$GOPATH/bin"
