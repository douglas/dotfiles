##
## ZSH Configuration
##

##
## Environment
##
export TMPDIR="$HOME/tmp"
export _ZO_DOCTOR=0
export ENABLE_LSP_TOOL=1
export PATH="$HOME/.local/bin:$HOME/.bin:$PATH"
export PATH="$HOME/.lmstudio/bin:$HOME/.opencode/bin:$PATH"

##
## OS specific configs
##
if [[ $OSTYPE == darwin* ]]; then
	source ~/.zsh/extensions/macos.sh
else
	source ~/.zsh/extensions/linux.sh
fi

##
## Default aliases (transparent replacements)
##
alias cat="bat"
alias top="bottom"
alias ls="eza"
alias ll="eza -la"
alias lt="eza -laT -I .git ."

##
## Load Extensions
##
source ~/.zsh/extensions/zsh.sh
source ~/.zsh/extensions/general.sh
source ~/.zsh/extensions/git.sh

##
## Load Theme (Omarchy-generated, with static fallback)
##
if [[ -f ~/.config/omarchy/current/theme/fzf.sh ]]; then
	source ~/.config/omarchy/current/theme/fzf.sh
else
	source ~/.zsh/themes/catppuccin-mocha.sh
fi

##
## Work related configurations
##
[[ -f ~/.zsh_private/load_environment.sh ]] && source ~/.zsh_private/load_environment.sh

## ─── Everything below must stay at the end of .zshrc ───

# ZSH Syntax Highlighting theme (must be loaded before the plugin)
if [[ -f ~/.config/omarchy/current/theme/zsh-syntax-highlighting.zsh ]]; then
	source ~/.config/omarchy/current/theme/zsh-syntax-highlighting.zsh
elif [[ -f ~/.zsh/themes/catppuccin_mocha-zsh-syntax-highlighting.zsh ]]; then
	source ~/.zsh/themes/catppuccin_mocha-zsh-syntax-highlighting.zsh
fi

# ZSH Syntax Highlighting (must be sourced at the very end of .zshrc)
if [[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
	source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
	source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Entire CLI shell completion
if (( $+commands[entire] )); then source <(entire completion zsh 2>/dev/null); fi

# Zoxide (must be initialized at the very end of .zshrc)
eval "$(zoxide init --cmd cd zsh)"
