#!/bin/bash

sudo apt-get update
sudo apt-get -y dist-upgrade

# Install web server and PHP
sudo apt-get -y install apache2 php
sudo mkdir -p /var/www/html/speedtest

# Install speedtest
git clone https://github.com/radawson/speedtest.git
cd speedtest

# Basic Frontend
sudo cp -R backend example-singleServer-full.html *.js favicon.ico /var/www/html/speedtest

# Database backend
sudo cp -R results/ /var/www/html/speedtest
sudo apt-get -y install mariadb-server
sudo apt-get -y install phpmyadmin

sudo chown -R www-data /var/www/html/speedtest

