##
## macOS aliases e configurations
##

##
## General PATH changes
##
export PATH="/Users/douglas/.local/bin:$PATH"
export PATH="/Users/douglas/.bin:$PATH"

##
## Homebrew
##
export HOMEBREW_NO_ANALYTICS=1
[[ -x /opt/homebrew/bin/brew ]] && eval $(/opt/homebrew/bin/brew shellenv)

##
## ADSF
##
#source /opt/homebrew/opt/asdf/libexec/asdf.sh

##
## Mise
##
eval "$(mise activate zsh)"

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
export PATH="$PATH:/opt/homebrew/opt/rustup/bin"
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
export PATH="$PATH:$GOPATH/bin"

##
## ZSH Plugins
##

# Requires zsh-autosuggestions and zsh-syntax-highlighting zsh plugins
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
#source /opt/homebrew/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
#source ~/.zsh/themes/catppuccin_frappe-zsh-syntax-highlighting.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
