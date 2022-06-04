#!/bin/bash

if [[ ! -d './pikaur' ]]; then
git clone https://aur.archlinux.org/pikaur.git
$(cd ./pikaur && makepkg -si --noconfirm --needed)
fi

pikaur -S --noconfirm --needed - < aur.txt