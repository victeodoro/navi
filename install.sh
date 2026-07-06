#!/usr/bin/env bash

set -euo pipefail

echo "==> Updating package indexes..."
sudo apt update

# Deliberately separated from package installation.
# Remove or comment this line if you do not want the script to upgrade
# the entire system every time it is executed.
echo "==> Upgrading installed packages..."
sudo apt upgrade -y

echo "==> Installing base utilities..."
sudo apt install -y \
    ca-certificates \
    curl \
    git \
    unzip \
    wget

echo "==> Installing Sway and session components..."
sudo apt install -y \
    foot \
    foot-themes \
    lxqt-policykit \
    sway \
    swaybg \
    swayidle \
    swaylock \
    waybar \
    wofi \
    xwayland

echo "==> Installing desktop portals..."
sudo apt install -y \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal-wlr

echo "==> Installing notification support..."
sudo apt install -y \
    libnotify-bin \
    mako-notifier

echo "==> Installing audio components..."
sudo apt install -y \
    libspa-0.2-bluetooth \
    pavucontrol \
    pipewire \
    pipewire-pulse \
    wireplumber

echo "==> Installing network components..."
sudo apt install -y \
    network-manager \
    network-manager-gnome

echo "==> Installing Bluetooth components..."
sudo apt install -y \
    bluez \
    blueman

echo "==> Installing screenshot and clipboard tools..."
sudo apt install -y \
    grim \
    slurp \
    wl-clipboard

echo "==> Installing hardware and media controls..."
sudo apt install -y \
    brightnessctl \
    playerctl

echo "==> Installing fonts..."
sudo apt install -y \
    fonts-noto-core \
    fonts-noto-color-emoji \
    fonts-jetbrains-mono \
    fonts-font-awesome

echo "==> Installing user applications..."
sudo apt install -y \
    firefox-esr \
    mousepad \
    nemo

echo "==> Creating standard user directories..."
sudo apt install -y xdg-user-dirs
xdg-user-dirs-update

echo
echo "Installation completed."
echo "Configure session services in ~/.config/sway/config."

cp -r ./sway ~/.config/
cp -r ./wofi ~/.config/
cp -r ./foot ~/.config/
cp -r ./waybar ~/.config/
cp -r ./wallpaper.jpg ~/Pictures
swaymsg reload
