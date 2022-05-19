#!/bin/bash

./setup.sh

source ./settings.conf

timedatectl set-ntp true
timedatectl status

umount -A --recursive /mnt
wipefs --all --force ${DISK}
sgdisk -Z ${DISK}
sgdisk -a 2048 -o ${DISK}

sgdisk -n 1::+512M --typecode=1:ef00 --change-name=1:'EFI' ${DISK} # EFI /dev/nvme0n1p1
sgdisk -n 2::+4g --typecode=2:8200 --change-name=2:'SWAP' ${DISK} # SWAP /dev/nvme0n1p2
sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK} # FILE SYSTEM /dev/nvme0n1p3

fdisk -l

NEW_DISK=${DISK}${DISK_PREFIX}

mkfs.fat -F32 ${NEW_DISK}1
mkswap ${NEW_DISK}2
swapon ${NEW_DISK}2
echo "Y" | mkfs.ext4 ${NEW_DISK}3
mount ${NEW_DISK}3 /mnt

pacstrap -i /mnt --noconfirm base base-devel linux linux-firmware archlinux-keyring git
pacstrap -i /mnt --noconfirm networkmanager dhcpcd dhclient netctl dialog iwd
pacstrap -i /mnt --noconfirm grub efibootmgr

# ----------------- KDE ------------------ #

if [ "$DESKTOP" == "KDE" ]; then
    pacstrap -i /mnt --noconfirm xorg plasma plasma-wayland-session sddm
fi

# ---------------- GPU ------------------- #

if [ "$GPU_TYPE" == "NVIDIA" ]; then
    pacstrap -i --noconfirm cuda lib32-libvdpau lib32-nvidia-utils lib32-opencl-nvidia libvdpau libxnvctrl nvidia-settings nvidia-utils opencl-nvidia nvidia-dkms
fi

genfstab -U -p /mnt >> /mnt/etc/fstab

sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /mnt/etc/locale.gen
ln -sf /mnt/usr/share/zoneinfo/Asia/Manila /mnt/etc/localtime

echo $HOST_NAME >> /mnt/etc/hostname
echo "127.0.0.1 localhost" >> /mnt/etc/hosts
echo "::1   localhost" >> /mnt/etc/hosts
echo "127.0.0.1 $HOST_NAME.localdomain  $HOST_NAME" >> /mnt/etc/hosts

sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /mnt/etc/sudoers
echo "$USERNAME ALL=(ALL) ALL" >> /mnt/etc/sudoers

cp ./chroot.sh /mnt
cp ./apps.sh /mnt
cp ./settings.conf /mnt

arch-chroot /mnt /chroot.sh

# umount -R /mnt