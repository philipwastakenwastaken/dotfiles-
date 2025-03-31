#!/bin/bash

# nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# copr
sudo wget -P /etc/yum.repos.d/ https://copr.fedorainfracloud.org/coprs/pgdev/ghostty/repo/fedora-rawhide/pgdev-ghostty-fedora-rawhide.repo
sudo wget -P /etc/yum.repos.d/ https://copr.fedorainfracloud.org/coprs/yalter/niri/repo/fedora-rawhide/yalter-niri-fedora-rawhide.repo

# packages
rpm-ostree install ghostty niri waybar

# azure artifacts credential provider
wget -qO- https://aka.ms/install-artifacts-credprovider.sh | bash
