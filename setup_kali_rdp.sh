#!/bin/bash
# add RDP to Kali
# Rick Dawson 2022

sudo apt update
sudo apt-get -y dist-upgrade

apt-get install -y kali-desktop-xfce 
apt-get install -y xorg 
apt-get install -y xrdp

sudo systemctl enable xrdp --now
