#!/bin/bash

fd -t d "" config -x rm -rf ~/.{}
fd -t d "" config -d 1 -x ln -s $HOME/dotfiles/{} $HOME/.{}

# cp ~/dotfiles/config/starship.toml ~/.config/
