#!/bin/bash

# Remove only top-level directories (e.g., nvim) from home
fd -t d "" config -d 1 -x rm -rf ~/."{}"

# Create symlinks for these top-level directories
fd -t d "" config -d 1 -x ln -s $HOME/dotfiles/"{}" $HOME/."{}"

# cp ~/dotfiles/config/starship.toml ~/.config/
