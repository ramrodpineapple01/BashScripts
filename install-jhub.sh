#!/bin/bash
## copyright R. Dawson 2024
VERSION='1.0.1'

printf "Jupyterhub installation script v${VERSION}\n"

# Server Prep
sudo apt update
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove
sudo apt-get -y clean

sudo apt-get -y install unattended-upgrades
#sudo nano /etc/apt/apt.conf.d/20auto-upgrades
#APT::Periodic::Update-Package-Lists "1";
#APT::Periodic::Unattended-Upgrade "1";

#sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i 's|//Unattended-Upgrade::AutoFixInterruptedDpkg "true";|Unattended-Upgrade::AutoFixInterruptedDpkg "true";|g' /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i 's|//Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";|Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";|g' /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i 's|//Unattended-Upgrade::Unattended-Upgrade::Remove-New-Unused-Dependencies "false";|Unattended-Upgrade::Unattended-Upgrade::Remove-New-Unused-Dependencies "true";|g' /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i 's|//Unattended-Upgrade::Remove-Unused-Dependencies "false";|Unattended-Upgrade::Remove-Unused-Dependencies "true";|g' /etc/apt/apt.conf.d/50unattended-upgrades

sudo ufw allow http
sudo ufw allow https
sudo ufw allow 8000

## Install pip
sudo apt-get -y install python3-pip

## Install nodejs
curl -fsSL https://deb.nodesource.com/setup_21.x | sudo -E bash - &&\
sudo apt-get -y install nodejs

## Install configurable-proxy
sudo npm install -g configurable-http-proxy

## Install JupyterHub
sudo python3 -m pip install jupyterhub
sudo python3 -m pip install jupyterlab notebook  # needed if running the notebook servers in the same environment

## Add /notebooks directory to all new users (and current user)
sudo mkdir /etc/skel/notebooks
mkdir ~/notebooks

## Create an admin user
username=admin
password=jovyan # <-- Change This!

sudo adduser --gecos "" --disabled-password ${username}
sudo chpasswd <<<"${username}:${password}"

## Generate a configuration file
sudo jupyterhub --generate-config

## Initial security setup 
## This also makes the installation user a JHub admin
sudo sed -i "s|# c.JupyterHub.internal_ssl = False|c.JupyterHub.internal_ssl = True|g" jupyterhub_config.py
#sudo sed -i "s|# c.Spawner.default_url = ''|c.Spawner.default_url = '/tree/home/{username}'|g" jupyterhub_config.py
sudo sed -i "s|# c.Spawner.notebook_dir = ''|c.Spawner.notebook_dir = '~/notebooks'|g" jupyterhub_config.py
sudo sed -i "s|# c.Authenticator.admin_users = set()|c.Authenticator.admin_users = {'admin', '${USER}'}|g" jupyterhub_config.py
sudo echo c.LocalAuthenticator.create_system_users=True >> jupyterhub_config.py

## Copy current configuration file to /etc/JupyterHub
sudo mkdir -p /etc/jupyterhub
sudo cp jupyterhub_config.py /etc/jupyterhub

## Create Startup script
cat <<\EOF > run-jhub.sh
#!/bin/bash
CONFIG_FILE='/etc/jupyterhub/jupyterhub_config.py'

echo 'Starting Jupyterhub from '${CONFIG_FILE}
sudo jupyterhub -f ${CONFIG_FILE}
EOF
sudo chmod +x run-jhub.sh