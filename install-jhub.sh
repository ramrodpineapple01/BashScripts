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
sudo sed -i 's|//Unattended-Upgrade::AutoFixInterruptedDpkg "true";|Unattended-Upgrade::AutoFixInterruptedDpkg "true";|g' /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i 's|//Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";|Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";|g' /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i 's|//Unattended-Upgrade::Unattended-Upgrade::Remove-New-Unused-Dependencies "false";|Unattended-Upgrade::Unattended-Upgrade::Remove-New-Unused-Dependencies "true";|g' /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i 's|//Unattended-Upgrade::Remove-Unused-Dependencies "false";|Unattended-Upgrade::Remove-Unused-Dependencies "true";|g' /etc/apt/apt.conf.d/50unattended-upgrades

sudo ufw allow http
sudo ufw allow https

## Install pip
sudo apt-get -y install python3-pip

## Install nodejs
curl -fsSL https://deb.nodesource.com/setup_21.x | sudo -E bash - &&\
sudo apt-get -y install nodejs

## Install JupyterHub
sudo python3 -m pip install jupyterhub
sudo npm install -g configurable-http-proxy
sudo python3 -m pip install jupyterlab notebook  # needed if running the notebook servers in the same environment

## Generate a configuration file
sudo jupyterhub --generate-config

## initial security setup
sudo sed -i 's/# c.JupyterHub.internal_ssl = False/c.JupyterHub.internal_ssl = True/g' jupyterhub_config.py

## Copy current configuration file to /etc/JupyterHub
sudo mkdir -p /etc/jupyterhub
sudo cp jupyterhub_config.py /etc/jupyterhub

