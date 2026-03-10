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

##
## RubyMine
##
alias cd-rubymine-gems='cd $HOME/Applications/RubyMine.app/Contents/plugins/ruby/rb/gems'

##
## VS Code
##
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
