#!/bin/bash
## copyright R. Dawson 2024
VERSION='2.0.2'

# VARIABLES
IP_ADDRESS=$(hostname -I | cut -d' ' -f1)

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
sudo dpkg-reconfigure -plow unattended-upgrades

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

## Get python version
p_version=$(python3 --version | sed 's/Python //g' | cut -d. -f1,2)

## Install venv
sudo apt-get -y install python${p_version}-venv

## Install nodejs
curl -fsSL https://deb.nodesource.com/setup_21.x | sudo -E bash - &&\
sudo apt-get -y install nodejs

## Install configurable-proxy
sudo npm install -g configurable-http-proxy

## Create Virtual Environment for Jupyterhub
sudo python3 -m venv /opt/jupyterhub/

## Install JupyterHub
sudo /opt/jupyterhub/bin/python3 -m pip install wheel
sudo /opt/jupyterhub/bin/python3 -m pip install jupyterhub
sudo /opt/jupyterhub/bin/python3 -m pip install jupyterlab notebook  # needed if running the notebook servers in the same environment
sudo /opt/jupyterhub/bin/python3 -m pip install pycurl
sudo /opt/jupyterhub/bin/python3 -m pip install ipywidgets

## Install BASH kernel
sudo /opt/jupyterhub/bin/python3 -m pip install bash_kernel
sudo /opt/jupyterhub/bin/python3 -m bash_kernel.install

## Install Jupyter AI
sudo /opt/jupyterhub/bin/python3 -m pip install jupyter-ai

## Add /notebooks directory to all new users (and current user)
sudo mkdir /etc/skel/notebooks
mkdir ~/notebooks

## Create an admin user
username=admin
password=jovyan # <-- Change This!

sudo adduser --gecos "" --disabled-password ${username}
sudo chpasswd <<<"${username}:${password}"

## Create the folder for the JupyterHub configuration
sudo mkdir -p /opt/jupyterhub/etc/jupyterhub/
cd /opt/jupyterhub/etc/jupyterhub/

## Generate a configuration file
sudo /opt/jupyterhub/bin/jupyterhub --generate-config

## Initial security setup 
## This also makes the installation user a JHub admin
sudo sed -i "s|# c.JupyterHub.internal_ssl = False|c.JupyterHub.internal_ssl = True|g" jupyterhub_config.py
sudo sed -i "s|# c.Spawner.notebook_dir = ''|c.Spawner.notebook_dir = '~/notebooks'|g" jupyterhub_config.py
sudo sed -i "s|# c.JupyterHub.bind_url = 'http://:8000'|c.JupyterHub.bind_url = 'http://${IP_ADDRESS}:8000'|g" jupyterhub_config.py
sudo sed -i "s|# c.Authenticator.admin_users = set()|c.Authenticator.admin_users = {'admin', '${USER}'}|g" jupyterhub_config.py
sudo sed -i "s|# c.JupyterHub.trusted_alt_names = []|c.JupyterHub.trusted_alt_names = ['DNS:${HOSTNAME}','IP:${IP_ADDRESS}']|g" jupyterhub_config.py
sudo sed -i "s|# c.Spawner.cmd = ['jupyterhub-singleuser']|c.Spawner.cmd = ['/opt/jupyterhub/bin/jupyterhub-singleuser']|g" jupyterhub_config.py
sudo sed -i "s|# c.Authenticator.delete_invalid_users = False|c.Authenticator.delete_invalid_users = True|g" jupyterhub_config.py
echo c.LocalAuthenticator.create_system_users=True | sudo tee -a /opt/jupyterhub/etc/jupyterhub/jupyterhub_config.py > /dev/null

## Install PostgreSQL for production
# Create the file repository configuration:
sudo sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Import the repository signing key:
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Update the package lists:
sudo apt-get update

# Install the latest version of PostgreSQL.
# If you want a specific version, use 'postgresql-12' or similar instead of 'postgresql':
sudo apt-get -y install postgresql postgresql-contrib

# Install the SQLAlchemy library for Postgres
sudo /opt/jupyterhub/bin/python3 -m pip install psycopg2-binary

# Generate userdb user password 
password=$(dd if=/dev/urandom bs=18 count=1 2>/dev/null | base64)
echo "jhub_agent:${password}" > ~/db_user.txt

# Create postgres database user
sudo -u postgres psql -U postgres -c "CREATE ROLE jhub_agent CREATEDB LOGIN PASSWORD '${password}';"

# Create postgres database
sudo -u postgres psql -U postgres -c "CREATE DATABASE jhub WITH OWNER = 'jhub_agent';"

# Set postgres database in the configuration
sudo sed -i "s|# c.JupyterHub.db_url = 'sqlite:///jupyterhub.sqlite'|c.JupyterHub.db_url = 'postgresql+psycopg2://jhub_agent:${password}@127.0.0.1:5432/jhub'|g" jupyterhub_config.py

## Copy current configuration file to /etc/JupyterHub
sudo mkdir -p /etc/jupyterhub
sudo cp jupyterhub_config.py /etc/jupyterhub

## Create Startup script
cat <<!EOF > ~/run-jhub.sh
#!/bin/bash
CONFIG_FILE='/opt/jupyterhub/etc/jupyterhub/jupyterhub_config.py'

echo 'Starting Jupyterhub from '\${CONFIG_FILE}
sudo /opt/jupyterhub/bin/jupyterhub -f \${CONFIG_FILE}
!EOF

## Create Config Edit Script
cat <<!EOF > ~/edit-config.sh
#!/bin/bash

sudo nano /opt/jupyterhub/etc/jupyterhub/jupyterhub_config.py

sudo cp /opt/jupyterhub/etc/jupyterhub/jupyterhub_config.py /etc/jupyterhub/jupyterhub_config.py
!EOF

## Make home directory scripts executable
sudo chmod +x ~/run-jhub.sh
sudo chmod +x ~/edit-config.sh

## Install typical useful libraries
sudo /opt/jupyterhub/bin/python3 -m pip install ipyleaflet
sudo /opt/jupyterhub/bin/python3 -m pip install pandas
sudo /opt/jupyterhub/bin/python3 -m pip install geopandas

## Create systemd file
cat <<!EOF | sudo tee jupyterhub.service
[Unit]
Description=JupyterHub
After=syslog.target network.target

[Service]
User=root
Environment="PATH=/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/opt/jupyterhub/bin"
ExecStart=/opt/jupyterhub/bin/jupyterhub -f /opt/jupyterhub/etc/jupyterhub/jupyterhub_config.py

[Install]
WantedBy=multi-user.target
!EOF

## Copy systemd file
sudo mkdir -p /opt/jupyterhub/etc/systemd
sudo cp jupyterhub.service /opt/jupyterhub/etc/systemd

## Link systemd file 
sudo ln -s /opt/jupyterhub/etc/systemd/jupyterhub.service /etc/systemd/system/jupyterhub.service

## Enable service
sudo systemctl daemon-reload
#sudo systemctl enable jupyterhub.service --now

## Install anaconda for user environments
## Back to the home directory
cd ~

## Install Anacononda public gpg key to trusted store
curl https://repo.anaconda.com/pkgs/misc/gpgkeys/anaconda.asc | gpg --dearmor > conda.gpg
sudo install -o root -g root -m 644 conda.gpg /etc/apt/trusted.gpg.d/

## Add Repo
echo "deb [arch=amd64] https://repo.anaconda.com/pkgs/misc/debrepo/conda stable main" | sudo tee /etc/apt/sources.list.d/conda.list

## Install Conda
sudo apt-get update
sudo apt-get install -y conda

## Add Conda setup script
sudo ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh

## Create a default conda environment
sudo mkdir -p /opt/conda/envs/
sudo /opt/conda/bin/conda create --prefix /opt/conda/envs/python python=3.10 ipykernel

sudo /opt/conda/envs/python/bin/python -m ipykernel install --prefix=/opt/jupyterhub/ --name 'python' --display-name "Python (conda)"


## Add current hostname to /etc/hosts
echo "Make sure your hostname is correct in /etc/hosts"
echo ${IP_ADDRESS} ${HOSTNAME} | sudo tee -a /etc/hosts > /dev/null

echo "Installation complete.  Use run-jhub.sh to start JupyterHub or enable jupyterhub.service"