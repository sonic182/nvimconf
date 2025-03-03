#!/bin/bash

# Hyprland installation dependencies for Arch Linux
echo "Installing Hyprland and required dependencies..."

# Update system first
# sudo pacman -Syu --noconfirm

# Install Hyprland and core components
sudo pacman -S --needed  \
    hyprland \
    xdg-desktop-portal-hyprland \
    waybar \
    kitty \
    dunst \
    polkit-kde-agent

# Install utilities
sudo pacman -S --needed  \
    brightnessctl \
    playerctl \
    grim \
    slurp \
    wl-clipboard \
    thunar \

yay -S --needed walker-bin

# Install network utilities
sudo pacman -S --needed  \
    networkmanager \
    nm-connection-editor

# Install audio utilities
sudo pacman -S --needed  \
    pipewire \
    pipewire-pulse \
    wireplumber

# Install fonts and theming
sudo pacman -S --needed --noconfirm \
    ttf-jetbrains-mono-nerd \
    noto-fonts \
    noto-fonts-emoji

echo "Installation complete! You may need to reboot your system."
echo "Hyprland configuration files should be placed in ~/.config/hypr/"

