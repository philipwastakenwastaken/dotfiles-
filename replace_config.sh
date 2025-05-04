#!/usr/bin/env bash
set -eu -o pipefail

DOTFILES="$HOME/dotfiles-"
CFGROOT="$DOTFILES/config"     # e.g. .../dotfiles/config/nvim
DEST="$HOME/.config"           # where the links should live (respects XDG)

mkdir -p "$DEST"               # 1. ensure ~/.config exists

# 2. remove stale links or dirs (except git)
fd -t d "" "$CFGROOT" -d 1 --exclude git \
   -x rm -rf "$DEST/{/}"

# 3. recreate links
fd -t d "" "$CFGROOT" -d 1 --exclude git \
   -x ln -s "{}" "$DEST/{/}"

# standalone git config still belongs in $HOME itself
cp "$CFGROOT/git/.gitconfig" "$HOME/.gitconfig"
