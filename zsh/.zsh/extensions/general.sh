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
## FZF
##
source <(fzf --zsh)

##
## Ruby (YJIT)
##
export RUBY_YJIT_ENABLE="1"
export RUBY_CONFIGURE_OPTS=--enable-yjit

##
## Golang
##
export PATH="$PATH:$HOME/go/bin"

##
## Networking
##

# Ports in use
function openports() {
	sudo lsof -iTCP -sTCP:LISTEN -n -P
}

# Processes using a specific port
function pup() {
	sudo lsof -iTCP -sTCP:LISTEN -n -P | grep -i --color $1
}
