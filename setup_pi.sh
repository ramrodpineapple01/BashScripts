#!/bin/bash
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y autoremove

sudo apt-get -y install tmux

sudo apt-get -y install wireguard
sudo apt-get -y install wireguard-tools

# RasPi Raspian Only
#sudo apt -y install snapd
#sudo snap install core
# RasPi Only

sudo snap install nextcloud
sudo snap connect nextcloud:removable-media
sudo snap run nextcloud.enable-https self-signed

# Adding IP addresses
##  /var/snap/nextcloud/current/nextcloud/config/config.php
##  or
##  sudo nextcloud.occ config:system:get trusted_domains
##  sudo nextcloud.occ config:system:set trusted_domains 1 --value=<IP Address>
