#!/usr/bin/bash

set -euo pipefail

exec > >(tee -i /var/log/voidlinux_setup.log)
exec 2>&1

#####################################################################

echo -ne "
-------------------------------------------------------------------------
 █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗
██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝
███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗
██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║
██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
-------------------------------------------------------------------------
                    Automated Void Linux Installer
-------------------------------------------------------------------------

Verifying Void Linux ISO is Booted

"

if [ ! -f /usr/bin/xbps-install ]; then
  echo "This script must be run from a Void Linux ISO environment."
  exit 1
fi

root_check() {
  if [[ "$(id -u)" != "0" ]]; then
    echo -ne "ERROR! This script must be run under the 'root' user!\n"
    exit 0
  fi
}

docker_check() {
  if awk -F/ '$2 == "docker"' /proc/self/cgroup | read -r; then
    echo -ne "ERROR! Docker container is not supported (at the moment)\n"
    exit 0
  elif [[ -f /.dockerenv ]]; then
    echo -ne "ERROR! Docker container is not supported (at the moment)\n"
    exit 0
  fi
}

background_checks() {
  root_check
  docker_check
}

select_option() {
  local options=("$@")
  local num_options=${#options[@]}
  local selected=0
  local last_selected=-1

  while true; do
    # Move cursor up to the start of the menu
    if [ $last_selected -ne -1 ]; then
      echo -ne "\033[${num_options}A"
    fi

    if [ $last_selected -eq -1 ]; then
      echo "Please select an option using the arrow keys and Enter:"
    fi
    for i in "${!options[@]}"; do
      if [ "$i" -eq $selected ]; then
        echo "> ${options[$i]}"
      else
        echo "  ${options[$i]}"
      fi
    done

    last_selected=$selected

    # Read user input
    read -rsn1 key
    case $key in
    $'\x1b') # ESC sequence
      read -rsn2 -t 0.1 key
      case $key in
      '[A') # Up arrow
        ((selected--))
        if [ $selected -lt 0 ]; then
          selected=$((num_options - 1))
        fi
        ;;
      '[B') # Down arrow
        ((selected++))
        if [ $selected -ge $num_options ]; then
          selected=0
        fi
        ;;
      esac
      ;;
    '') # Enter key
      break
      ;;
    esac
  done

  return $selected
}

logo() {
  # This will be shown on every set as user is progressing
  echo -ne "
-------------------------------------------------------------------------
 █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗
██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝
███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗
██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║
██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
------------------------------------------------------------------------
            Please select presetup settings for your system
------------------------------------------------------------------------
"
}

filesystem() {
  echo -ne "
    Please Select your file system for both boot and root
    "
  options=("btrfs" "ext4" "exit")
  select_option "${options[@]}"

  case $? in
  0) export FS=btrfs ;;
  1) export FS=ext4 ;;
  2) exit ;;
  *)
    echo "Wrong option please select again"
    filesystem
    ;;
  esac
}

libc() {
  echo -ne "
    Please Select your choice of standard c library
    "
  options=("glibc" "musl-libc" "exit")
  select_option "${options[@]}"

  case $? in
  0) export LIBC=glibc ;;
  1) export LIBC=musl ;;
  2) exit ;;
  *)
    echo "Wrong option please select again"
    libc
    ;;
  esac
}

timezone() {
  # Added this from arch wiki https://wiki.archlinux.org/title/System_time
  time_zone="$(curl --fail https://ipapi.co/timezone)"
  echo -ne "
    System detected your timezone to be '$time_zone' \n"
  echo -ne "Is this correct?
    "
  options=("Yes" "No")
  select_option "${options[@]}"

  case ${options[$?]} in
  y | Y | yes | Yes | YES)
    echo "${time_zone} set as timezone"
    export TIMEZONE=$time_zone
    ;;
  n | N | no | NO | No)
    echo "Please enter your desired timezone e.g. Europe/London :"
    read -r new_timezone
    echo "${new_timezone} set as timezone"
    export TIMEZONE=$new_timezone
    ;;
  *)
    echo "Wrong option. Try again"
    timezone
    ;;
  esac
}

keymap() {
  echo -ne "
    Please select key board layout from this list"
  # These are default key maps as presented in official arch repo archinstall
  options=(us by ca cf cz de dk es et fa fi fr gr hu il it lt lv mk nl no pl ro ru se sg ua uk)

  select_option "${options[@]}"
  keymap=${options[$?]}

  echo -ne "Your key boards layout: ${keymap} \n"
  export KEYMAP=$keymap
}

drivessd() {
  echo -ne "
    Checking if this is an ssd
    "

  case $(/usr/bin/cat /sys/block/"${DISK}"/queue/rotational) in
  "0")
    export MOUNT_OPTIONS="rw,noatime,compress=zstd,ssd,discard=async"
    ;;
  "1")
    export MOUNT_OPTIONS="rw,noatime,compress=zstd,commit=120"
    ;;
  *)
    echo "Wrong option. Try again"
    drivessd
    ;;
  esac
}

diskpart() {
  echo -ne "
------------------------------------------------------------------------
    THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK
    Please make sure you know what you are doing because
    after formatting your disk there is no way to get data back
    *****BACKUP YOUR DATA BEFORE CONTINUING*****
------------------------------------------------------------------------

"

  PS3='
    Select the disk to install on: '
  options=($(lsblk -n --output TYPE,KNAME,SIZE | awk '$1=="disk"{print "/dev/"$2"|"$3}'))

  select_option "${options[@]}"
  disk=${options[$?]%|*}

  echo -e "\n${disk%|*} selected \n"
  export DISK=${disk%|*}

  drivessd
}

userinfo() {
  while true; do
    read -rs -p "Please enter root password: " ROOT_PASSWORD1
    echo -ne "\n"
    read -rs -p "Please re-enter root password: " ROOT_PASSWORD2
    echo -ne "\n"
    if [[ "$ROOT_PASSWORD1" == "$ROOT_PASSWORD2" ]]; then
      break
    else
      echo -ne "ERROR! Passwords do not match. \n"
    fi
  done
  export ROOT_PASSWORD=$ROOT_PASSWORD1

  # Loop through user input until the user gives a valid username
  while true; do
    read -r -p "Please enter username: " username
    if [[ "${username,,}" =~ ^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$ ]]; then
      break
    fi
    echo "Incorrect username."
  done
  export USERNAME=$username

  while true; do
    read -rs -p "Please enter password: " PASSWORD1
    echo -ne "\n"
    read -rs -p "Please re-enter password: " PASSWORD2
    echo -ne "\n"
    if [[ "$PASSWORD1" == "$PASSWORD2" ]]; then
      break
    else
      echo -ne "ERROR! Passwords do not match. \n"
    fi
  done
  export PASSWORD=$PASSWORD1

  read -pr "Do you want $USERNAME to be a sudo capable user? [Y/n]" sudo_privelidge

  # Loop through user input until the user gives a valid hostname, but allow the user to force save
  while true; do
    read -r -p "Please name your machine: " name_of_machine
    # hostname regex (!!couldn't find spec for computer name!!)
    if [[ "${name_of_machine,,}" =~ ^[a-z][a-z0-9_.-]{0,62}[a-z0-9]$ ]]; then
      break
    fi
    # if validation fails allow the user to force saving of the hostname
    read -r -p "Hostname doesn't seem correct. Do you still want to save it? (y/n)" force
    if [[ "${force,,}" = "y" ]]; then
      break
    fi
  done
  export NAME_OF_MACHINE=$name_of_machine
}

# Starting functions
background_checks
clear
logo
userinfo
clear
logo
diskpart
clear
logo
filesystem
clear
logo
timezone
clear
logo
keymap
clear
logo
libc

echo -ne "
-------------------------------------------------------------------------
                    Installing Prerequisites
-------------------------------------------------------------------------
"
xbps-install -S gptfdisk parted btrfs-progs e2fsprogs
echo -ne "
-------------------------------------------------------------------------
                    Formatting Disk
-------------------------------------------------------------------------
"

####################################################

# disk partitioning, note that `C12A7328-F81F-11D2-BA4B-00A0C93EC93B` is the GUID for an EFI system
# `B921B045-1DF0-41C3-AF44-4C6F280D3FAE` is the GUID for a Linux ARM64 root
# and `4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709` is the GUID for a Linux x86-64 root
# visit 'https://en.wikipedia.org/wiki/GUID_Partition_Table#Partition_type_GUIDs' for other GUID's

if mountpoint -q /mnt; then
  umount -AR /mnt # make sure everything is unmounted before we start
fi

# using sgdisk
sgdisk --zap-all ${DISK}                                             # zap all on disk
sgdisk --set-alignment 2048 --clear ${DISK}                          # new gpt disk 2048 alignment
sgdisk --new=1::+64M --typecode=1:ef00 --change-name=1:'esp' ${DISK} # partition 1 (EFI system partition)
sgdisk --new=2::-0 --typecode=2:8305 --change-name=2:'root' ${DISK}  # partition 2 (Root partition), default start, remaining

partprobe ${DISK} # reread partition table to ensure it is correct

# make filesystems
echo -ne "
-------------------------------------------------------------------------
                    Creating Filesystems
-------------------------------------------------------------------------
"

createsubvolumes() {
  btrfs subvolume create /mnt/@
  btrfs subvolume create /mnt/@home
  btrfs subvolume create /mnt/@snapshots
}

# @description Mount all btrfs subvolumes after root has been mounted.
mountallsubvol() {
  mount -o "${MOUNT_OPTIONS}",subvol=@home "${partition2}" /mnt/home
  mount -o "${MOUNT_OPTIONS}",subvol=@snapshots "${partition2}" /mnt/snapshots
}

# @description BTRFS subvolulme creation and mounting.
subvolumesetup() {
  # create nonroot subvolumes
  createsubvolumes
  # unmount root to remount with subvolume
  umount /mnt
  # mount @ subvolume
  mount -o "${MOUNT_OPTIONS}",subvol=@ "${partition2}" /mnt
  # make directories home, .snapshots, var, tmp
  mkdir -p /mnt/home
  mkdir -p /mnt/snapshots
  # mount subvolumes
  mountallsubvol
}

if [[ "${DISK}" =~ "nvme" ]]; then
  partition1=${DISK}p1
  partition2=${DISK}p2
else
  partition1=${DISK}1
  partition2=${DISK}2
fi

if [[ "${FS}" == "btrfs" ]]; then
  mkfs.vfat -F32 -n "esp" "${partition1}"
  mkfs.btrfs -f "${partition2}"
  mount -t btrfs "${partition2}" /mnt
  subvolumesetup
elif [[ "${FS}" == "ext4" ]]; then
  mkfs.vfat -F32 -n "esp" "${partition1}"
  mkfs.ext4 "${partition2}"
  mount -t ext4 "${partition2}" /mnt
fi

BOOT_UUID=$(blkid -s UUID -o value "${partition1}")

sync
if ! mountpoint -q /mnt; then
  echo "ERROR! Failed to mount ${partition2} to /mnt after multiple attempts."
  exit 1
fi
mkdir -p /mnt/efi
mount -t vfat -U "${BOOT_UUID}" -o rw,noatime /mnt/efi/

if ! grep -qs '/mnt' /proc/mounts; then
  echo "Drive is not mounted for some reason"
fi

echo -ne "
-------------------------------------------------------------------------
                    Void Install on Main Drive
-------------------------------------------------------------------------
"

case $(uname --machine) in
aarch64)
  REPO=https://repo-de.voidlinux.org/current/aarch64
  ARCH=aarch64
  ;;
x86_64)
  case $LIBC in
  glibc)
    REPO=https://repo-de.voidlinux.org/current
    ARCH=x86_64
    ;;
  musl)
    REPO=https://repo-de.voidlinux.org/current/musl
    ARCH=x86_64-musl
    ;;
  esac
  ;;
esac

mkdir -p /mnt/var/db/xbps/keys
cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/

case $FS in
btrfs)
  case $LIBC in
  glibc) XBPS_ARCH=$ARCH xbps-install -S -r /mnt -R "$REPO" base-system base-devel linux-mainline linux-firmware btrfs-progs ;;
  musl) XBPS_ARCH=$ARCH xbps-install -S -r /mnt -R "$REPO" base-system base-devel linux-mainline musl linux-firmware btrfs-progs ;;
  esac
  ;;
ext4)
  case $LIBC in
  glibc) XBPS_ARCH=$ARCH xbps-install -S -r /mnt -R "$REPO" base-system base-devel linux-mainline linux-firmware e2fsprogs ;;
  musl) XBPS_ARCH=$ARCH xbps-install -S -r /mnt -R "$REPO" base-system base-devel linux-mainline musl linux-firmware e2fsprogs ;;
  esac
  ;;
esac

xgenfstab -U /mnt >/mnt/etc/fstab
echo "
  Generated /etc/fstab:
"

cat /mnt/etc/fstab
echo -ne "
-------------------------------------------------------------------------
                    Checking for low memory systems <8G
-------------------------------------------------------------------------
"
TOTAL_MEM=$(grep -i 'memtotal' </proc/meminfo | grep -o '[[:digit:]]*')
if [[ $TOTAL_MEM -lt 8000000 ]]; then
  # Put swap into the actual system, not into RAM disk, otherwise there is no point in it, it'll cache RAM into RAM. So, /mnt/ everything.
  mkdir -p /mnt/opt/swap # make a dir that we can apply NOCOW to to make it btrfs-friendly.
  if findmnt -n -o FSTYPE /mnt | grep -q btrfs; then
    chattr +C /mnt/opt/swap # apply NOCOW, btrfs needs that.
  fi
  dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=2048 status=progress
  chmod 600 /mnt/opt/swap/swapfile # set permissions.
  chown root /mnt/opt/swap/swapfile
  mkswap /mnt/opt/swap/swapfile
  swapon /mnt/opt/swap/swapfile
  # The line below is written to /mnt/ but doesn't contain /mnt/, since it's just / for the system itself.
  echo "/opt/swap/swapfile    none    swap    sw    0    0" >>/mnt/etc/fstab # Add swap to fstab, so it KEEPS working after installation.
fi

gpu_type=$(lspci | grep -E "VGA|3D|Display")

############################### CHROOT COMMANDS START HERE ####################################################

xchroot /mnt /bin/bash -c "KEYMAP='${KEYMAP}' /bin/bash" <<EOCHROOT

echo -ne "
-------------------------------------------------------------------------
                    Setup Font, Language and set Locale
-------------------------------------------------------------------------
"

sed -i 's/^#FONT="lat9w-16"/FONT="ter-132n"/' /etc/rc.conf

ln -sf /usr/share/zoneinfo/"${TIMEZONE}" /etc/localtime

case $LIBC in
glibc)
  sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/default/libc-locales
  xbps-reconfigure -f glibc-locales
  ;;
musl) return ;;
esac

# Set keymaps
sed -i "s/KEYMAP=us/KEYMAP=${KEYMAP}/" > /etc/rc.conf
echo "Keymap set to: ${KEYMAP}"

# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Enable void non-free and multilib repos
xbps-install -Sy void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree

echo -ne "
-------------------------------------------------------------------------
                  Installing Microcode
-------------------------------------------------------------------------
"
# determine processor type and install microcode
if grep -q "GenuineIntel" /proc/cpuinfo; then
  echo "Installing Intel microcode"
  xbps-install -S intel-ucode
elif grep -q "AuthenticAMD" /proc/cpuinfo; then
  echo "Installing AMD microcode"
  xbps-install -S linux-firmware-amd
else
  echo "Unable to determine CPU vendor. Skipping microcode installation."
fi

echo -ne "
-------------------------------------------------------------------------
                  Installing Graphics Drivers
-------------------------------------------------------------------------
"
# Graphics Drivers find and install
if echo "${gpu_type}" | grep -E "NVIDIA|GeForce"; then
  echo "Installing NVIDIA drivers: nvidia"
  xbps-install -S nvidia
elif echo "${gpu_type}" | grep 'VGA' | grep -E "Radeon|AMD"; then
  echo "Installing AMD drivers: xf86-video-amdgpu"
  xbps-install -S xf86-video-amdgpu mesa-dri vulkan-loader mesa-vaapi mesa-vdpau mesa-vulkan-radeon amdvlk
elif echo "${gpu_type}" | grep -E "Integrated Graphics Controller"; then
  echo "Installing Intel drivers:"
  xbps-install -S mesa-dri vulkan-loader mesa-vulkan-intel intel-video-accel
elif echo "${gpu_type}" | grep -E "Intel Corporation UHD"; then
  echo "Installing Intel drivers:"
  xbps-install -S mesa-dri vulkan-loader mesa-vulkan-intel intel-video-accel
else
  echo "Installing VM drivers:"
  xbps-install -S spice-vdagent xf86-video-qxl mesa
fi

echo -ne "
-------------------------------------------------------------------------
                    Adding User
-------------------------------------------------------------------------
"
chsh -s /bin/bash root
echo "root default shell set to /bin/bash"
echo "root:$ROOT_PASSWORD" | chpasswd
echo "root password set successfully"

case "$sudo_privelidge" in
"n" | "N" | "no" | "No" | "NO") useradd -m -G storage,video,audio -s /bin/bash $USERNAME ;;
*) useradd -m -G wheel,storage,video,audio -s /bin/bash $USERNAME ;;
esac
echo "$USERNAME created, home directory created, default shell set to /bin/bash"
echo "$USERNAME:$PASSWORD" | chpasswd
echo "$USERNAME password set successfully"

echo $NAME_OF_MACHINE > /etc/hostname
echo "'$NAME_OF_MACHINE' set as hostname successfully"

cat <<EOF >/etc/hosts
#
# /etc/hosts: static lookup table for host names
#
127.0.0.1        localhost
::1              localhost
127.0.1.1        $NAME_OF_MACHINE.localdomain $NAME_OF_MACHINE
EOF
echo "/etc/hosts file setup successfully"

echo -ne "
-------------------------------------------------------------------------
 █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗
██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝
███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗
██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║
██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
-------------------------------------------------------------------------
                    Automated Arch Linux Installer
-------------------------------------------------------------------------

Final Setup and Configurations
GRUB EFI Bootloader Install & Check
"

case $(uname -m) in
aarch64)
  xbps-install -Sy grub-arm64-efi
  grub-install --target=arm64-efi --efi-directory=/efi --bootloader-id="Void"
  ;;
x86_64)
  xbps-install -Sy grub-x86_64-efi
  grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id="Void"
  ;;
esac

echo "GRUB installed succesfully"

echo -ne "
-------------------------------------------------------------------------
                    Enabling Essential Services
-------------------------------------------------------------------------
"
xbps-install -Sy NetworkManager elogind chrony openssh terminus-font fastfetch curl tar python
ln -s /etc/sv/dbus /etc/runit/runsvdir/default/
ln -s /etc/sv/NetworkManager /etc/runit/runsvdir/default/
ln -s /etc/sv/sshd /etc/runit/runsvdir/default/
ln -s /etc/sv/chrony /etc/runit/runsvdir/default/

echo "NetworkManager, dbus, chrony and sshd enabled successfully"

echo -ne "
-------------------------------------------------------------------------
                    Updating system and generating initramfs
-------------------------------------------------------------------------
"
xbps-install -Su
xbps-install -u xbps
xbps-install -Su
echo "Updated entire system successfully"

xbps-reconfigure -fa
echo "Configured system and generated initramfs successfully"
EOCHROOT

###################### UNESENTIALS ##################################################

# case $(uname -m) in
# aarch64)
#   case $LIBC in
#   glibc) echo repository=https://raw.githubusercontent.com/Makrennel/hyprland-void/repository-aarch64-glibc | tee /etc/xbps.d/hyprland-void.conf ;;
#   musl) echo repository=https://raw.githubusercontent.com/Makrennel/hyprland-void/repository-aarch64-musl | tee /etc/xbps.d/hyprland-void.conf ;;
#   esac
#   ;;
# x86_64)
#   case $LIBC in
#   glibc) echo repository=https://raw.githubusercontent.com/Makrennel/hyprland-void/repository-x86_64-glibc | tee /etc/xbps.d/hyprland-void.conf ;;
#   musl) echo repository=https://raw.githubusercontent.com/Makrennel/hyprland-void/repository-x86_64-musl | tee /etc/xbps.d/hyprland-void.conf ;;
#   esac
#   ;;
# esac
# xbps-install -S
#
# xbps-install -S pavucontrol
# xbps-install -S alsa-utils alsa-plugins
# xbps-install -S pipewire
#
# xbps-install -S hyprland hyprpaper
#
# xbps-install -S sway swaybg
#
# xbps-install -S noto-fonts-cjk ttf-opensans
# xbps-install -S noto-fonts-emoji
#
# xbps-install -S tofi
#
# xbps-install -S Waybar
#
# xbps-install -S alacritty kitty ghostty
#
# xbps-install -S yazi nemo
#
# xbps-install -S firefox
#
# xbps-install -S lxappearance nwg-look qt6ct qt5ct gnome-themes-extra breeze breeze-gtk
#
# gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
# gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
#
# xbps-install -S git curl wget neovim fastfetch fzf gzip btop
# xbps-install -S bat eza fd ripgrep tldr
#
# git clone https://codeberg.org/mazentech/linux_dotfiles.git /home/"$username"/linux_dotfiles
#
# ln -sf /home/"$username"/linux_dotfiles/* /home/"$username"/.config/

if mountpoint -q /mnt; then
  umount -AR /mnt
fi

echo 'Installation completed succesfully! Run "shutdown -r now" to reboot into the new system and kernel.'
