#!/bin/bash

sudo apt update
sudo apt-get install gnupg

wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -

# Ubuntu 18.04
#echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

# Ubuntu 20.04 
#echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

# Ubuntu 22.04
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

sudo apt-get update
sudo apt-get install -y mongodb-org

sudo systemctl daemon-reload
sudo systemctl enable mongod.service
sudo systemctl restart mongod.service
sudo systemctl --type=service --state=active | grep mongod

sudo su

cat > /etc/systemd/system/disable-transparent-huge-pages.service <<EOF
Description=Disable Transparent Huge Pages (THP)
DefaultDependencies=no
After=sysinit.target local-fs.target
[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo never | tee /sys/kernel/mm/transparent_hugepage/enabled > /dev/null'
[Install]
WantedBy=basic.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable disable-transparent-huge-pages.service
sudo systemctl start disable-transparent-huge-pages.service

sudo adduser --system --disabled-password --disabled-login --home /var/empty --no-create-home --quiet --force-badname --group opensearch

#Download Opensearch 2.0.1
wget https://artifacts.opensearch.org/releases/bundle/opensearch/2.0.1/opensearch-2.0.1-linux-x64.tar.gz

#Create Directories
sudo mkdir -p /graylog/opensearch/data
sudo mkdir /var/log/opensearch

#Extract Contents from tar
sudo tar -zxf opensearch-2.0.1-linux-x64.tar.gz 
sudo mv opensearch-2.0.1/* /graylog/opensearch/

#Set Permissions
sudo chown -R opensearch:opensearch /graylog/opensearch/
sudo chown -R opensearch:opensearch /var/log/opensearch
sudo chmod -R 2750 /graylog/opensearch/
sudo chmod -R 2750 /var/log/opensearch

#Create empty log file
sudo -u opensearch touch /var/log/opensearch/graylog.log

#Create System Service
sudo su
cat > /etc/systemd/system/opensearch.service <<!EOF
[Unit]
Description=Opensearch
Documentation=https://opensearch.org/docs/latest
Requires=network.target remote-fs.target
After=network.target remote-fs.target
ConditionPathExists=/graylog/opensearch
ConditionPathExists=/graylog/opensearch/data
[Service]
Environment=OPENSEARCH_HOME=/graylog/opensearch
Environment=OPENSEARCH_PATH_CONF=/graylog/opensearch/config
ReadWritePaths=/var/log/opensearch
User=opensearch
Group=opensearch
WorkingDirectory=/graylog/opensearch
ExecStart=/graylog/opensearch/bin/opensearch
# Specifies the maximum file descriptor number that can be opened by this process
LimitNOFILE=65535
# Specifies the maximum number of processes
LimitNPROC=4096
# Specifies the maximum size of virtual memory
LimitAS=infinity
# Specifies the maximum file size
LimitFSIZE=infinity
# Disable timeout logic and wait until process is stopped
TimeoutStopSec=0
# SIGTERM signal is used to stop the Java process
KillSignal=SIGTERM
# Send the signal only to the JVM rather than its control group
KillMode=process
# Java process is never killed
SendSIGKILL=no
# When a JVM receives a SIGTERM signal it exits with code 143
SuccessExitStatus=143
# Allow a slow startup before the systemd notifier module kicks in to extend the timeout
TimeoutStartSec=180
[Install]
WantedBy=multi-user.target
!EOF

nano /graylog/opensearch/config/opensearch.yml

cluster.name: graylog
node.name: ${HOSTNAME}
path.data: /graylog/opensearch/data
path.logs: /var/log/opensearch
network.host: ${HOSTNAME}
discovery.seed_hosts: ["SERVERNAME01", "SERVERNAME02", "SERVERNAME03"]
cluster.initial_master_nodes: ["SERVERNAME01", "SERVERNAME02", "SERVERNAME03"]
action.auto_create_index: false
plugins.security.disabled: true

sudo nano /graylog/opensearch/config/jvm.options

sudo sysctl -w vm.max_map_count=262144
sudo echo 'vm.max_map_count=262144' >> /etc/sysctl.conf

sudo systemctl daemon-reload
sudo systemctl enable opensearch.service
sudo systemctl start opensearch.service

wget -q https://artifacts.elastic.co/GPG-KEY-elasticsearch -O myKey
sudo apt-key add myKey
echo "deb https://artifacts.elastic.co/packages/oss-7.10.2/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.10.2.list
sudo apt-get update && sudo apt-get install elasticsearch-oss

sudo tee -a /etc/elasticsearch/elasticsearch.yml > /dev/null <<!EOF
cluster.name: graylog
action.auto_create_index: false
!EOF

sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service
sudo systemctl restart elasticsearch.service
sudo systemctl --type=service --state=active | grep elasticsearch

wget https://packages.graylog2.org/repo/packages/graylog-5.0-repository_latest.deb
sudo dpkg -i graylog-5.0-repository_latest.deb
sudo apt-get update && sudo apt-get install graylog-server 

nano /etc/graylog/server/server.conf

echo -n "Enter Password: " && head -1 </dev/stdin | tr -d '\n' | sha256sum | cut -d" " -f1

pwgen -N 1 -s 96

sudo systemctl daemon-reload
sudo systemctl enable graylog-server.service
sudo systemctl start graylog-server.service
sudo systemctl --type=service --state=active | grep graylog

