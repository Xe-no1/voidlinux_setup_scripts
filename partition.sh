#!/usr/bin/bash

set -euo pipefail

# disk partitioning, note that `C12A7328-F81F-11D2-BA4B-00A0C93EC93B` is the GUID for an EFI system
# `B921B045-1DF0-41C3-AF44-4C6F280D3FAE` is the GUID for a Linux ARM64 root
# and `4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709` is the GUID for a Linux x86-64 root
# visit 'https://en.wikipedia.org/wiki/GUID_Partition_Table#Partition_type_GUIDs' for other GUID's

# using parted
testparted() {
  wipefs -a /dev/sda
  parted -sf /dev/sda mklabel gpt
  parted -sf /dev/sda mkpart '"esp"' fat32 1MiB 65MiB
  parted -sf /dev/sda set 1 esp on
  parted -sf /dev/sda mkpart '"root"' ext4 65MiB 100%
  parted -sf /dev/sda type 2 B921B045-1DF0-41C3-AF44-4C6F280D3FAE

  partprobe /dev/sda # reread partition table to ensure it is correct

  sfdisk -d /dev/sda >>parted.sfdisk
  parted /dev/sda print >>parted.parted
}

# using sgdisk
testsgdisk() {
  sgdisk -Z /dev/sda                                                 # zap all on disk
  sgdisk -a 2048 -o /dev/sda                                         # new gpt disk 2048 alignment
  sgdisk -n 1::+64M --typecode=1:ef00 --change-name=1:'esp' /dev/sda # partition 2 (UEFI Boot Partition)
  sgdisk -n 2::-0 --typecode=2:8305 --change-name=2:'root' /dev/sda  # partition 3 (Root), default start, remaining

  partprobe /dev/sda # reread partition table to ensure it is correct

  sfdisk -d /dev/sda >>sgdisk.sfdisk
  parted /dev/sda print >>sgdisk.parted
}

# using sfdisk
testsfdisk() {
  sfdisk --delete /dev/sda
  sfdisk -w always /dev/sda <<EOF
label: gpt
/dev/sda1: start=, size=64MiB, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, name="esp"
/dev/sda2: start=, size=, type=B921B045-1DF0-41C3-AF44-4C6F280D3FAE, name="root"
EOF

  partprobe /dev/sda # reread partition table to ensure it is correct

  sfdisk -d /dev/sda >>sfdisk.sfdisk
  parted /dev/sda print >>sfdisk.parted
}

# using gdisk
testgdisk() {
  sgdisk -Z /dev/sda
  sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' <<EOF | gdisk /dev/sda
  o # create a new GPT disk label
  Y # confirm creating a new disk label
  n # new partition
  1 # partition number 1
    # default - start at beginning of disk 
  +64M # 64 MiB boot parttion
  ef00 # set partition 1 as the ESP
  c # change the PARTLABEL of partition 1
  esp # set the partlabel of partiton 1 to 'esp'
  n # new partition
  2 # partion number 2
    # default, start immediately after preceding partition
    # default, extend partition to end of disk
  8305 # set partition 2 as Linux ARM64 root
  c # change the PARTLABEL of partition 2
  2 # partition number 2
  root # set the PARTLABEL of partiton 2 to 'root'
  w # write the partition table and quit
  Y # confirm writing to the disk
EOF

  partprobe /dev/sda # reread partition table to ensure it is correct

  sfdisk -d /dev/sda >>gdisk.sfdisk
  parted /dev/sda print >>gdisk.parted
}

# using fdisk
testfdisk() {
  sfdisk --delete /dev/sda
  sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' <<EOF | fdisk /dev/sda
  g # create a new GPT disk label
  n # new partition
  1 # partition number 1
    # default - start at beginning of disk 
  +64M # 64 MiB boot partition
  t # change the type of partion
  uefi # set partition 1 as the ESP
  x # enter "expert mode"
  n # change the PARTLABEL of partition 1
  esp # set the partlabel of partiton 1 to 'esp'
  r # return back to normal mode
  n # new partition
  2 # partion number 2
    # default, start immediately after preceding partition
    # default, extend partition to end of disk
  t # change the type of partition
  2 # partition number 2
  27 # set partition 2 as Linux root (ARM64)
  x # enter "expert mode"
  n # change the PARTLABEL of partition 2
  2 # partition number 2
  root # set the PARTLABEL of partiton 2 to 'root'
  r # return back to normal mode
  w # write the partition table and quit
EOF

  partprobe /dev/sda # reread partition table to ensure it is correct

  sfdisk -d /dev/sda >>fdisk.sfdisk
  parted /dev/sda print >>fdisk.parted
}

echo "What partitioning tool would you like to test?"
echo "1 - parted"
echo "2 - sgdisk"
echo "3 - sfdisk"
echo "4 - gdisk"
echo "5 - fdisk"
read -r answer

case "$answer" in
"1") testparted ;;
"2") testsgdisk ;;
"3") testsfdisk ;;
"4") testgdisk ;;
"5") testfdisk ;;
esac
