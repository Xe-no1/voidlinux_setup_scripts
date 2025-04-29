#!/bin/bash

sed -i '/Color/s/^#//g' /etc/pacman.conf

pacman-key --init
pacman-key --populate
archlinux-keyring-wkd-sync

ln -sf /usr/share/zoneinfo/Asia/Qatar /etc/localtime
hwclock --systohc

sed -i '/en_US.UTF-8 UTF-8/s/^#//g' /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" >> /etc/locale.conf

echo "FONT=ter-132n" >> /etc/vconsole.conf

echo "archlinux" >> /etc/hostname

echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1 localhost" >> /etc/hosts
echo "127.0.1.1 archlinux" >> /etc/hosts

pacman -S grub efibootmgr sudo terminus-font

grub-install --efi-directory=/boot --bootloader-id=GRUB

grub-mkconfig -o /boot/grub/grub.cfg

passwd

useradd -m -g users -G wheel,storage,power,video,audio,input mazentech
passwd mazentech

export EDITOR=nvim 
visudo

systemctl enable NetworkManager

mkinitcpio -P

echo "Now please exit by `exit` and unmount all drives by `umount -R /mnt`!"
