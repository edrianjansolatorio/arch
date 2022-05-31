#!/bin/bash

source ./settings.conf

# --- root installation -------- #

pacman -Sy --noconfirm --needed bzip2 p7zip unrar
pacman -Sy --noconfirm --needed git
pacman -Sy --noconfirm --needed firefox
# pacman -Sy --noconfirm --needed gimp

if [ "$DESKTOP" == "KDE" ]; then
    # important apps
    pacman -Sy --noconfirm kwrite ark dolphin kwallet konsole latte-dock

    # bluetooth
    pacman -Sy --noconfirm pulseaudio-alsa pulseaudio-bluetooth bluez-utils bluez

    # for vscode to access login
    pacman -Sy --noconfirm gnome-keyring libsecret

    # fix sound and wifi applet
    pacman -Sy --noconfirm plasma-pa plasma-nm
fi