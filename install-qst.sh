#!/bin/bash
sudo apt-get update
sudo apt-get -y dist-upgrade
sudo apt-get -y install build-essential

sudo apt-get -y install apache2
# Start and stop service to ensure configs are built
sudo systemctl start apache2
sudo systemctl stop apache2

sudo apt-get -f install
sudo apt-get -y install libapache2-mod-perl2 

sudo cpan install cpan
cpan reload

cat <<EOF | sudo tee /etc/apache2/conf-available/mod_perl.conf
Alias /perl /var/www/perl 
<Location /qst>
   SetHandler perl-script
   PerlResponseHandler MyApache2::QST 
</Location>
EOF

sudo a2enconf mod_perl
a2enmod perl.load

sudo systemctl restart apache2

sudo mkdir -p /var/www/qst/schools/qst_files/photos
sudo chmod 777 -R /var/www/qst/schools

sudo mkdir /home/MyApache2 
cd ~/qst_linux 
sudo cp QST.pm /home/MyApache2 
sudo cp startup.pl /home/MyApache2 
sudo chmod 711 /home/MyApache2/startup.pl 
sudo chmod 715 /home/MyApache2/QST.pm

sudo cp -R qst/* /var/www/qst
sudo cp -R schools/* /var/www/qst/schools

sudo sed -i 's$DocumentRoot /var/www/html$DocumentRoot /var/www/qst\n\tPerlInterpStart 20\n\tPerlInterpMax 100\n\tPerlInterpMaxSpare 20\n$g' /etc/apache2/sites-available/000-default.conf

sudo sed -i 's$# AccessFileName: The$StartServers 10 \
MaxRequestWorkers 10000 \
ServerLimit 100 \
ThreadsPerChild 100 \
ThreadLimit 100 \
PerlModule Apache::DBI \
PerlRequire /home/MyApache2/startup.pl \
<Location /qst> \
SetHandler perl-script \
PerlResponseHandler MyApache2::QST \
</Location> \
# AccessFileName: The$g' /etc/apache2/apache2.conf


sudo apt-get -y install perl-doc 
sudo perl -MCPAN -e 'install Bundle::DBI'

sudo apt-get -y install mysql-server

# MySQL config
sudo mysql -u root <<EOFMYSQL   
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'changeme';
CREATE DATABASE qst;
CREATE USER 'qstuser'@'localhost' IDENTIFIED BY 'Qstyreg#389';
grant all on qst.* to qstuser@localhost;
CREATE USER 'qst'@'localhost' identified by 'Qst#captain2';
grant SELECT, INSERT, DELETE,UPDATE ON qst.* TO qst@localhost;
EOFMYSQL

sudo sed -i 's$= /var/run/mysqld/mysqld.sock$= /run/mysqld/mysqld.sock$g' /etc/mysql/mysql.conf.d/mysqld.cnf

mysql -u qstuser -pQstyreg#389 qst <~/qst_linux/qst.sql

sudo apt-get update 
sudo cpan YAML
sudo cpan Email::Valid
sudo apt-get -y install libcrypt-pbkdf2-perl
sudo apt-get -y install libdbd-mysql-perl
sudo cpan -i Net::DNS
sudo cpan -i Net::LDAP
sudo cpan -i Mail::Address
sudo cpan -i MIME::Base64
sudo cpan -i Archive::Zip
sudo cpan -i Exporter
sudo perl -MCPAN -e 'install Apache::DBI'

sudo systemctl restart apache2