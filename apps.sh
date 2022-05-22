#!/bin/bash

source ./settings.conf

# --- root installation -------- #

pacman -S --noconfirm --needed bzip2 p7zip unrar
pacman -S --noconfirm --needed git
pacman -S --noconfirm --needed firefox
pacman -S --noconfirm --needed gimp

if [ "$DESKTOP" == "KDE" ]; then
    # important apps
    pacman -S --noconfirm kwrite ark dolphin kwallet konsole latte-dock

    # bluetooth
    pacman -S --noconfirm pulseaudio-alsa pulseaudio-bluetooth bluez-utils bluez

    # for vscode to access login
    pacman -S --noconfirm gnome-keyring libsecret

    # fix sound and wifi applet
    pacman -S --noconfirm plasma-pa plasma-nm
fi