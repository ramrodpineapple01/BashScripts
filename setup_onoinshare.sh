#!/bin/bash

DISTRIBUTION=$(cat /etc/lsb-release | grep CODENAME | sed 's/DISTRIB_CODENAME=//')

sudo apt update
sudo apt -y install apt-transport-https

sudo cat 
	deb     [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org "${DISTRIBUTION}" main
	deb-src [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org "${DISTRIBUTION}" main
