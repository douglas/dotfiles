##
## Install stow configurations
##

stow stow
stow bin
stow git
stow zsh

if [[ $OPERATINGSYSTEM == 'macos' ]]; then
  stow ghostty-macos
else
  stow ghostty-linux
fi

# Install git-cob in /usr/local/bin so git can use it
sudo ln -s $HOME/.bin/git-cob /usr/local/bin/git-cob
