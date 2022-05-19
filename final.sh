#!/bin/bash

if [ ! '$(ls ./pikaur)' ]; then
git clone https://aur.archlinux.org/pikaur.git
cd ./pikaur
makepkg -si <<EOF
Y
Y
Y
EOF
fi

# pikaur -S --noconfirm visual-studio-code-bin skypeforlinux-stable-bin brave beekeeper-studio-bin wps-office slack-desktop
pikaur -S --noconfirm snapd
pikaur -S --noconfirm gitahead

# snapcraft
ln -s /var/lib/snapd/snap /snap
systemctl enable --now snapd.service

# -------- SNAP CRAFT ------------ #

snap install beekeeper-studio
snap install brave
snap install code --classic
# snap install firefox
# snap install gimp
snap install skype
snap install slack
snap install wps-2019-snap