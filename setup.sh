#!/bin/bash

checkline() {
$1
read -p "continue?" confirmation
if [[ "$confirmation" != "y" ]]; then
exit 0
fi
}

reset () {
echo -e "
DESKTOP=
DISK=
DISK_PREFIX=
BOOT_TYPE=
USERNAME=
PASSWORD=
GPU_TYPE=
HOST_NAME=
GRUB_TITLE=
INSTALL_TYPE=
" > ./settings.conf
}

update_settings () {
sed -i 's/$1=/$1=$2/g' ./settings.conf
}

reset

# disk_list=$(lsblk -n --output TYPE,KNAME,SIZE | awk '$1=="disk"{print "/dev/"$2"|"$3}')
desktop_list=('KDE')

choosed_disk=
username=
password=
boot=
gpu=
desktop=
host_name=
install_type=

declare -a disk=()
declare -i index=0

# [BEGIN]-GET GPU #

if grep -E "NVIDIA|GeForce" <<< $(lspci); then
gpu=NVIDIA
update_settings "GPU_TYPE" "$gpu"
elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
gpu=AMD
update_settings "GPU_TYPE" "$gpu"
elif grep -E "Integrated Graphics Controller" <<< $(lspci); then
gpu=INTEL_GRAPHICS
update_settings "GPU_TYPE" "$gpu"
elif grep -E "Intel Corporation UHD" <<< $(lspci); then
gpu=INTEL_UHD
update_settings "GPU_TYPE" "$gpu"
else
gpu=--
update_settings "GPU_TYPE" "$gpu"
fi
# [END]-GET GPU #

# [BEGIN]-GET BOOT_TYPE #

if [[ -d "/sys/firmware/efi" ]]; then
boot=EFI
update_settings "BOOT_TYPE" "$boot"
else
boot=LEGACY
update_settings "BOOT_TYPE" "$boot"
fi

# [END]-GET BOOT_TYPE #

echo -e ""

disk_list=$(lsblk -n --output TYPE,KNAME,SIZE | awk '$1=="disk"{print "/dev/"$2}')

if [[ "$disk_list" == *"nvme0n1"* ]]; then
update_settings "DISK_PREFIX" "p"
fi

for i in $disk_list
do
index+=1
echo "$index. $i"
done

disk_list=$(lsblk -n --output TYPE,KNAME,SIZE | awk '$1=="disk"{print "\\/dev\\/"$2}')

for i in $disk_list
do
index+=1
disk+=($i)
done
echo -e ""
read -p "CHOOSE DISK: " $disk_choose
read -p "HOST_NAME: " host_name
read -p "USERNAME: " user
read -sp "PASSWORD: " pass
echo -e ""
read -p "GRUB_TITLE: " grub_title

echo "
0: basic
1: basic/gui
"
read -p "INSTALL_TYPE: " select_install_type

if [ "$select_install_type" == "1" ]; then

install_type="BASIC-GUI"
echo -e ""

index=0

for i in $desktop_list
do
index+=1
echo "$index. $i"
done

echo -e ""

echo "INSTALL_TYPE IS BASIC/GUI"
read -p "CHOOSE DESKTOP ENVIRONMENT: " desktop_environment
desktop=${desktop_list[$desktop_environment - 1]}

fi

install_type="BASIC"
echo "INSTALL_TYPE IS BASIC"
desktop="--"

choosed_disk=${disk[$disk_choose - 1]}
username=$user
password=$pass

update_settings "DISK" "$choosed_disk"
update_settings "HOST_NAME" "$host_name"
update_settings "USERNAME" "$username"
update_settings "PASSWORD" "$password"
update_settings "GRUB_TITLE" "\"$grub_title\""
update_settings "INSTALL_TYPE" "$install_type"
update_settings "DESKTOP" "$desktop"

index=0

for i in $desktop_list
do
index+=1
echo "$index. ${i}"
done

checkline "cat ./settings.conf"