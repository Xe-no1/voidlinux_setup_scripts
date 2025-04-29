#!/bin/bash

sudo pacman -Syu

sudo pacman -S xdg-user-dirs
xdg-user-dirs-update

cd $HOME && mkdir aur
cd aur
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

sudo pacman -S spice-vdagent xf86-video-qxl

sudo pacman -S pavucontrol
sudo pacman -S alsa-utils alsa-plugins
sudo pacman -S pipewire wireplumber

sudo pacman -S ntp
sudo systemctl enable ntpd
timedatectl set-ntp true

sudo pacman -S hyprland hyprpaper hyprlock hypridle
yay -S wlogout

yay -S bibata-cursor-theme-bin

sudo pacman -S sway swaybg swayidle

sudo pacman -S foot wmenu grim

sudo pacman -S noto-fonts ttf-opensans ttf-jetbrains-mono-nerd
sudo pacman -S noto-fonts-emoji

sudo pacman -S zsh

sudo pacman -S alacritty kitty

sudo pacman -S wofi

sudo pacman -S waybar

sudo pacman -S brightnessctl

sudo pacman -S yazi nemo

sudo pacman -S firefox

yay -S hyprshot

sudo pacman -S gnome-themes-extra

gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

sudo pacman -S rust

sudo pacman -S bottom curl fastfetch fzf gzip htop lazygit starship tar tmux unzip wget
sudo pacman -S tree-sitter tree-sitter-cli
sudo pacman -S bat eza fd ripgrep tldr
