##
## Install stow configurations
##

stow stow
stow bin
stow git
stow zsh

# Install git-cob in /usr/local/bin so git can use it
sudo ln -s $HOME/.bin/git-cob /usr/local/bin/git-cob
