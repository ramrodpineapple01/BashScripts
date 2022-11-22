#!/bin/bash

USERNAME="${1}"
FILES_DIRECTORY=/srv/xftp

sudo apt update

# TFTP
sudo apt install tftpd-hpa
sudo mkdir -p ${FILES_DIRECTORY}
sudo chown tftp:tftp ${FILES_DIRECTORY}
# Fix your config !
sudo nano /etc/default/tftpd-hpa
sudo systemctl restart tftpd-hpa

# GUI Version


# CLI Version
sudo mkdir -p ${FILES_DIRECTORY}
sudo chmod 701 ${FILES_DIRECTORY}

groupadd sftp_users
useradd -g sftp_users -d /upload -s /sbin/nologin "${USERNAME}"

mkdir -p ${FILES_DIRECTORY}/${USERNAME}/upload
chown -R root:sftp_users ${FILES_DIRECTORY}/${USERNAME}
chown -R ${USERNAME}:sftp_users ${FILES_DIRECTORY}/${USERNAME}/upload

sudo cat <<EOF >> /etc/ssh/sshd_config
Match Group sftp_users
ChrootDirectory ${FILES_DIRECTORY}/%u
ForceCommand internal-sftp
EOF

sudo systemctl restart sshd