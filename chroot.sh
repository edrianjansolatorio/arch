#!/bin/bash

checkline() {
$1
read -p "continue?" confirmation
if [[ "$confirmation" != "y" ]]; then
exit 0
fi
}

source ./settings.conf

sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
ln -sf /mnt/usr/share/zoneinfo/Asia/Manila /etc/localtime
locale-gen
hwclock --systohc --utc

echo -n "${PASSWORD}" | passwd root -
useradd -m $USERNAME
echo -n "${PASSWORD}" | passwd $USERNAME -

whereis sudo
usermod -aG wheel,audio,video,optical,storage $USERNAME
groups $USERNAME

# ---------------- DEBUG AREA ------------------ #

# @@@ #
# ./apps.sh
# @@@ #

# ---------------- DEBUG AREA ------------------ #

# ---------- G14 kernel ---------- #

# @@@ #

# echo "[Unit]
# Description=Set the battery charge threshold
# After=multi-user.target
# StartLimitBurst=0

# [Service]
# Type=oneshot
# Restart=on-failure
# ExecStart=/bin/bash -c 'echo 60 > /sys/class/power_supply/BAT1/charge_control_end_threshold'

# [Install]
# WantedBy=multi-user.target" >> /etc/systemd/system/battery-charge-threshold.service

# pacman -Syu

# pacman -Sy --noconfirm --needed asusctl supergfxctl linux-g14 linux-g14-headers

# systemctl enable supergfxd
# systemctl enable power-profiles-daemon.service
# systemctl --user enable asus-notify.service
# systemctl enable battery-charge-threshold.service

# @@@ #

# ---------- G14 kernel ---------- #

# ----------- RUN SERVICES -------------- #

systemctl enable NetworkManager
systemctl enable dhcpcd
systemctl enable iwd.service

if [ "$DESKTOP" == "KDE" ]; then
systemctl enable sddm.service
fi

systemctl enable bluetooth

# ---------- RUN SERVICES ------------ #

# ---------- ENCRYPT SET-UP ---------- #
# "shingha" <--- custom name

STORAGE_NAME=shingha
VOLGROUP=scrubs

sed -i 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck encrypt lvm2)/g' /etc/mkinitpcio.conf

checkline "cat /etc/mkinitcpio.conf"

mkinitcpio -p linux
bootctl --path=/boot/ install

checkline

echo "
default arch
timeout 3
editor 0
" > /etc/loader/loader.conf

checkline "cat /etc/loader/loader.conf"

# blkid /dev/${DISK}${DISK_PREFIX}2

# echo "
# title Shingha System
# linux /vmlinuz-linux
# initrd /initramfs-linux.img
# options cryptdevice=UUID=
# "

exit 0

# ---------- ENCRYPT SET-UP ---------- #

if [ "$BOOT_TYPE" == "EFI" ]; then
    mkdir /boot/efi
    mount ${DISK}${DISK_PREFIX}1 /boot/efi
    grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
    grub-mkconfig -o /boot/grub/grub.cfg
    mkdir /boot/efi/EFI/BOOT
    cp /boot/efi/EFI/GRUB/grubx64.efi /boot/efi/EFI/BOOT/BOOTX64.EFI
    echo 'bcf boot add 1 fs0:\EFI\GRUB\grubx64.efi "My GRUB bootloader"' >> /boot/efi/startup.nsh
    echo 'exit' >> /boot/efi/startup.nsh
elif [ "$BOOT_TYPE" == "LEGACY" ]; then
    mkdir /mnt/boot
    mount ${NEW_DISK}1 /boot
    swapon ${NEW_DISK}2
    grub-install --boot-directory=/boot ${DISK}
    grub-mkconfig -o /boot/grub/grub.cfg
fi