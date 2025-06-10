#!/usr/bin/bash

set -euxo pipefail

sudo xbps-install -Su
sudo xbps-install -Su

sudo xbps-install -S xdg-user-dirs
xdg-user-dirs-update

sudo xbps-install -S spice-vdagent xf86-video-qxl mesa

sudo xbps-install -S pavucontrol
sudo xbps-install -S alsa-utils alsa-plugins
sudo xbps-install -S pipewire wireplumber

sudo xbps-install -S hyprland hyprpaper hyprlock hypridle
sudo xbps-install -S wlogout

sudo xbps-install -S sway swaybg swayidle

sudo xbps-install -S wmenu grim

sudo xbps-install -S noto-fonts-cjk ttf-opensans
sudo xbps-install -S noto-fonts-emoji

sudo xbps-install -S alacritty kitty

sudo xbps-install -S yazi nautilus

sudo xbps-install -S firefox

sudo xbps-install -S gnome-themes-extra

gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

sudo xbps-install -S bottom curl fastfetch fzf gzip btop lazygit starship tar tmux unzip wget
sudo xbps-install -S tree-sitter
sudo xbps-install -S bat eza fd ripgrep tldr

sudo ln -sf /home/mazentech/linux_dotfiles/* /home/mazentech/.config/

sudo xbps-reconfigure -fa

echo 'Now reboot the system with "sudo shutdown -r now" to apply the changes'
