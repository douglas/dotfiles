##
## ZSH Configuration
##

##
## Environment
##
export TMPDIR="$HOME/tmp"
export VISUAL=zed
export _ZO_DOCTOR=0
export ENABLE_LSP_TOOL=1
export CLAUDE_CODE_NO_FLICKER=1
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cache/.bun/bin:$PATH"
export PATH="$HOME/.bin:$PATH"

##
## OS specific configs
##
if [[ $OSTYPE == darwin* ]]; then
	source ~/.zsh/extensions/macos.sh
else
	source ~/.zsh/extensions/linux.sh
fi

##
## Bose QC35 II Bluetooth profile switching
##
alias bose-mic='pactl set-card-profile bluez_card.4C_87_5D_CE_E0_96 headset-head-unit'
alias bose-music='pactl set-card-profile bluez_card.4C_87_5D_CE_E0_96 a2dp-sink'

##
## Default aliases (transparent replacements)
##
alias fix_term="stty sane"  # Restore terminal after Claude Code or other apps leave it in a broken state
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

# Gum theme (Omarchy-generated)
if [[ -f ~/.config/omarchy/current/theme/gum.sh ]]; then
	source ~/.config/omarchy/current/theme/gum.sh
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

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/douglas/.lmstudio/bin"
# End of LM Studio CLI section


# dox-agent PATH
export PATH="/home/douglas/work/agentic-dev/bin:$PATH"

# >>> wt initialize >>>
eval "$(wt shellenv)"
# <<< wt initialize <<<

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.Fyfhd3KoVV/bin:$PATH"

# mise (tool version manager)
eval "$(mise activate zsh)"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.Sx5pdSIsYR/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.SKYzycBCQv/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.EalcSBUCzI/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.hIRypa7EK7/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.yMB8wAQaDZ/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.5KNT0KXxo7/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.Q2HGnhIANo/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.4upwUrWE9t/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.nKhZ4qhNRO/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.SEjz1eDfbC/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.8yTV33SFjt/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.rlpBhrYChi/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.sdskbPhLhK/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.ZkC18zFpxx/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.KH53HyNt4R/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.92KInDeh5Q/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.PP4sWxRwGA/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.ry95yICjFG/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.v6QHMVajOW/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.c0uAkrMa57/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.O0peB7eZcw/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.AJ7wWffQCN/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.OOlrTPfHDZ/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.pHjp7MZVya/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.bQ5buPt5eg/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.HU9Gv67WLV/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.9LpTt6W8Qd/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.NogVb6agKO/bin:$PATH"

# dox-agent PATH
export PATH="/home/douglas/tmp/tmp.ih4FWfvzag/bin:$PATH"
