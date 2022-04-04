#!/bin/bash
# Script for setting up nebula
# (C) 2021 Richard Dawson
# v 0.2

# Functions
## Processor Types
amd64(){
    printf "64-bit Intel/AMD architecture"
	sudo wget https://github.com/slackhq/nebula/releases/download/v1.4.0/nebula-linux-amd64.tar.gz
    sudo tar -xzf nebula-linux-amd64.tar.gz
	sudo rm nebula-linux-amd64.tar.gz
}

raspi() {
    printf "64-bit ARM architecture"
	sudo wget https://github.com/slackhq/nebula/releases/download/v1.4.0/nebula-linux-arm64.tar.gz
    sudo tar -xzf nebula-linux-arm64.tar.gz
	sudo rm nebula-linux-arm64.tar.gz
}
  
## Build Types
make_ca(){
sudo ./nebula-cert ca -name "$2"
sudo mkdir /srv/ca
sudo chmod 755 /srv/ca
sudo cp ca.crt /srv/ca
}

make_lighthouse(){
# Get default lighthouse config
sudo wget https://raw.githubusercontent.com/jimsalterjrs/nebula-sample-configs/master/config.lighthouse.yaml
sudo cp config.lighthouse.yaml /etc/nebula/config.yaml

# build fetch directories
sudo useradd --no-create-home xfer
sudo mkdir /srv/lighthouse
sudo chmod 755 /srv/lighthouse
cd /srv/lighthouse || exit
sudo wget https://raw.githubusercontent.com/rdbh/BashScripts/master/nebula.service
}

make_node(){
# Get default node config
sudo wget https://raw.githubusercontent.com/jimsalterjrs/nebula-sample-configs/master/config.node.yaml
sudo cp config.node.yaml /etc/nebula/config.yaml
# sudo scp root@"$lighthouse_ip":/srv/lighthouse/config.yaml /etc/nebula/config.yaml
}

### Main Program ###
if [ "$2" != "" ] && [ "$1" != "ca" ]
then
  printf "\n\n Too many arguments"
  exit 1
fi  

clear
read -r -p "Enter Lighthouse public IP: " lighthouse_ip

# Update repositories
sudo apt-get update
sudo apt-get -y full-upgrade
sudo apt -y autoremove

# Create a nebula user
sudo useradd --system --no-create-home nebula

# Create install directory
sudo mkdir /opt/nebula
sudo mkdir /opt/nebula/certs
cd /opt/nebula || exit

# Create config directories
sudo mkdir /etc/nebula
sudo mkdir /etc/nebula/certs


# Check processor architecture and download current release
proc_arch=$(uname -m)

case $proc_arch in

    x86_64)
	  amd64
	  ;;

    aarch64)
	  raspi
	  ;;
	  
	*)
	  printf "/n/n Unknown architecture %s" "$proc_arch"
	  exit
	  ;;
	  
esac

# Install nebula to /usr/bin/bash
sudo install ./nebula /usr/bin
sudo setcap cap_net_admin=+pe /usr/bin/nebula

# Build specific type of nebula node
case $1 in 
    "")
	  make_node
	  ;;
	node)
	  make_node
	  ;;
	lighthouse)
	  make_lighthouse
	  ;;
	ca)
	  make_ca "$@"
	  ;;
	*)
	  printf "\n\n Invalid Argument\n\tBuilding node"
	  make_node
	  ;;
esac

# Pull certificate(s)
sudo scp root@"$lighthouse_ip":/srv/lighthouse/ca.crt /etc/nebula/certs/ca.crt
sudo chown -R nebula:nebula /etc/nebula
sudo chmod 600 /etc/nebula/certs/*

# Set up nebula as a service
sudo scp root@"$lighthouse_ip":/srv/lighthouse/nebula.service /etc/systemd/system/
sudo systemctl daemon-reload

# Enable nebula service
sudo systemctl enable nebula.service
sudo systemctl start nebula.service

# TODO Make sure nextcloud is updated
# sudo nextcloud.occ config:system:set trusted_domains 0 --value="{{ nextcloud_server_fqdn }}"
