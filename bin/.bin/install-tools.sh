#!/usr/bin/env bash
set -euo pipefail

##
## Install CLI tools to ~/.bin that aren't available via system package managers.
## On macOS, most tools come from Homebrew (see Brewfile). This script handles
## the remaining tools and all Linux installations.
##

DEST="$HOME/.bin"
mkdir -p "$DEST"

OS="$(uname -s)"
ARCH="$(uname -m)"

# Normalize architecture names
case "$ARCH" in
  x86_64)  ARCH_GO="amd64"; ARCH_RUST="x86_64" ;;
  aarch64) ARCH_GO="arm64"; ARCH_RUST="aarch64" ;;
  arm64)   ARCH_GO="arm64"; ARCH_RUST="aarch64" ;;
  *)       echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

install_aws_vault() {
  echo "Installing aws-vault..."
  local version
  version=$(curl -s https://api.github.com/repos/99designs/aws-vault/releases/latest | grep tag_name | cut -d '"' -f 4)
  if [ "$OS" = "Darwin" ]; then
    brew install --cask aws-vault
  else
    curl -Lo "$DEST/aws-vault" "https://github.com/99designs/aws-vault/releases/download/${version}/aws-vault-linux-${ARCH_GO}"
    chmod +x "$DEST/aws-vault"
  fi
}

install_eza() {
  echo "Installing eza..."
  if [ "$OS" = "Darwin" ]; then
    brew install eza
  else
    cargo install eza
    # cargo installs to ~/.cargo/bin, copy to ~/.bin for PATH consistency
    cp "$HOME/.cargo/bin/eza" "$DEST/eza"
  fi
}

install_lazydocker() {
  echo "Installing lazydocker..."
  local version
  version=$(curl -s https://api.github.com/repos/jesseduffield/lazydocker/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/^v//')
  if [ "$OS" = "Darwin" ]; then
    brew install lazydocker
  else
    local tarball="lazydocker_${version}_Linux_${ARCH}.tar.gz"
    curl -Lo "/tmp/$tarball" "https://github.com/jesseduffield/lazydocker/releases/download/v${version}/${tarball}"
    tar xzf "/tmp/$tarball" -C "$DEST" lazydocker
    rm "/tmp/$tarball"
  fi
}

install_mkcert() {
  echo "Installing mkcert..."
  local version
  version=$(curl -s https://api.github.com/repos/FiloSottile/mkcert/releases/latest | grep tag_name | cut -d '"' -f 4)
  if [ "$OS" = "Darwin" ]; then
    brew install mkcert
  else
    curl -Lo "$DEST/mkcert" "https://github.com/FiloSottile/mkcert/releases/download/${version}/mkcert-${version}-linux-${ARCH_GO}"
    chmod +x "$DEST/mkcert"
  fi
}

install_rails_new() {
  echo "Installing rails-new..."
  if [ "$OS" = "Darwin" ]; then
    local version
    version=$(curl -s https://api.github.com/repos/rails/rails-new/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/^v//')
    local binary="rails-new-aarch64-apple-darwin"
    curl -Lo "$DEST/rails-new" "https://github.com/rails/rails-new/releases/download/v${version}/${binary}"
    chmod +x "$DEST/rails-new"
  else
    echo "  rails-new is macOS-only, skipping on Linux"
  fi
}

# Install all tools
for tool in aws_vault eza lazydocker mkcert rails_new; do
  if command -v "${tool//_/-}" &>/dev/null || [ -x "$DEST/${tool//_/-}" ]; then
    echo "${tool//_/-} already installed, skipping (use --force to reinstall)"
    if [ "${1:-}" != "--force" ]; then
      continue
    fi
  fi
  "install_$tool"
done

echo "Done. Tools installed to $DEST"
