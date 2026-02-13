##
## Install stow configurations
##
## Usage:
##   PROFILE=desktop ./install.sh   # Linux desktop (default)
##   PROFILE=laptop ./install.sh    # Linux laptop
##   ./install.sh                   # macOS or Linux desktop
##

stow stow
stow bin
stow git
stow zsh
stow apps

if [[ $OPERATINGSYSTEM == 'macos' ]]; then
  stow apps-macos
else
  stow apps-linux
  PROFILE="${PROFILE:-desktop}"
  stow "apps-linux-${PROFILE}"
fi

# Install git-cob in /usr/local/bin so git can use it
git_cob="/usr/local/bin/git-cob"
[ ! -f "$git_cob" ] && sudo ln -s $HOME/.bin/git-cob "$git_cob"
