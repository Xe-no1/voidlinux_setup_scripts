#!/bin/bash

fdisk /dev/vda

mkfs.ext4 /dev/vda2
mkfs.fat -F 32 /dev/vda1

mount /dev/vda2 /mnt
mount --mkdir /dev/vda1 /mnt/boot

pacstrap -K /mnt base base-devel linux linux-firmware e2fsprogs networkmanager sof-firmware git neovim man-db man-pages texinfo archlinuxarm-keyring

genfstab -U /mnt >> /mnt/etc/fstab

echo "Now chroot into your new system via `arch-chroot /mnt` and execute `setup_pre_reboot.sh`!"
