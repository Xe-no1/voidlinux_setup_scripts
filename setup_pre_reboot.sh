#!/usr/bin/dash

set -euxo pipefail

echo "FONT=ter-132n" >>/etc/rc.conf

ln -sf /usr/share/zoneinfo/Asia/Qatar /etc/localtime

sed -i '/en_US.UTF-8 UTF-8/s/^#//g' /etc/defaults/libc-locales
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
usermod -aG wheel,storage,power,video,audio,input mazentech

chsh -s /bin/bash root
EDITOR=nvim visudo

xbps-install -S
xbps-install void-repo-nonfree
echo repository=https://raw.githubusercontent.com/Makrennel/hyprland-void/repository-aarch64-glibc | sudo tee /etc/xbps.d/hyprland-void.conf
xbps-install -S

xbps-install -S grub-arm64-efi

grub-install --target=arm64-efi --efi-directory=/boot/efi --bootloader-id="Void"

xbps-install NetworkManager terminus-font fastfetch curl tar
ln -s /etc/sv/NetworkManager /etc/runit/runsvdir/default/

xbps-reconfigure -fa

echo 'Now please exit by "exit" and unmount all drives by "umount -R /mnt"!'
