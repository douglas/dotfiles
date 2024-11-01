##
## Install stow configurations
##

stow stow
stow bin
stow git
stow zsh

if [[ $OPERATINGSYSTEM == 'macos' ]]; then
  stow apps-macos
else
  stow apps-linux
fi

# Install git-cob in /usr/local/bin so git can use it
git_cob="/usr/local/bin/git-cob"
[ ! -f "$git_cob" ] && sudo ln -s $HOME/.bin/git-cob "$git_cob"
