#!/usr/bin/bash

set -euxo pipefail

xbps-install -Su
xbps-install -Su

xbps-install -S terminus-font

setfont ter-132n

umount -A --recursive /mnt # make sure everything is unmounted before we start

# disk prep
sgdisk -Z ${DISK} # zap all on disk
sgdisk -a 2048 -o ${DISK} # new gpt disk 2048 alignment

# create partitions
sgdisk -n 1::+300M --typecode=2:ef00 --change-name=2:'EFIBOOT' ${DISK} # partition 1 (UEFI Boot Partition)
sgdisk -n 2::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK} # partition 2 (Root), default start, remaining
partprobe ${DISK} # reread partition table to ensure it is correct

mkfs.fat -F32 -n EFI /dev/sda1
mkfs.ext4 /dev/sda2

mount /dev/sda2 /mnt
mkdir -p /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi

REPO=https://repo-de.voidlinux.org/current/aarch64
ARCH=aarch64

mkdir -p /mnt/var/db/xbps/keys
cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/

XBPS_ARCH=$ARCH xbps-install -S -r /mnt -R "$REPO" base-system base-devel linux-mainline linux-firmware neovim git

xgenfstab -U /mnt >/mnt/etc/fstab

echo 'Now chroot into your new system via "xchroot /mnt /bin/bash" and execute setup_pre_reboot.sh!'

###############################

chroot () {
  xbps-install -Su
  xbps-install -Su

  nvim /etc/rc.conf

  ln -sf /usr/share/zoneinfo/Asia/Qatar /etc/localtime

  nvim /etc/default/libc-locales
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

  passwd

  useradd mazentech
  passwd mazentech
  usermod -aG wheel,storage,video,audio mazentech

  chsh -s /bin/bash root

  # Add sudo no password rights
  sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
  sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

  xbps-install -S
  xbps-install void-repo-nonfree
  echo repository=https://raw.githubusercontent.com/Makrennel/hyprland-void/repository-aarch64-glibc | tee /etc/xbps.d/hyprland-void.conf
  xbps-install -S

  xbps-install -S grub-arm64-efi

  grub-install --target=arm64-efi --efi-directory=/boot/efi --bootloader-id="Void"

  xbps-install NetworkManager elogind chrony openssh terminus-font fastfetch curl tar python
  ln -s /etc/sv/dbus /etc/runit/runsvdir/default/
  ln -s /etc/sv/NetworkManager /etc/runit/runsvdir/default/
  ln -s /etc/sv/sshd /etc/runit/runsvdir/default/
  ln -s /etc/sv/chrony /etc/runit/runsvdir/default/

  xbps-install -S xdg-user-dirs
  xdg-user-dirs-update

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

  xbps-install -S lxappearance qt6ct gnome-themes-extra breeze breeze-gtk

  gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

  xbps-install -S bottom curl fastfetch fzf gzip btop lazygit starship tar tmux unzip wget
  xbps-install -S tree-sitter
  xbps-install -S bat eza fd ripgrep tldr

  git clone https://github.com/Xe-no1/linux_dotfiles /home/mazentech/linux_dotfiles

  ln -sf /home/mazentech/linux_dotfiles/* /home/mazentech/.config/

  xbps-install -Su
  xbps-install -Su

  xbps-reconfigure -fa
}

xchroot /mnt chroot

echo 'Now please exit by "exit" and unmount all drives by "umount -R /mnt"!'
