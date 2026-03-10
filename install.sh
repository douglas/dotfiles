##
## Install stow configurations
##
## Usage:
##   ./install.sh                    # Auto-detects OS and profile
##   PROFILE=laptop ./install.sh     # Override profile on Linux
##

stow -d ~/.public_dotfiles -t ~ stow
stow -d ~/.public_dotfiles -t ~ bin
stow -d ~/.public_dotfiles -t ~ git
stow -d ~/.public_dotfiles -t ~ zsh
stow -d ~/.public_dotfiles -t ~ apps

if [[ $OSTYPE == darwin* ]]; then
  stow -d ~/.public_dotfiles -t ~ apps-macos
else
  PROFILE="${PROFILE:-$(hostnamectl chassis 2>/dev/null || echo desktop)}"
  stow -d ~/.public_dotfiles -t ~ apps-linux
  stow -d ~/.public_dotfiles -t ~ "apps-linux-${PROFILE}"

  if command -v omarchy &>/dev/null; then
    stow -d ~/.public_dotfiles -t ~ apps-omarchy
    stow -d ~/.public_dotfiles -t ~ "apps-omarchy-${PROFILE}"
  fi
fi

# Install git-cob in /usr/local/bin so git can use it
git_cob="/usr/local/bin/git-cob"
[ ! -f "$git_cob" ] && sudo ln -s $HOME/.bin/git-cob "$git_cob"

# Bootstrap private dotfiles if available
if [[ -f ~/.private_dotfiles/install.sh ]]; then
  echo "=> Stowing private dotfiles..."
  source ~/.private_dotfiles/install.sh
fi
