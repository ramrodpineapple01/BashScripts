#!/bin/bash
# Installation script for Microsoft Surface devices
# v 1.0.0


wget -qO - https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.asc \
    | gpg --dearmor | sudo dd of=/etc/apt/trusted.gpg.d/linux-surface.gpg
	
echo "deb [arch=amd64] https://pkg.surfacelinux.com/debian release main" \
	| sudo tee /etc/apt/sources.list.d/linux-surface.list

sudo apt update
sudo apt-get dist-upgrade -y

sudo apt-get install -y linux-image-surface linux-headers-surface iptsd libwacom-surface
sudo systemctl enable iptsd

sudo apt-get install -y intel-microcode

sudo apt-get autoremove -y
sudo apt-get clean -y

sudo update-grub

# This updates the secureboot key and really should not be scripted
#sudo apt install linux-surface-secureboot-mok