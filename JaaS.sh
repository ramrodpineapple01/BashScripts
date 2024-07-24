#!/bin/bash
# install jitsi seamlessly... almost
# Jorge Figoli V1 17JUL24

# Prompt for user's domain
read -p "Enter your domain name (e.g., jitsi.yourdomain.com): " DOMAIN
read -p "Enter the public IP of your server: " IP
# Step 1: Setting the System Hostname
echo "Setting system hostname..."
sudo hostnamectl set-hostname $DOMAIN
echo "testing hostname"
hostname
#need to use sudo sed to configure the /etc/host file but for now. 
echo "add your public ip and domain name below the 127.0.1.1 localhost line in the following hosts file"
sleep 10
sudo nano /etc/hosts


# Step 2: Configuring the Firewall
echo "Configuring firewall..."
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3478/udp
sudo ufw allow 5349/tcp
sudo ufw allow 10000/udp
sudo ufw enable
sudo ufw status

# Step 3: Installing Jitsi Meet
echo "Installing Jitsi Meet..."
curl https://download.jitsi.org/jitsi-key.gpg.key | sudo sh -c 'gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg'
echo 'deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/' | sudo tee /etc/apt/sources.list.d/jitsi-stable.list > /dev/null
curl https://prosody.im/files/prosody-debian-packages.key | sudo sh -c 'gpg --dearmor > /usr/share/keyrings/prosody-keyring.gpg'
echo "deb [signed-by=/usr/share/keyrings/prosody-keyring.gpg] http://packages.prosody.im/debian $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/prosody.list > /dev/null

sudo apt update
sudo apt install -y jitsi-meet

# Step 4: Obtaining a Signed TLS Certificate
echo "Installing certbot and obtaining TLS certificate..."
sudo apt install -y certbot
sudo /usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh
# Select to SSL when it prompts, this will allow certbot to install which makes getting a cert easier.

# Step 5: Locking Conference Room Creation
# There is a code error where the text is not being replaced by the sudo sed command
echo "Configuring authentication..."
sudo sed -i "s/authentication = \"anonymous\"/authentication = \"internal_plain\"/" /etc/prosody/conf.avail/$DOMAIN.cfg.lua
echo "
VirtualHost \"guest.$DOMAIN\"
    authentication = \"anonymous\"
    c2s_require_encryption = false
    modules_enabled = {
        \"bosh\";
        \"ping\";
        \"pubsub\";
        \"speakerstats\";
        \"turncredentials\";
        \"conference_duration\";
    }
" | sudo tee -a /etc/prosody/conf.avail/$DOMAIN.cfg.lua > /dev/null

sudo sed -i "s/\/\/ anonymousdomain: 'guest.$DOMAIN',/anonymousdomain: 'guest.$DOMAIN',/" /etc/jitsi/meet/$DOMAIN-config.js

echo "org.jitsi.jicofo.auth.URL=XMPP:$DOMAIN" | sudo tee /etc/jitsi/jicofo/sip-communicator.properties > /dev/null

# Create admin user
read -p "Enter username for admin: " ADMIN_USER
read -s -p "Enter password for admin: " ADMIN_PASS
echo
sudo prosodyctl register $ADMIN_USER $DOMAIN $ADMIN_PASS

# Restart services
sudo systemctl restart prosody.service jicofo.service jitsi-videobridge2.service

echo "Jitsi Meet installation and configuration completed!"
echo "You can now access your Jitsi Meet instance at https://$DOMAIN"




# Still need to configure "the conference lockdown" watch this video as reference: https://www.youtube.com/watch?v=wZ-4LVzNRFU

