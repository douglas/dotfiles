##
## ZSH Configuration
##

##
## Environment
##
export TMPDIR="$HOME/tmp"
export PATH="$HOME/.local/bin:$HOME/.bin:$PATH"
export PATH="$HOME/.lmstudio/bin:$HOME/.opencode/bin:$PATH"

##
## Utils
##
source ~/.zsh/extensions/utils.sh

##
## OS specific configs
##
if [[ $OPERATINGSYSTEM == 'macos' ]]; then
	source ~/.zsh/extensions/macos.sh
else
	source ~/.zsh/extensions/linux.sh
fi

##
## Default aliases
##
alias cat="bat"
alias top="bottom"
alias ls="eza"
alias ll="eza -la"
alias lt="eza -laT -I .git ."
alias zshconfig="zed ~/.public_dotfiles ~/.private_dotfiles"
alias zshreload="source ~/.zshrc"

##
## Load Extensions
##
source ~/.zsh/extensions/zsh.sh
source ~/.zsh/extensions/general.sh
source ~/.zsh/extensions/networking.sh
source ~/.zsh/extensions/git.sh
source ~/.zsh/extensions/ruby-on-rails.sh
source ~/.zsh/extensions/fzf.sh

##
## Load Theme
##
source ~/.zsh/themes/catppuccin-frappe.sh

##
## Work related configurations
##
[[ -f ~/.zsh_private/load_environment.sh ]] && source ~/.zsh_private/load_environment.sh

## ─── Everything below must stay at the end of .zshrc ───

# ZSH Syntax Highlighting (must be sourced at the very end of .zshrc)
if [[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
	source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
	source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Entire CLI shell completion
autoload -Uz compinit && compinit && source <(entire completion zsh)
