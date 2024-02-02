#!/bin/bash

# Server Prep
sudo apt update
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove
sudo apt-get -y clean

sudo apt-get -y install unattended-upgrades
sudo nano /etc/apt/apt.conf.d/20auto-upgrades
#APT::Periodic::Update-Package-Lists "1";
#APT::Periodic::Unattended-Upgrade "1";

#sudo nano /etc/apt/apt.conf.d/50unattended-upgrades

sudo ufw allow http
sudo ufw allow https

## TLJH installation start
sudo apt-get -y install python3 python3-dev git curl

curl -L https://tljh.jupyter.org/bootstrap.py | sudo -E python3 - --admin dawsonr:P@NGu1n2 --plugin tljh-shared-directory --show-progress-page

# Remember this for later
# Fixes http_proxy
#sudo setcap 'cap_net_bind_service=+ep' $(readlink -f $(which node))