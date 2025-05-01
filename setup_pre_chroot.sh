#!/usr/bin/bash

set -euxo pipefail

xbps-install -S terminus-font

setfont ter-132n

fdisk /dev/vda

mkfs.fat -F32 -n EFI /dev/vda1
mkfs.ext4 /dev/vda2

mount /dev/vda2 /mnt
mkdir -p /mnt/boot/efi
mount /dev/vda1 /mnt/boot/efi

REPO=https://repo-de.voidlinux.org/current/aarch64
ARCH=aarch64

mkdir -p /mnt/var/db/xbps/keys
cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/

XBPS_ARCH=$ARCH xbps-install -S -r /mnt -R "$REPO" base-system base-devel linux-mainline linux-firmware neovim git

xgenfstab -U /mnt >/mnt/etc/fstab

git clone https://github.com/Xe-no1/voidlinux_setup_scripts /mnt/voidlinux_setup_scripts
chmod 777 /mnt/voidlinux_setup_scripts/*

echo 'Now chroot into your new system via "xchroot /mnt /bin/bash" and execute setup_pre_reboot.sh!'
