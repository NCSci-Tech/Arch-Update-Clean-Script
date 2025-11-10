#!/bin/bash

# Update official repositories
sudo pacman -Syu

# Update AUR packages (requires yay)
yay -Sua

# Remove orphaned packages
orphans=$(pacman -Qtdq 2>/dev/null)
if [ -n "$orphans" ]; then
    sudo pacman -Rns $orphans --noconfirm
else
    echo "No orphaned packages found."
fi

# Clean old package cache
sudo pacman -Sc --noconfirm

# Optionally, clean *all* cache (uncomment if desired)
# sudo pacman -Scc

# Update locate and man databases
sudo updatedb
sudo mandb
