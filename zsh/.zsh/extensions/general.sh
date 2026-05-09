##
## Configurations for both macOS and Linux
##

##
## Enable starship
##
if command -v starship &>/dev/null; then eval "$(starship init zsh)"; fi

##
## Mise
##
if command -v mise &>/dev/null; then eval "$(mise activate zsh)"; fi

##
## FZF
##
if command -v fzf &>/dev/null; then source <(fzf --zsh); fi

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
