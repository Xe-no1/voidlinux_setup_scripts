#!/usr/bin/dash

set -euxo pipefail

sudo xbps-install -Su

sudo xbps-install -S xdg-user-dirs
xdg-user-dirs-update

sudo xbps-install -S spice-vdagent mesa

sudo xbps-install -S pavucontrol
sudo xbps-install -S alsa-utils alsa-plugins
sudo xbps-install -S pipewire wireplumber

sudo xbps-install -S chrony
sudo ln -s /etc/sv/chronyd /var/service/

sudo xbps-install -S hyprland hyprpaper hyprlock hypridle
sudo xbps-install -S wlogout

curl -O -L github.com/ful1e5/Bibata_Cursor/releases/download/latest/Bibata.tar.xz
tar -xvf Bibata.tar.gz
mv Bibata-* ~/.local/share/icons/
sudo mv Bibata-* /usr/share/icons/

sudo xbps-install -S sway swaybg swayidle

sudo xbps-install -S foot wmenu grim

sudo xbps-install -S noto-fonts-cjk ttf-opensans
sudo xbps-install -S noto-fonts-emoji

sudo xbps-install -S zsh

sudo xbps-install -S alacritty kitty ghostty

sudo xbps-install -S wofi

sudo xbps-install -S waybar

sudo xbps-install -S brightnessctl

sudo xbps-install -S yazi nemo

sudo xbps-install -S firefox

sudo xbps-install -S hyprshot

sudo xbps-install -S gnome-themes-extra

gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

sudo xbps-install -S rust

sudo xbps-install -S bottom curl fastfetch fzf gzip htop lazygit starship tar tmux unzip wget
sudo xbps-install -S tree-sitter tree-sitter-cli
sudo xbps-install -S bat eza fd ripgrep tldr
