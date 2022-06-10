#!/bin/bash

# Create a directory that serves as the root directory for the CA.
sudo mkdir /root/ca/

# Create ‘certs’ directory to store issued certificates.
sudo mkdir /root/ca/certs/

# Create ‘CRL’ directory to store Certificate Revocation List.
sudo mkdir /root/ca/crl/

# Create optional directory ‘newcerts’ to store new certificates.
sudo mkdir /root/ca/newcerts/

# Create a directory ‘private’ to store private keys.
sudo mkdir /root/ca/private/

# Create a dedicated directory ‘requests’ to store certificate requests or CSRs.
sudo mkdir /root/ca/requests/

# Create ‘index.txt’ which act as a database for issued certificates.
sudo touch /root/ca/index.txt

# Create an empty file named ‘serial’ which stores the next serial number of the certificate. 
# Move the file to /root/ca
echo "1000" > serial
sudo mv serial /root/ca/serial
sudo chown root:root /root/ca/serial

# Protect the CA directory
sudo chmod -R 600 /root/ca
