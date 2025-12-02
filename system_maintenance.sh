#!/bin/bash

set -e  # Exit on error

echo "==> Updating system packages..."
sudo pacman -Syu

echo "==> Updating AUR packages..."
# Uncomment if you use yay
# yay -Sua

echo "==> Removing orphaned packages..."
orphans=$(pacman -Qtdq 2>/dev/null)
if [ -n "$orphans" ]; then
    sudo pacman -Rns $orphans --noconfirm
else
    echo "No orphaned packages found."
fi

echo "==> Cleaning package cache (keeping last 3 versions)..."
if command -v paccache &> /dev/null; then
    sudo paccache -rk3
    sudo paccache -ruk0
else
    sudo pacman -Scc --noconfirm
fi

echo "==> Cleaning systemd temporary files..."
sudo systemd-tmpfiles --clean

echo "==> Cleaning journal logs (keep last 2 weeks)..."
sudo journalctl --vacuum-time=2weeks

echo "==> Removing old temporary files..."
sudo find /tmp -type f -atime +7 -delete 2>/dev/null || true
sudo find /var/tmp -type f -atime +10 -delete 2>/dev/null || true

echo "==> Cleaning user cache (safe items only)..."
rm -rf ~/.cache/thumbnails/*
rm -rf ~/.cache/mesa_shader_cache/*
rm -rf ~/.cache/fontconfig/*
rm -rf ~/.local/share/Trash/files/*
rm -rf ~/.local/share/Trash/info/*

echo "==> Cleaning pip cache (if you use Python)..."
if command -v pip &> /dev/null; then
    pip cache purge 2>/dev/null || true
fi

echo "==> Cleaning npm cache (if you use Node.js)..."
if command -v npm &> /dev/null; then
    npm cache clean --force 2>/dev/null || true
fi

echo "==> Cleaning cargo cache (if you use Rust)..."
if [ -d ~/.cargo ]; then
    rm -rf ~/.cargo/registry/cache/*
    rm -rf ~/.cargo/git/checkouts/*
fi

echo "==> Cleaning Docker (if you use it)..."
if command -v docker &> /dev/null; then
    docker system prune -af --volumes 2>/dev/null || true
fi

echo "==> Removing broken symlinks..."
find ~ -xtype l -delete 2>/dev/null || true

echo "==> Updating system databases..."
sudo updatedb
# sudo mandb
echo "==> Disk usage summary:"
df -h / /home 2>/dev/null || df -h /

# Clean browser caches (Firefox example - will log you out)
# rm -rf ~/.mozilla/firefox/*.default*/cache2/*

# Clean old kernels (keep only current + 1 backup)
sudo pacman -R $(pacman -Qq | grep 'linux[0-9]' | grep -v "$(uname -r | cut -d'-' -f1)")

# Find large files you might not need
find ~ -type f -size +100M -exec ls -lh {} \; 2>/dev/null

echo "✓ System maintenance complete!"
