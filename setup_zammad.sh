#!/bin/bash

sudo apt update
sudo apt-get -y install curl apt-transport-https gnupg

# Set US_en locale
sudo locale-gen en_US.UTF-8
sudo echo "LANG=en_US.UTF-8" > /etc/default/locale

# Add Elasticsearch repository
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | \
  sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | \
  sudo tee /etc/apt/sources.list.d/elastic-8.x.list

# Add Zammad repository
sudo curl -fsSL https://dl.packager.io/srv/zammad/zammad/key | \
  sudo gpg --dearmor | tee /etc/apt/trusted.gpg.d/pkgr-zammad.gpg> /dev/null
  
echo "deb [signed-by=/etc/apt/trusted.gpg.d/pkgr-zammad.gpg] https://dl.packager.io/srv/deb/zammad/zammad/stable/ubuntu 20.04 main"| \
  sudo tee /etc/apt/sources.list.d/zammad.list > /dev/null
  
# Install software
sudo apt update

sudo apt-get -y install elasticsearch
sudo systemctl enable elasticsearch --now

sudo apt-get -y install zammad

# Set the Elasticsearch server address
sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install ingest-attachment
sudo systemctl restart elasticsearch
sudo zammad run rails r "Setting.set('es_url', 'http://localhost:9200')"


# Build the search index
sudo zammad run rake zammad:searchindex:rebuild