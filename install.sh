#!/usr/bin/env bash
##
## Install dotfiles through dotlayer.
##
## Usage:
##   ./install.sh
##   DOTLAYER_PROFILE=laptop DOTLAYER_MACHINE=t14 ./install.sh --dry-run --verbose
##

set -euo pipefail

# The ~/.config/dotlayer/dotlayer.yml link only exists after the first stow,
# so point a fresh machine straight at the private config.
config_args=()
private_config="$HOME/.private_dotfiles/config/.config/dotlayer/dotlayer.yml"
[[ -f $private_config ]] && config_args=(-c "$private_config")

if command -v dotlayer >/dev/null 2>&1; then
  exec dotlayer install "${config_args[@]}" "$@"
fi

if [[ -x "$HOME/src/dotlayer/exe/dotlayer" ]]; then
  exec "$HOME/src/dotlayer/exe/dotlayer" install "${config_args[@]}" "$@"
fi

printf '%s\n' "dotlayer is required. Install it or clone it to \$HOME/src/dotlayer." >&2
exit 1
