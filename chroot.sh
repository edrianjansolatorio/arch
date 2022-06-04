#!/bin/bash

DEBUG=true

checkline() {
$1
read -p "continue?: " confirmation
if [[ "$confirmation" != "y" ]]; then
exit 0
fi
}

cat /etc/systemd/system/battery-charge-threshold.service
read -p ""

source ./settings.conf

locale-gen
locale > /etc/locale.conf

hwclock --systohc --utc

echo "root:${PASSWORD}" | chpasswd
useradd -m $USERNAME
echo "$USERNAME:${PASSWORD}" | chpasswd

whereis sudo
usermod -aG wheel,audio,video,optical,storage $USERNAME
groups $USERNAME

# ---------------- DEBUG AREA ------------------ #

if [ "$INSTALL_TYPE" == "BASIC-GUI" ]; then

./apps.sh

fi
# ---------------- DEBUG AREA ------------------ #

# ---------- G14 kernel ---------- #

if [ "$INSTALL_TYPE" == "BASIC-GUI" ]; then

pacman -Syu

pacman -Sy --noconfirm --needed asusctl supergfxctl

systemctl enable supergfxd
systemctl enable power-profiles-daemon.service
systemctl --user enable asus-notify.service
systemctl enable battery-charge-threshold.service

fi

# ---------- G14 kernel ---------- #

# ----------- RUN SERVICES -------------- #

if [ "$DEBUG" = true ] ; then

systemctl enable NetworkManager
systemctl enable dhcpcd
systemctl enable iwd.service

fi

if [ "$INSTALL_TYPE" == "BASIC-GUI" ] && [ "$DESKTOP" == "KDE" ]; then

echo "SDDM service"
systemctl enable sddm.service
systemctl enable bluetooth

fi

# ---------------- GPU ------------------- #

if [ "$INSTALL_TYPE" == "BASIC-GUI" ] && [ "$GPU_TYPE" == "NVIDIA" ]; then
echo "nvidia"

pacman -Sy --needed --noconfirm cuda lib32-libvdpau lib32-nvidia-utils lib32-opencl-nvidia libvdpau libxnvctrl nvidia-settings nvidia-utils opencl-nvidia nvidia-dkms

fi

# ---------------- GPU ------------------- #

if [ "$INSTALL_TYPE" == "BASIC-GUI" ]; then

echo "install G14 kernel"
pacman -Sy --noconfirm --needed linux-g14 linux-g14-headers

fi

# ---------- RUN SERVICES ------------ #

if [ "$BOOT_TYPE" == "EFI" ]; then

# ---------- ENCRYPT SET-UP ---------- #
# "shingha" <--- custom name

pacman -Sy --noconfirm --needed lvm2
sed -r -i 's/(HOOKS=)\((.*?)\)/\1(base udev autodetect modconf block keyboard encrypt lvm2 filesystems fsck)/g' /etc/mkinitcpio.conf
cat /etc/mkinitcpio.conf

mkinitcpio -p linux
bootctl --path=/boot/ install

echo "
default arch
timeout 3
editor 0
" > /boot/loader/loader.conf

cat /boot/loader/loader.conf

DISK_ID=$(blkid /dev/nvme0n1p2 | awk '{print $2}' | sed -r -e 's/(UUID=")(.*?)"/\2/g')


echo "
title ${GRUB_TITLE}
linux /vmlinuz-linux-g14
initrd /initramfs-linux-g14.img
options cryptdevice=UUID=${DISK_ID}:volume root=/dev/mapper/${USERNAME}-ROOT quiet rw
" > /boot/loader/entries/arch.conf

cat /boot/loader/entries/arch.conf

# ---------- ENCRYPT SET-UP ---------- #

elif [ "$BOOT_TYPE" == "LEGACY" ]; then
mkdir /mnt/boot
mount ${NEW_DISK}1 /boot
swapon ${NEW_DISK}2
grub-install --boot-directory=/boot ${DISK}
grub-mkconfig -o /boot/grub/grub.cfg
fi