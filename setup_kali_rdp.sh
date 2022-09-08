#!/bin/bash
# add RDP to Kali
# Rick Dawson 2022
VERSION="1.0.0"

sudo apt update
sudo apt-get -y dist-upgrade

sudo apt-get -y install kali-desktop-xfce 
sudo apt-get -y install xorg 
sudo apt-get -y install xrdp

sudo systemctl enable xrdp --now
