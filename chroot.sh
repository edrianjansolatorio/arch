#!/bin/bash

source ./settings.conf

# ----------- SYSTEMD -------------- #
systemctl enable NetworkManager
systemctl enable dhcpcd
systemctl enable iwd.service

locale-gen
hwclock --systohc --utc

passwd << EOF
$ROOT_PASSWD
$ROOT_PASSWD
EOF

useradd -m $USER_NAME
passwd scrubs << EOF
$USER_PASSWD
$USER_PASSWD
EOF

whereis sudo
usermod -aG wheel,audio,video,optical,storage $USER_NAME
groups $USER_NAME

mkdir /boot/efi
mount ${DISK}1 /boot/efi

if [ "$BOOT_TYPE" = "EFI" ]; then
grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg
mkdir /boot/efi/EFI/BOOT
cp /boot/efi/EFI/GRUB/grubx64.efi /boot/efi/EFI/BOOT/BOOTX64.EFI
echo 'bcf boot add 1 fs0:\EFI\GRUB\grubx64.efi "My GRUB bootloader"' >> /boot/efi/startup.nsh
echo 'exit' >> /boot/efi/startup.nsh
elif [ "$TYPE" = "LEGACY" ]; then
grub-install ${DISK}
grub-mkconfig -o /boot/grub/grub.cfg
fi