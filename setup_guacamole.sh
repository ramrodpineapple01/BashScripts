#!/bin/bash
sudo apt update

## Install MariaDB server
sudo apt-get install -y mariadb-server
sudo mysql_secure_installation

# Create admin user
sudo mysql -e "GRANT ALL ON *.* TO 'admin'@'localhost' IDENTIFIED BY 'changeme' WITH GRANT OPTION;"


# Build Database
sudo mysql -e "CREATE DATABASE guacamole_db;"
sudo mysql -e "CREATE USER 'guacamole_user'@'localhost' IDENTIFIED BY 'Password01!';"
sudo mysql -e "GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO 'guacamole_user'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

## Install Guacamole Dependencies
VER=1.5.5
# Compiling Tools
sudo apt-get install -y gcc g++ build-essential

# Base libraries for Guacamole protocol
sudo apt-get install -y libcairo2-dev libjpeg-turbo8-dev libpng-dev libtool-bin libossp-uuid-dev

# Rendering support libraries
sudo apt-get install -y libpango1.0-dev libvorbis-dev libwebp-dev

# Install streaming / Recording support
sudo apt-get install -y libavcodec-dev libavformat-dev libavutil-dev libswscale-dev

# Install Kubernetes support
#sudo apt-get install -y libwebsockets-dev

# Install SSH support
sudo apt-get install -y libssh2-1-dev

# Install RDP support
sudo apt-get install -y freerdp2-dev freerdp2-x11

# Install VNC support
sudo apt-get install -y libvncserver-dev libpulse-dev

# Install Telnet support
#sudo apt-get install -y libtelnet-dev 

## Install tomcat
# Install JDK
sudo apt-get install -y default-jdk

# Install Tomcat 10
install_t10 () {

sudo useradd -m -d /opt/tomcat -U -s /bin/false tomcat

cd tmp
wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.24/bin/apache-tomcat-10.1.24.tar.gz
sudo tar xzvf apache-tomcat-10*tar.gz -C /opt/tomcat --strip-components=1
sudo chown -R tomcat:tomcat /opt/tomcat/
sudo chmod -R u+x /opt/tomcat/bin

sudo sed -i 's|</tomcat-users>|<role rolename="manager-gui" />\n<user username="manager" password="changeme" roles="manager-gui" />\n\n<role rolename="admin-gui" />\n<user username="admin" password="changemetoo" roles="manager-gui,admin-gui,manager-status" />\n</tomcat-users>|' /opt/tomcat/conf/tomcat-users.xml

#sudo sed -i 's!<Valve className="org.apache.catalina.valves.RemoteAddrValve"\n\tallow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" />!<Valve className="org.apache.catalina.valves.RemoteAddrValve"\n\tallow="10\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" />!' /opt/tomcat/webapps/manager/META-INF/context.xml

JAVA_LOC=$(sudo update-java-alternatives -l|awk '{print $3}')

cat << EOF | sudo tee /etc/systemd/system/tomcat.service
[Unit]
Description=Tomcat
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment="JAVA_HOME=${JAVA_LOC}"
Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom"
Environment="CATALINA_BASE=/opt/tomcat"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Download the guacamole client
wget https://archive.apache.org/dist/guacamole/$VER/binary/guacamole-$VER.war
wget https://dlcdn.apache.org/tomcat/jakartaee-migration/v1.0.8/binaries/jakartaee-migration-1.0.8-bin.tar.gz
tar -xvf jakartaee-migration-1.0.8-bin.tar.gz
java -jar jakartaee-migration-1.0.8/lib/jakartaee-migration-1.0.8.jar guacamole-$VER.war guacamole.war
sudo mv guacamole.war /opt/tomcat/webapps-javaee/guacamole.war

sudo systemctl daemon-reload
sudo systemctl enable tomcat --now
}


## Install Tomcat 9
install_t9(){
sudo apt-get install -y tomcat9 tomcat9-admin tomcat9-common tomcat9-user
sudo systemctl enable --now tomcat9

sudo sed -i 's|</tomcat-users>|<role rolename="manager-gui" />\n<user username="manager" password="changeme" roles="manager-gui" />\n\n<role rolename="admin-gui" />\n<user username="admin" password="changemetoo" roles="manager-gui,admin-gui,manager-status" />\n</tomcat-users>|' /etc/tomcat9/tomcat-users.xml

# Download the guacamole client
wget https://archive.apache.org/dist/guacamole/$VER/binary/guacamole-$VER.war
sudo mv guacamole-$VER.war /var/lib/tomcat9/webapps/guacamole.war
}

if [[ $1 == "10" ]]; then
	install_t10
else
	install_t9
fi

## Install Guacamole
cd ~
wget https://archive.apache.org/dist/guacamole/$VER/source/guacamole-server-$VER.tar.gz
tar xzf ~/guacamole-server-*.tar.gz
cd ~/guacamole-server-*/

# Build 
./configure --disable-guacenc --with-init-dir=/etc/init.d

make

sudo make install

sudo ldconfig
sudo mkdir  -p /etc/guacamole/{extensions,lib}

# Create config file
cat << EOF | sudo tee /etc/guacamole/guacd.conf
[daemon]
pid_file = /var/run/guacd.pid
#log_level = debug

[server]
#bind_host = localhost
bind_host = 127.0.0.1
bind_port = 4822

#[ssl]
#server_certificate = /etc/ssl/certs/guacd.crt
#server_key = /etc/ssl/private/guacd.key
EOF

sudo systemctl daemon-reload
sudo systemctl enable guacd --now


# Path to guacamole configuration file
echo "GUACAMOLE_HOME=/etc/guacamole" | sudo tee -a /etc/default/tomcat 
echo "export GUACAMOLE_HOME=/etc/guacamole" | sudo tee -a /etc/profile

# Build configuration file 
cat << EOF | sudo tee /etc/guacamole/guacamole.properties
guacd-hostname: localhost
guacd-port:     4822
EOF

# Clean up
cd ~
rm *.tar.gz

## Connect User Database
CON_VER=3.3.3
wget https://dlm.mariadb.com/3752081/Connectors/java/connector-java-$CON_VER/mariadb-java-client-$CON_VER.jar
sudo cp mariadb-java-client-$CON_VER.jar /etc/guacamole/lib/

# JDBC Auth Plugin
JDBC_VER=1.5.5
wget https://downloads.apache.org/guacamole/$JDBC_VER/binary/guacamole-auth-jdbc-$JDBC_VER.tar.gz
tar -xf guacamole-auth-jdbc-$JDBC_VER.tar.gz
sudo mv guacamole-auth-jdbc-$JDBC_VER/mysql/guacamole-auth-jdbc-mysql-$JDBC_VER.jar /etc/guacamole/extensions/
cd guacamole-auth-jdbc-*/mysql/schema
cat *.sql | sudo mysql guacamole_db
cat << EOF | sudo tee -a /etc/guacamole/guacamole.properties
###MySQL properties
mysql-hostname: 127.0.0.1
mysql-port: 3306
mysql-database: guacamole_db
mysql-username: guacamole_user
mysql-password: Password01!
EOF

if [[ $1 == "10" ]]; then
	sudo systemctl restart tomcat guacd
else
	sudo systemctl restart tomcat9 guacd
fi