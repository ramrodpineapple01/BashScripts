#!/bin/bash

wget https://go.dev/dl/go1.22.2.linux-amd64.tar.gz
sudo  rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.22.2.linux-amd64.tar.gz

echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.profile

sudo apt install -y build-essential

sudo apt install -y libpam0g-dev

git clone https://github.com/bolkedebruin/rdpgw.git

cd rdpgw
make
make install