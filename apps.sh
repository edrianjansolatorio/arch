#!/bin/bash

source ./settings.conf

# --- root installation -------- #

pacman -S --noconfirm bzip2 p7zip unrar
pacman -S --noconfirm git

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

pacman -S --noconfirm firefox

pacman -S --noconfirm gimp

# ---------- RUN SERVICE ------------ #

# bluetooth
systemctl enable bluetooth

# snapcraft service
# systemctl enable --now snapd.socket