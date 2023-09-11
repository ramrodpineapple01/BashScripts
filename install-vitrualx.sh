#!/bin/bash

sudo apt update
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove
sudo apt-get -y clean
sudo apt-get -y install git-core zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev

# Install Apache Server
sudo apt-get -y install apache2
sudo ufw allow ssh
sudo ufw allow in "Apache Full"
sudo ufw enable

# Install mysql server
sudo apt-get -y install mysql-server mysql-client libmysqlclient-dev

# Install PHP
#sudo apt install php libapache2-mod-php php-mysql

# !Ensure the root mysql user has a password set before running mysql_secure_installation!
# Change the password in the following line before running
sudo mysql --user=root --execute="ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';"

sudo mysql_secure_installation

# Install Ruby on Rails
cd ~
git clone https://github.com/excid3/asdf.git ~/.asdf
echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc
echo '. "$HOME/.asdf/completions/asdf.bash"' >> ~/.bashrc
echo 'legacy_version_file = yes' >> ~/.asdfrc
echo 'export EDITOR="code --wait"' >> ~/.bashrc

exec $SHELL

asdf plugin add ruby
asdf plugin add nodejs

#asdf install ruby 1.8.7
#asdf global ruby 1.8.7
asdf install ruby 2.6.0
asdf global ruby 2.6.0

# Update to the latest Rubygems version
gem update --system
gem install rails -v 3.0.3

asdf install nodejs 18.16.0
asdf global nodejs 18.16.0

# Move files to the web server
cd VirtualX
sudo mkdir /var/www/virtualx
sudo cp -R * /var/www/virtualx

#gem install bundler:1.17.3
#bundle _1.17.3_ install
bundle install

