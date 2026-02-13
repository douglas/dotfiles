##
## macOS aliases e configurations
##

##
## General PATH changes
##
export PATH="$HOME/src/git-fuzzy/bin:$PATH"

##
## Homebrew
##
export HOMEBREW_NO_ANALYTICS=1
[[ -x /opt/homebrew/bin/brew ]] && eval $(/opt/homebrew/bin/brew shellenv)

##
## Rubymine
##
alias cd-rubymine-gems='cd $HOME/Applications/RubyMine.app/Contents/plugins/ruby/rb/gems'

##
## VS Code
##
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

##
## Rust
##
source "$HOME/.cargo/env"

##
## LM Studio
##
export PATH="$PATH:$HOME/.cache/lm-studio/bin"

##
## Iterm2
## https://www.iterm2.com/

# home and end in iterm2
bindkey '\e[H'    beginning-of-line
bindkey '\e[F'    end-of-line

