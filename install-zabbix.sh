#!/bin/bash

sudo apt update
sudo apt-get -y install nginx

sudo ufw allow 'Nginx Full'
sudo ufw allow ssh
#sudo ufw enable

sudo apt-get -y install mariadb-server
sudo mysql_secure_installation

sudo apt-get -y install php8.1-fpm php-mysql
sudo apt-get -y install php php-mbstring php-gd php-xml php-bcmath php-ldap php-mysql

wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4%2Bubuntu22.04_all.deb
sudo dpkg -i zabbix-release_6.0-4+ubuntu22.04_all.deb
sudo apt update
sudo apt-get -y install zabbix-server-mysql zabbix-frontend-php zabbix-nginx-conf zabbix-sql-scripts zabbix-agent

mysql -uroot -p
password
mysql> create database zabbix character set utf8mb4 collate utf8mb4_bin;
mysql> create user zabbix@localhost identified by 'password';
mysql> grant all privileges on zabbix.* to zabbix@localhost;
mysql> quit;
