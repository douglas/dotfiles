##
## ZSH Configuration
##

##
## Environment
##
export VISUAL=zed
export EDITOR=zed
export _ZO_DOCTOR=0
export ENABLE_LSP_TOOL=1
export CLAUDE_CODE_NO_FLICKER=1
unset NO_COLOR
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cache/.bun/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"
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
## Bose QC35 II Bluetooth profile switching (Linux/PulseAudio only)
##
if [[ $OSTYPE != darwin* ]]; then
	alias bose-mic='pactl set-card-profile bluez_card.4C_87_5D_CE_E0_96 headset-head-unit'
	alias bose-music='pactl set-card-profile bluez_card.4C_87_5D_CE_E0_96 a2dp-sink'
fi

##
## Default aliases (transparent replacements)
##
alias fix_term="stty sane"  # Restore terminal after Claude Code or other apps leave it in a broken state
alias cat="bat"
alias top="bottom"
alias ls="eza"
alias ll="eza -la"
alias lt="eza -laT -I .git ."

codex() {
	local arg
	for arg in "$@"; do
		case "$arg" in
			-p|--profile|--profile=*|\
			-a|--ask-for-approval|--ask-for-approval=*|\
			-s|--sandbox|--sandbox=*|\
			--dangerously-bypass-approvals-and-sandbox)
				command codex "$@"
				return
				;;
		esac
	done

	local current_dir="${PWD:A}"
	local src_dir="${HOME:A}/src"
	local work_dir="${HOME:A}/work"
	local memories_dir="${HOME:A}/.codex/memories"

	if [[ "$current_dir" == "$src_dir" || "$current_dir" == "$src_dir"/* || "$current_dir" == "$work_dir" || "$current_dir" == "$work_dir"/* ]]; then
		command codex \
			-a never \
			-s workspace-write \
			-c 'sandbox_workspace_write.network_access=true' \
			-c "sandbox_workspace_write.writable_roots=[\"$src_dir\",\"$work_dir\",\"$memories_dir\",\"/tmp\"]" \
			"$@"
	else
		command codex -a on-request -s read-only "$@"
	fi
}

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

# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
# End of LM Studio CLI section

# Zoxide (must be initialized at the very end of .zshrc)
eval "$(zoxide init --cmd cd zsh)"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi
