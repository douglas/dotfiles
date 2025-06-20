##
## ZSH Configuration
##

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
## Environment Variables
##
export EDITOR='zed'

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

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/douglas/.cache/lm-studio/bin"
# End of LM Studio CLI section
