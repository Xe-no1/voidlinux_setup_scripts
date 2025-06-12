#!/usr/bin/bash

set -euo pipefail

xbps-install -Su
xbps-install -u xbps

xbps-install -S gptfdisk parted
xbps-install -S terminus-font

setfont ter-132n

echo "Warning!!! Wiping the disk in 5 seconds, press ctrl+c to interrupt."
echo "5"
sleep 1
echo "4"
sleep 1
echo "3"
sleep 1
echo "2"
sleep 1
echo "1"
sleep 1
echo "Wiping now"

# disk partitioning, note that `C12A7328-F81F-11D2-BA4B-00A0C93EC93B` is the GUID for an EFI system
# `B921B045-1DF0-41C3-AF44-4C6F280D3FAE` is the GUID for a Linux ARM64 root
# and `4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709` is the GUID for a Linux x86-64 root
# visit 'https://en.wikipedia.org/wiki/GUID_Partition_Table#Partition_type_GUIDs' for other GUID's

if mountpoint -q /mnt; then
  umount -AR /mnt # make sure everything is unmounted before we start
fi

# using sgdisk
testsgdisk() {
  sgdisk --zap-all /dev/sda                                             # zap all on disk
  sgdisk --set-alignment 2048 --clear /dev/sda                          # new gpt disk 2048 alignment
  sgdisk --new=1::+64M --typecode=1:ef00 --change-name=1:'esp' /dev/sda # partition 1 (EFI system partition)
  sgdisk --new=2::-0 --typecode=2:8305 --change-name=2:'root' /dev/sda  # partition 2 (Root partition), default start, remaining

  partprobe /dev/sda # reread partition table to ensure it is correct
}

mkfs.vfat /dev/sda1
mkfs.ext4 /dev/sda2

mount /dev/sda2 /mnt
mkdir -p /mnt/efi
mount /dev/sda1 /mnt/efi

case $(uname --machine) in
aarch64) REPO=https://repo-de.voidlinux.org/current/aarch64 ;;
*) REPO=https://repo-de.voidlinux.org/current ;;
esac

ARCH=$(uname --machine)

mkdir -p /mnt/var/db/xbps/keys
cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/

XBPS_ARCH=$ARCH xbps-install -S -r /mnt -R "$REPO" base-system base-devel linux-mainline linux-firmware

xgenfstab -U /mnt >/mnt/etc/fstab

###############################

chrootcmds() {
  xbps-install -Su
  xbps-install -u xbps

  sed -i 's/^#FONT="lat9w-16"/FONT="ter-132n"/' /etc/sudoers

  ln -sf /usr/share/zoneinfo/Asia/Qatar /etc/localtime

  sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/sudoers
  xbps-reconfigure -f glibc-locales

  echo "LANG=en_US.UTF-8" >>/etc/locale.conf

  echo "voidlinux" >/etc/hostname

  cat <<EOF >/etc/hosts
#
# /etc/hosts: static lookup table for host names
#
127.0.0.1        localhost
::1              localhost
127.0.1.1        myhostname.localdomain myhostname
EOF

  echo "Enter the root password"
  passwd

  echo "Enter the username of choice:"
  read -r username

  useradd "$username"

  echo "Enter the password of $username:"
  passwd "$username"

  echo "Do you want $username to be a sudo capable user? [Y/n]"
  read -r answer

  case "$answer" in
  "n" | "N" | "no" | "No" | "NO") usermod -aG storage,video,audio "$username" ;;
  *) usermod -aG wheel,storage,video,audio "$username" ;;
  esac

  chsh -s /bin/bash root

  # Add sudo rights
  sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
  sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

  xbps-install -S
  xbps-install void-repo-nonfree
  echo repository=https://raw.githubusercontent.com/Makrennel/hyprland-void/repository-aarch64-glibc | tee /etc/xbps.d/hyprland-void.conf
  xbps-install -S

  xbps-install -S grub-arm64-efi

  grub-install --target=arm64-efi --efi-directory=/efi --bootloader-id="Void"

  xbps-install NetworkManager elogind chrony openssh terminus-font fastfetch curl tar python
  ln -s /etc/sv/dbus /etc/runit/runsvdir/default/
  ln -s /etc/sv/NetworkManager /etc/runit/runsvdir/default/
  ln -s /etc/sv/sshd /etc/runit/runsvdir/default/
  ln -s /etc/sv/chrony /etc/runit/runsvdir/default/

  xbps-install -S spice-vdagent xf86-video-qxl mesa

  xbps-install -S pavucontrol
  xbps-install -S alsa-utils alsa-plugins
  xbps-install -S pipewire

  xbps-install -S hyprland hyprpaper

  xbps-install -S sway swaybg

  xbps-install -S noto-fonts-cjk ttf-opensans
  xbps-install -S noto-fonts-emoji

  xbps-install -S tofi

  xbps-install -S Waybar

  xbps-install -S alacritty kitty ghostty

  xbps-install -S yazi nemo

  xbps-install -S firefox

  xbps-install -S lxappearance nwg-look qt6ct qt5ct gnome-themes-extra breeze breeze-gtk

  gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

  xbps-install -S git curl wget neovim fastfetch fzf gzip btop
  xbps-install -S bat eza fd ripgrep tldr

  git clone https://codeberg.org/mazentech/linux_dotfiles.git /home/"$username"/linux_dotfiles

  ln -sf /home/"$username"/linux_dotfiles/* /home/"$username"/.config/

  xbps-install -Su
  xbps-install -u xbps

  xbps-reconfigure -fa
}

xchroot /mnt chrootcmds

if mountpoint -q /mnt; then
  umount -AR /mnt # make sure everything is unmounted before we start
fi

echo 'Installation completed succesfully! Run "shutdown -r now" to reboot into the new system and kernel.'
