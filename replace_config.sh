#!/bin/bash

# Remove only top-level directories (e.g., nvim) from home, excluding 'git'
fd -t d "" config -d 1 --exclude git -x rm -rf ~/."{}"

# Create symlinks for these top-level directories, excluding 'git'
fd -t d "" config -d 1 --exclude git -x ln -s $HOME/dotfiles/"{}" $HOME/."{}"

cp $HOME/dotfiles/config/git/.gitconfig $HOME/.gitconfig
