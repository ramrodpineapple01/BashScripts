#!/bin/bash

sudo apt update
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove
sudo apt-get -y clean

# Install Apache Server
sudo apt-get -y install apache2
sudo ufw allow ssh
sudo ufw allow in "Apache Full"
sudo ufw enable

# Install mysql server
sudo apt-get -y install mysql-server
sudo apt-get -y install mysql-client
sudo apt-get -y install libmysqlclient-dev
# !Ensure the root mysql user has a password set before running mysql_secure_installation!
# Change the password in the following line before running
sudo mysql --user=root --execute="ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';"

sudo mysql_secure_installation

# Install PHP
sudo apt-get -y install php 
sudo apt-get -y installlibapache2-mod-php
sudo apt-get -y install php-cli
sudo apt-get -y install php-curl
sudo apt-get -y install php-gd
sudo apt-get -y install php-imagick
#sudo apt-get -y install php-mcrypt
sudo apt-get -y install php-memcache
sudo apt-get -y install php-mysql

# Dependencies
sudo apt-get -y install acpid 

sudo apt-get -y install perl 
sudo apt-get -y install libauthen-pam-perl
sudo apt-get -y install libio-pty-perl
sudo apt-get -y install libmd5-perl
sudo apt-get -y install libnet-ssleay-perl
sudo apt-get -y install libpam-runtime
sudo apt-get -y install lm-sensors

sudo apt-get -y install texlive-latex-extra

sudo apt-get -y install zbar-tools

# Restart Apache
sudo systemctl restart apache2