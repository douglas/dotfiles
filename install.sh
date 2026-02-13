##
## Install stow configurations
##
## Usage:
##   PROFILE=desktop ./install.sh   # Linux desktop (default)
##   PROFILE=laptop ./install.sh    # Linux laptop
##   ./install.sh                   # macOS or Linux desktop
##

stow -d ~/.public_dotfiles -t ~ stow
stow -d ~/.public_dotfiles -t ~ bin
stow -d ~/.public_dotfiles -t ~ git
stow -d ~/.public_dotfiles -t ~ zsh
stow -d ~/.public_dotfiles -t ~ apps

if [[ $OPERATINGSYSTEM == 'macos' ]]; then
  stow -d ~/.public_dotfiles -t ~ apps-macos
else
  stow -d ~/.public_dotfiles -t ~ apps-linux
  PROFILE="${PROFILE:-desktop}"
  stow -d ~/.public_dotfiles -t ~ "apps-linux-${PROFILE}"
fi

# Install git-cob in /usr/local/bin so git can use it
git_cob="/usr/local/bin/git-cob"
[ ! -f "$git_cob" ] && sudo ln -s $HOME/.bin/git-cob "$git_cob"
