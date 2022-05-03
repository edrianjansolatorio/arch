### APPS ISSUE AND FIXED

```

---VIRTUAL BOX---
$ modprobe vboxdrv

---SLACK LOGIN NOT WORKING---
// use mozilla firefox

---KDE PLASMA DESKTOP NO SOUND AND WIFI INTERFACE---
$ pacman -S pulseaudio plasma-pa plasma-nm

```


### CONSTANTS

```

GPU_TYPE=
BOOT_MODE=
CLEAR_SCREEN=true
DISPLAY_INFO=true
PAUSE=true


```

### DEBUG VIEW

```
clear_screen() {
    if [ $CLEAR_SCREEN === true ]; then
        clear
    fi
}

display_info() {
    if [ $DISPLAY_INFO === true ]; then
        echo "[start]-- $title"
    fi
}

pause() {
    if [ $PAUSE === true ]; then
        read -p "[end]-- $title"
    fi
}

```

### CHECK SYSTEM

```

// check GPU

if grep -E "NVIDIA|GeForce" <<< $(lspci); then
    GPU_TYPE=NVIDIA
elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
    GPU_TYPE=AMD
elif grep -E "Integrated Graphics Controller" <<< $(lspci); then
    GPU_TYPE=INTEL_GRAPHICS
elif grep -E "Intel Corporation UHD" <<< $(lspci); then
    GPU_TYPE=INTEL_UHD
fi

// check if EFI

if [[ ! -d "/sys/firmware/efi" ]]; then
    BOOT_MODE=UEFI
else
    BOOT_MODE=LEGACY
fi

```

### 1. CHECK INTERNET

```

ping -c 5 google.com

```

### 2. SET TIMEDATECTL

```

timedatectl set-ntp true
timedatectl status

```

### 3. PARTITIONING

```
umount -A --recursive /mnt
sgdisk -Z ${DISK}
sgdisk -a 2048 -o ${DISK}

sgdisk -n 1::+512M --typecode=1:ef00 --change-name=1:'EFI' ${DISK} # EFI /dev/nvme0n1p1
sgdisk -n 2::+4g --typecode=2:8200 --change-name=2:'SWAP' ${DISK} # SWAP /dev/nvme0n1p2
sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK} # FILE SYSTEM /dev/nvme0n1p3
```

### 4. CONFIGURING DISK

```
fdisk -l
mkfs.fat -F32 /dev/${STORAGE_NAME}${STORAGE_PREFIX}1
mkswap /dev/${STORAGE_NAME}${STORAGE_PREFIX}2
swapon /dev/${STORAGE_NAME}${STORAGE_PREFIX}2
mkfs.ext4 /dev/${STORAGE_NAME}${STORAGE_PREFIX}3
```

### 5. INSTALLING FIRMWARE AND KERNEL

```
pacstrap -i /mnt base base-devel linux linux-firmware --noconfirm
```

### 6. GENFSTAB

```
genfstab -U -p /mnt >> /mnt/etc/fstab
```

### 7. COPY CHROOT.SH

```
cp ./chroot.sh /mnt
```

### 8. ARCH-CHROOT

```
arch-chroot /mnt /chroot.sh
```

### 9. TIMEZONE AND LANGUAGES

```
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
ln -sf /usr/share/zoneinfo/Asia/Manila /etc/localtime
hwclock --systohc --utc
```

### 10. SET HOSTNAME

```
echo $HOST_NAME >> /etc/hostname
echo "127.0.0.1	localhost" >> /etc/hosts
echo "::1	localhost" >> /etc/hosts
echo "127.0.0.1	$HOST_NAME.localdomain	$HOST_NAME" >> /etc/hosts
```

### 11. USERS.

```
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

sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers
echo "$USER_NAME ALL=(ALL) ALL" >> /etc/sudoers
```

### 12. INSTALL NETWORK

```
pacman -Sy networkmanager dhcpcd dhclient netctl dialog iwd nano --noconfirm
systemctl enable NetworkManager
systemctl enable dhcpcd
systemctl enable iwd.service
```

### 13. ADDS ON (OPTIONAL DEPENDS ON THE DEVICE)

// TODO
```

```

### 14. CLEAN FILES

```
rm -rvf chroot.sh
```

### 15. GRUB AND EFIBOOTMNGR

```
pacman -S --noconfirm grub efibootmgr
```

### 18. INSTALLING GRUB

```
mkdir /boot/efi
mount /dev/${STORAGE_NAME}${STORAGE_PREFIX}1 /boot/efi
lsblk
grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg
mkdir /boot/efi/EFI/BOOT
cp /boot/efi/EFI/GRUB/grubx64.efi /boot/efi/EFI/BOOT/BOOTX64.EFI
echo 'bcf boot add 1 fs0:\EFI\GRUB\grubx64.efi "My GRUB bootloader"' >> /boot/efi/startup.nsh
echo 'exit' >> /boot/efi/startup.nsh
elif [ "$TYPE" = "LEGACY" ]; then
pacman -S grub --noconfirm
grub-install /dev/${STORAGE_NAME}
grub-mkconfig -o /boot/grub/grub.cfg
fi
```