#!/usr/bin/env bash
##
## Install dotfiles through dotlayer.
##
## Usage:
##   ./install.sh
##   DOTLAYER_PROFILE=laptop DOTLAYER_MACHINE=t14 ./install.sh --dry-run --verbose
##

set -euo pipefail

if command -v dotlayer >/dev/null 2>&1; then
  exec dotlayer install "$@"
fi

if [[ -x "$HOME/src/dotlayer/exe/dotlayer" ]]; then
  exec "$HOME/src/dotlayer/exe/dotlayer" install "$@"
fi

printf '%s\n' "dotlayer is required. Install it or clone it to \$HOME/src/dotlayer." >&2
exit 1
