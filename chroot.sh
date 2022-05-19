#!/bin/bash

source ./settings.conf

# ----------- SYSTEMD -------------- #

systemctl enable NetworkManager
systemctl enable dhcpcd
systemctl enable iwd.service

if [ "$DESKTOP" == "KDE" ]; then
    systemctl enable sddm.service
fi

locale-gen
hwclock --systohc --utc

passwd << EOF
$PASSWORD
$PASSWORD
EOF

useradd -m $USERNAME
passwd scrubs << EOF
$PASSWORD
$PASSWORD
EOF

whereis sudo
usermod -aG wheel,audio,video,optical,storage $USER_NAME
groups $USER_NAME

mkdir /boot/efi
mount ${DISK}1 /boot/efi

# ---------------- DEBUG AREA ------------------ #
./apps.sh
# ---------------- DEBUG AREA ------------------ #

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

exit 0