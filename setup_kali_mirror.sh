#!/bin/bash
# Create a kali mirror
# Rick Dawson 2022
VERSION="1.0.0"

REPO_PATH="/var/www/html/ubuntu"

# Install web server
sudo apt -y install apache2
sudo systemctl enable apache2 --now

sudo mkdir -p ${REPO_PATH}
sudo chown www-data:www-data ${REPO_PATH}

# Install apt-mirror
sudo apt update
sudo apt -y install apt-mirror

# Configure apt-mirror
sudo cp /etc/apt/mirror.list /etc/apt/mirror.list.bak
sudo sed -i 's+# set base_path    /var/spool/apt-mirror+set base_path ${REPO_PATH}+g' /etc/apt/mirror.list

# Copy run script
sudo mkdir -p ${REPO_PATH}/var 
$ sudo cp /var/spool/apt-mirror/var/postmirror.sh ${REPO_PATH}/var/




# Create sync user
sudo adduser --disabled-password archvsync

# Create directory
sudo mkdir -p /srv/mirrors/kali{,-images}
sudo chown archvsync:archvsync /srv/mirrors/kali{,-images}

# Setup rsync
sudo sed -i -e "s/RSYNC_ENABLE=false/RSYNC_ENABLE=true/" /etc/default/rsync

sudo cat <<EOF >> /etc/rsyncd.conf
uid = nobody
gid = nogroup
max connections = 25
socket options = SO_KEEPALIVE

[kali]
path = /srv/mirrors/kali
comment = The Kali Archive
read only = true

[kali-images]
path = /srv/mirrors/kali-images
comment = The Kali ISO images
read only = true
EOF

sudo systemctl enable rsync  

sudo su - archvsync
wget http://archive.kali.org/ftpsync.tar.gz
tar zxf ftpsync.tar.gz

cp etc/ftpsync.conf.sample etc/ftpsync-kali.conf
nano etc/ftpsync-kali.conf
grep -E '^[^#]' etc/ftpsync-kali.con
