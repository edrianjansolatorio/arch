#!/bin/bash

checkline() {
$1
read -p "continue?" confirmation
if [[ "$confirmation" != "y" ]]; then
exit 0
fi
}

./setup.sh

source ./settings.conf

timedatectl set-ntp true
timedatectl status

if [ "$BOOT_TYPE" == "EFI" ]; then

umount -A --recursive /mnt
swapoff -a
wipefs --all --force ${DISK}
sgdisk -Z ${DISK}
sgdisk -a 2048 -o ${DISK}

sgdisk -n 1::+512M --typecode=1:ef00 --change-name=1:'EFI' ${DISK} # EFI /dev/nvme0n1p1
sgdisk -n 2::-0 --typecode=2:8e00 --change-name=2:'ROOT' ${DISK} # FILE SYSTEM /dev/nvme0n1p3

NEW_DISK=${DISK}${DISK_PREFIX}

mkfs.fat -F32 ${NEW_DISK}1

# ------------- DEBUG: ENCRYPT SET-UP ------------------- #

# "shingha" <--- custom name

STORAGE_NAME=shingha
VOLGROUP=scrubs

echo -n "${PASSWORD}" | cryptsetup -y -v luksFormat ${NEW_DISK}2 -
echo -n "${PASSWORD}" | cryptsetup open --type luks ${NEW_DISK}2 ${STORAGE_NAME} -

if [[ ! "/dev/mapper/${STORAGE_NAME}" ]]; then
	exit 0
fi

pvcreate /dev/mapper/${STORAGE_NAME}
vgcreate ${VOLGROUP} /dev/mapper/${STORAGE_NAME}
lvcreate -L2G ${VOLGROUP} -n SWAP
lvcreate -l 100%FREE ${VOLGROUP} -n ROOT

mkfs.ext4 /dev/mapper/${VOLGROUP}-ROOT
mkswap /dev/mapper/${VOLGROUP}-SWAP
mount /dev/mapper/${VOLGROUP}-ROOT /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
swapon /dev/mapper/${VOLGROUP}-SWAP

# ------------- DEBUG: ENCRYPT SET-UP ------------------- #


elif [ "$BOOT_TYPE" == "LEGACY" ]; then

umount -A --recursive /mnt
swapoff -a
wipefs --all --force ${DISK}
sgdisk -Z ${DISK}
sgdisk -a 2048 -o ${DISK}

sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BOOT' ${DISK} # BOOT /dev/nvme0n1p1
sgdisk -n 2::+2g --typecode=2:8200 --change-name=2:'SWAP' ${DISK} # SWAP /dev/nvme0n1p2
sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK} # FILE SYSTEM /dev/nvme0n1p3

sgdisk -A 1:set:2 ${DISK}

NEW_DISK=${DISK}${DISK_PREFIX}

echo "Y" | mkfs.ext2 ${NEW_DISK}1
echo "Y" | mkfs.ext4 ${NEW_DISK}3
mkswap ${NEW_DISK}2

mount ${NEW_DISK}3 /mnt
fi

fdisk -l
lsblk

# @@@ #
# cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
# reflector --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
# @@@ #

# -- debugging -- #

pacstrap -i /mnt --needed --noconfirm base base-devel linux linux-firmware archlinux-keyring git
pacstrap -i /mnt --needed --noconfirm grub

if [ "$BOOT_TYPE" == "EFI" ]; then
pacstrap -i /mnt --needed --noconfirm efibootmgr
fi

genfstab -U -p /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

# ----------------- KDE ------------------ #

# @@@ #
# pacstrap -i /mnt --needed --noconfirm networkmanager dhcpcd dhclient netctl dialog iwd
# @@@ #

if [ "$DESKTOP" == "KDE" ]; then

echo "kde desktop"

### OPTION-1

# @@@ #
# pacstrap -i /mnt --needed --noconfirm xorg plasma-desktop plasma-wayland-session sddm
# @@@ #

fi

# ---------------- GPU ------------------- #

if [ "$GPU_TYPE" == "NVIDIA" ]; then

echo "nvidia"

# @@@ #
# pacstrap -i /mnt --needed --noconfirm cuda lib32-libvdpau lib32-nvidia-utils lib32-opencl-nvidia libvdpau libxnvctrl nvidia-settings nvidia-utils opencl-nvidia nvidia-dkms
# @@@ #
fi

# ---------------- GPU ------------------- #

cp /etc/pacman.d/mirrorlist.bak /etc/pacman.d/mirrorlist

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


cp ./chroot.sh /mnt
cp ./apps.sh /mnt
cp ./settings.conf /mnt

arch-chroot /mnt /chroot.sh

# umount -R /mnt