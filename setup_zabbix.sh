#!/bin/bash
sudo apt update
sudo apt-get -y dist-upgrade

#Install Apache2
sudo apt-get -y install apache2

# Install MariaDb
sudo apt-get -y install mariadb-server mariadb-client
sudo systemctl enable mariadb --now
sudo mysql_secure_installation

#sudo mariadb-server

#GRANT ALL ON *.* TO 'admin'@'localhost' IDENTIFIED BY 'password' WITH GRANT OPTION;
#FLUSH PRIVILEGES;

# Install PHP
sudo apt-get -y install php8.1 php8.1-fpm php8.1-mysql php-common php8.1-cli php8.1-common php8.1-opcache php8.1-readline php8.1-mbstring php8.1-xml php8.1-gd php8.1-curl libapache2-mod-php php-mysql
sudo systemctl enable php8.1-fpm --now

# Open firewall
sudo ufw allow 22
sudo ufw allow 'Apache Full'
sudo ufw allow 10050/tcp
sudo ufw allow 10051/tcp


# Install zabbix repos
wget https://repo.zabbix.com/zabbix/6.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.2-2%2Bubuntu22.04_all.deb
sudo dpkg -i zabbix-release_6.2-2+ubuntu22.04_all.deb
sudo apt update

sudo apt-get -y install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

sudo mysql -u root -e "create database zabbix character set utf8mb4 collate utf8mb4_bin"
sudo mysql -u root -e "create user zabbix@localhost identified by 'password'"
sudo mysql -u root -e "grant all privileges on zabbix.* to zabbix@localhost"
sudo mysql -u root -e "set global log_bin_trust_function_creators = 1"

echo "This password is the zabbix user password for the database"
sudo zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p zabbix

sudo mysql -u root -e "set global log_bin_trust_function_creators = 0"

sudo sed -i 's/# DBPassword=password/DBPassword=password/g' /etc/zabbix/zabbix_server.conf

sudo systemctl restart zabbix-server zabbix-agent apache2
sudo systemctl enable zabbix-server zabbix-agent apache2
