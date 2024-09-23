##
## macOS aliases e configurations
##

##
## Homebrew
##
[[ -x /opt/homebrew/bin/brew ]] && eval $(/opt/homebrew/bin/brew shellenv)

##
## General PATH changes
##
export PATH="~/.bin:$PATH"
export PATH="$PATH:/~/.local/bin"

##
## ADSF
##
source /opt/homebrew/opt/asdf/libexec/asdf.sh

##
## Rubymine
##
alias cd-rubymine-gems='cd /Users/douglas/Applications/RubyMine.app/Contents/plugins/ruby/rb/gems'

##
## VS Code
##
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

##
## Rust
##
export PATH="$PATH:/Users/douglas/.cargo/bin"

##
## LM Studio
##
export PATH="$PATH:/Users/douglas/.cache/lm-studio/bin"

##
## Iterm2
## https://www.iterm2.com/

# home and end in iterm2
bindkey '\e[H'    beginning-of-line
bindkey '\e[F'    end-of-line

##
## Golang
##
export GOPATH=$HOME
export PATH=$PATH:$GOPATH/bin

##
## FZF
##
source <(fzf --zsh)

# # Auto-completion
# # ---------------
# [[ $- == *i* ]] && source "/opt/homebrew/opt/fzf/shell/completion.zsh" 2> /dev/null

# # Key bindings
# # ------------
# source "/opt/homebrew/opt/fzf/shell/key-bindings.zsh"

##
## ZSH Plugins
##

# Requires zsh-autosuggestions and zsh-syntax-highlighting zsh plugins
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
