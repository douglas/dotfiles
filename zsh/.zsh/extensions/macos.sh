##
## macOS configurations
##

##
## Homebrew
##
export HOMEBREW_NO_ANALYTICS=1
[[ -x /opt/homebrew/bin/brew ]] && eval $(/opt/homebrew/bin/brew shellenv)

##
## Rust
##
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
