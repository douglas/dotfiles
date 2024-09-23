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

##
## Work related configurations
##
if [[ -f ~/.zsh_private/prepare_environment.sh ]]; then
	source ~/.zsh_private/prepare_environment.sh
fi
