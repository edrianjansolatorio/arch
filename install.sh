#!/bin/bash

debug () {
$1
read -p "debugging"
}

./setup.sh

source ./settings.conf

timedatectl set-ntp true
timedatectl status

# cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
# reflector --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

if [ "$BOOT_TYPE" == "EFI" ]; then

umount -A --recursive /mnt
swapoff -a
wipefs --all --force ${DISK}
sgdisk -Z ${DISK}
sgdisk -a 2048 -o ${DISK}

sgdisk -n 1::+512M --typecode=1:ef00 --change-name=1:'EFI' ${DISK} # EFI /dev/nvme0n1p1
sgdisk -n 2::+4g --typecode=2:8200 --change-name=2:'SWAP' ${DISK} # SWAP /dev/nvme0n1p2
sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK} # FILE SYSTEM /dev/nvme0n1p3

NEW_DISK=${DISK}${DISK_PREFIX}

mkfs.fat -F32 ${NEW_DISK}1
mkswap ${NEW_DISK}2
swapon ${NEW_DISK}2
echo "Y" | mkfs.ext4 ${NEW_DISK}3
mount ${NEW_DISK}3 /mnt

elif [ "$BOOT_TYPE" == "LEGACY" ]; then

umount -A --recursive /mnt
swapoff -a
wipefs --all --force ${DISK}
sgdisk -Z ${DISK}
sgdisk -a 2048 -o ${DISK}

sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BOOT' ${DISK} # BOOT /dev/nvme0n1p1
sgdisk -n 2::+4g --typecode=2:8200 --change-name=2:'SWAP' ${DISK} # SWAP /dev/nvme0n1p2
sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK} # FILE SYSTEM /dev/nvme0n1p3

NEW_DISK=${DISK}${DISK_PREFIX}

echo "Y" | mkfs.ext2 ${NEW_DISK}1
echo "Y" | mkfs.ext4 ${NEW_DISK}3
mkswap ${NEW_DISK}2

mount ${NEW_DISK}3 /mnt
mkdir /mnt/boot
mount ${NEW_DISK}1 /mnt/boot
swapon ${NEW_DISK}2

fi

lsblk
fdisk -l

# -- debugging -- #

pacstrap -i /mnt --needed --noconfirm base base-devel linux linux-firmware archlinux-keyring git
pacstrap -i /mnt --needed --noconfirm networkmanager dhcpcd dhclient netctl dialog iwd

pacstrap -i /mnt --needed --noconfirm grub

if [ "$BOOT_TYPE" == "EFI" ]; then
pacstrap -i /mnt --needed --noconfirm efibootmgr
fi

# ----------------- KDE ------------------ #

if [ "$DESKTOP" == "KDE" ]; then

### OPTION-1
pacstrap -i /mnt --needed --noconfirm xorg plasma-desktop plasma-wayland-session sddm

fi

# ---------------- GPU ------------------- #

if [ "$GPU_TYPE" == "NVIDIA" ]; then
pacstrap -i /mnt --needed --noconfirm cuda lib32-libvdpau lib32-nvidia-utils lib32-opencl-nvidia libvdpau libxnvctrl nvidia-settings nvidia-utils opencl-nvidia nvidia-dkms
fi
# ---------------- GPU ------------------- #


genfstab -U -p /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /mnt/etc/locale.gen
ln -sf /mnt/usr/share/zoneinfo/Asia/Manila /mnt/etc/localtime

echo $HOST_NAME >> /mnt/etc/hostname
echo "127.0.0.1 localhost" >> /mnt/etc/hosts
echo "::1   localhost" >> /mnt/etc/hosts
echo "127.0.0.1 $HOST_NAME.localdomain  $HOST_NAME" >> /mnt/etc/hosts

sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /mnt/etc/sudoers
echo "$USERNAME ALL=(ALL) ALL" >> /mnt/etc/sudoers

sed -i "s/#\[multilib]/[multilib]/" /mnt/etc/pacman.conf
sed -i "$!N;s/\(\[multilib]\n\)#\(Include\)/\1\2/;P;D" /mnt/etc/pacman.conf

echo "
[g14]
SigLevel = DatabaseNever Optional TrustAll
Server = https://arch.asus-linux.org" >> /mnt/etc/pacman.conf

exit 0

cp ./chroot.sh /mnt
cp ./apps.sh /mnt
cp ./settings.conf /mnt

arch-chroot /mnt /chroot.sh

# umount -R /mnt