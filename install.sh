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
stow -d ~/.public_dotfiles -t ~ config

if [[ $OSTYPE == darwin* ]]; then
  stow -d ~/.public_dotfiles -t ~ config-macos
else
  PROFILE="${PROFILE:-$(hostnamectl chassis 2>/dev/null || echo desktop)}"
  stow -d ~/.public_dotfiles -t ~ config-linux

  if command -v omarchy &>/dev/null; then
    stow -d ~/.public_dotfiles -t ~ config-omarchy
    stow -d ~/.public_dotfiles -t ~ "config-omarchy-${PROFILE}"
  elif [[ -f /etc/os-release ]] && source /etc/os-release && [[ "$ID" == "fedora" ]]; then
    stow -d ~/.public_dotfiles -t ~ "config-fedora-${PROFILE}"
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
