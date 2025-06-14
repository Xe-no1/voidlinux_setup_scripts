#!/usr/bin/bash

set -euo pipefail

# xbps-install -Sy gptfdisk parted
#
# echo "Warning!!! Wiping the disk in 5 seconds, press ctrl+c to interrupt."
# echo "5"
# sleep 1
# echo "4"
# sleep 1
# echo "3"
# sleep 1
# echo "2"
# sleep 1
# echo "1"
# sleep 1
# echo "Wiping now"
#
# # disk partitioning, note that `C12A7328-F81F-11D2-BA4B-00A0C93EC93B` is the GUID for an EFI system
# # `B921B045-1DF0-41C3-AF44-4C6F280D3FAE` is the GUID for a Linux ARM64 root
# # and `4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709` is the GUID for a Linux x86-64 root
# # visit 'https://en.wikipedia.org/wiki/GUID_Partition_Table#Partition_type_GUIDs' for other GUID's
#
# if mountpoint -q /mnt; then
#   umount -AR /mnt # make sure everything is unmounted before we start
# fi
#
# # using sgdisk
# sgdisk --zap-all /dev/sda                                             # zap all on disk
# sgdisk --set-alignment 2048 --clear /dev/sda                          # new gpt disk 2048 alignment
# sgdisk --new=1::+64M --typecode=1:ef00 --change-name=1:'esp' /dev/sda # partition 1 (EFI system partition)
# sgdisk --new=2::-0 --typecode=2:8305 --change-name=2:'root' /dev/sda  # partition 2 (Root partition), default start, remaining
#
# partprobe /dev/sda # reread partition table to ensure it is correct
#
# mkfs.vfat /dev/sda1
# mkfs.ext4 /dev/sda2
#
# mount /dev/sda2 /mnt
# mkdir -p /mnt/efi
# mount /dev/sda1 /mnt/efi
#
# REPO=https://repo-de.voidlinux.org/current/aarch64
#
# ARCH=aarch64
#
# mkdir -p /mnt/var/db/xbps/keys
# cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/
#
# XBPS_ARCH=$ARCH xbps-install -Sy -r /mnt -R "$REPO" base-system base-devel linux-mainline linux-firmware
#
# xgenfstab -U /mnt >/mnt/etc/fstab

###############################

# cat <<EOC >/mnt/chrootcmds

xchroot /mnt /bin/bash <<END
xbps-install -Syu
xbps-install -yu xbps

sed -i 's/^#FONT="lat9w-16"/FONT="ter-132n"/' /etc/rc.conf

ln -sf /usr/share/zoneinfo/Asia/Qatar /etc/localtime

sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/default/libc-locales
xbps-reconfigure -f glibc-locales

echo "voidlinux" >/etc/hostname

cat <<EOF >/etc/hosts
#
# /etc/hosts: static lookup table for host names
#
127.0.0.1        localhost
::1              localhost
127.0.1.1        voidlinux.localdomain voidlinux
EOF

echo "Enter the root password"
(passwd </dev/tty)

(read -pr "Enter the username of choice" username </dev/tty)
useradd "$username"

echo "Enter the password of $username:"
(passwd "$username" </dev/tty)

passwd "$username"

(read -rp "Do you want $username to be a sudo capable user? [Y/n]" answer </dev/tty)

case "$answer" in
"n" | "N" | "no" | "No" | "NO") usermod -aG storage,video,audio "$username" ;;
*) usermod -aG wheel,storage,video,audio "$username" ;;
esac

chsh -s /bin/bash root

# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

xbps-install -Sy
xbps-install -y void-repo-nonfree
(echo repository=https://raw.githubusercontent.com/Makrennel/hyprland-void/repository-aarch64-glibc | tee /etc/xbps.d/hyprland-void.conf <"Y")
xbps-install -Sy

xbps-install -Sy grub-arm64-efi

grub-install --target=arm64-efi --efi-directory=/efi --bootloader-id="Void"

xbps-install -Sy NetworkManager elogind chrony openssh terminus-font fastfetch curl tar python
ln -s /etc/sv/dbus /etc/runit/runsvdir/default/
ln -s /etc/sv/NetworkManager /etc/runit/runsvdir/default/
ln -s /etc/sv/sshd /etc/runit/runsvdir/default/
ln -s /etc/sv/chrony /etc/runit/runsvdir/default/

xbps-reconfigure -fa
END

# chmod 0755 /mnt/chrootcmds

# export -f install_func

# xchroot /mnt /bin/bash

# if mountpoint -q /mnt; then
#   umount -AR /mnt
# fi

echo 'Installation completed succesfully! Run "shutdown -r now" to reboot into the new system and kernel.'
