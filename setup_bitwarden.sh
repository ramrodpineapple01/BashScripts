#!/bin/bash
# Install Bitwarden on a new machine

# Install Docker
## Remove old Docker configurations - probably unnecessary
sudo apt-get remove docker docker-engine docker.io containerd runc

# Install Docker
sudo apt update
sudo apt -y install apt-transport-https 
sudo apt -y install ca-certificates
sudo apt -y install curl
sudo apt -y install gnupg
sudo apt -y install lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
sudo apt update
sudo apt -y install docker-ce docker-ce-cli containerd.io

# Install Docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create bitwarden user
sudo adduser bitwarden

sudo usermod -aG docker bitwarden

# Create Working directory
sudo mkdir /opt/bitwarden
sudo chmod -R 700 /opt/bitwarden
sudo chown -R bitwarden:bitwarden /opt/bitwarden

# Install bitwarden
sudo su bitwarden
cd /opt/bitwarden

curl -Lso bitwarden.sh https://go.btwrdn.co/bw-sh && chmod 700 bitwarden.sh

./bitwarden.sh install


# Build docker config file
CONFIG="# docker-compose.yml\nversion: '3'\n\nservices:\n  bitwarden:\n    image: bitwardenrs/server\n    restart: always\n    ports:\n      - 8000:80\n    volumes:\n      - ./bw-data:/data\n    environment:\n      WEBSOCKET_ENABLED: 'true' # Required to use websockets\n      SIGNUPS_ALLOWED: 'true'   # set to false to disable signups"
	  
echo $CONFIG >> docker-compose.yml


# Build the Docker container
sudo docker-compose up -d