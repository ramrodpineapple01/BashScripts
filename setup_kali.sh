#!/bin/bash
# Kali VM base setup script
# R. Dawson 2022
# v1.0.0

## Variables
#TODO: This works for a VM, but needs a better method
ADAPTER1=$(ls /sys/class/net | grep e)   # 1st Ethernet adapter

date_var=$(date +'%y%m%d-%H%M')  # Today's Date and time
LOG_FILE="${date_var}_install.log"  # Log File name

## Functions
check_internet() {
	# SETTINGS
	TEST="8.8.8.8"       # Test ping to google DNS

	# Report 
	LOG_FILE=~/Documents/ReportInternet.log

	# Messages
	MESSAGE1="Attempting to restore connectivity"
	MESSAGE2="This could take up to 2 minutes"
	MESSAGE3="No Internet connection detected"
	MESSAGE4="Internet connection detected"

	# Date
	TODAY=$(date "+%r %d-%m-%Y")

	# Show IP Public Address
	IPv4ExternalAddr1=$(ip addr list $ADAPTER1 |grep "inet " |cut -d' ' -f6|cut -d/ -f1)
	IPv6ExternalAddr1=$(ip addr list $ADAPTER1 |grep "inet6 " |cut -d' ' -f6|cut -d/ -f1)

	# Alarm
	alarm() {
		beep -f 1500 -l 200;beep -f 1550 -l 200;beep -f 1500 -l 200;beep -f 1550 -l 200;beep -f 1500 -l 200;beep -f 1550 -l 200;beep -f 1500 -l 200;beep -f 1550$
	}

	# Restoring Connectivity
	resolve() {
		clear
		echo "$MESSAGE1" | tee /dev/fd/3
		sudo ifconfig $ADAPTER1 up;sudo dhclient -r $ADAPTER1;sleep 5;sudo dhclient $ADAPTER1
		echo "$MESSAGE2"
		sleep 120
	}

	# Execution of work
	while true; do
		if [[ "$(cat /sys/class/net/${ADAPTER1}/operstate)" != "up" ]]; then
			alarm
			clear
			echo "================================================================================" 
			echo "$MESSAGE3 - $TODAY"                                                               | tee /dev/fd/3
			echo "================================================================================"
			sleep 10
			resolve
		else
			clear
			echo "================================================================================" 
			echo "$MESSAGE4 - $TODAY - IPv4 Addr: $IPv4ExternalAddr1 - IPv6 Addr: $IPv6ExternalAddr1" | tee /dev/fd/3
			echo "================================================================================" 
			break
		fi
	done
}


## MAIN
# Create a log file with current date and time
touch ${LOG_FILE}

# Redirect outputs
exec 3>&1 1>>${LOG_FILE} 2>&1

# Check for command line options
while getopts "c" opt; do
  case $opt in
    c)
      # Check internet connection
	  printf "\nChecking internet connection\n\n" 1>&3
	  check_internet
      ;;
    \?)
      echo "Invalid option: -$OPTARG" 1>&3
      ;;
  esac
done


# Start installation message
printf "\nConfiguring Kali Desktop\n\n" 1>&3
printf "\nThis may take some time and the system may appear to be unresponsive\n\n" 1>&3
printf "\nPlease be patient\n\n" 1>&3

# Add Repositories
printf "Adding Repositories\n" | tee /dev/fd/3
#sudo add-apt-repository -y ppa:unit193/encryption
#sudo add-apt-repository -y ppa:yubico/stable
#sudo add-apt-repository -y ppa:nextcloud-devs/client
printf "Complete\n\n" | tee /dev/fd/3

# Update the base OS
printf "Updating base OS\n" | tee /dev/fd/3
sudo apt-get update | tee /dev/fd/3
sudo apt-get -y install software-properties-common | tee /dev/fd/3
sudo apt-get -y dist-upgrade | tee /dev/fd/3
sudo apt-get -y install python3 | tee /dev/fd/3
printf "Complete\n\n" | tee /dev/fd/3

# Add toolsets
sudo apt-get -y install kali-tools-information-gathering | tee /dev/fd/3
sudo apt-get -y install kali-linux-large | tee /dev/fd/3

# Install VirtualBox Guest Additions:
printf "Installing VirtualBox Guest Additions\n" | tee /dev/fd/3
sudo apt-get -y install virtualbox-guest-dkms | tee /dev/fd/3
sudo apt-get -y install virtualbox-guest-x11 | tee /dev/fd/3
printf "Complete\n\n" | tee /dev/fd/3

# Install Tor Browser:
printf "Installing TOR browser bundle\n" | tee /dev/fd/3
## You may need this if you get a key error
# gpg --homedir "$HOME/.local/share/torbrowser/gnupg_homedir" --refresh-keys --keyserver keyserver.ubuntu.com
sudo apt-get -y install torbrowser-launcher | tee /dev/fd/3
printf "Complete\n\n" | tee /dev/fd/3

# GTKHash:
printf "Installing GTKHash\n" | tee /dev/fd/3
sudo snap install gtkhash | tee /dev/fd/3
printf "Complete\n\n" | tee /dev/fd/3

# Veracrypt:
printf "Installing Veracrypt\n" | tee /dev/fd/3
sudo apt-get -y install libwxgtk3.0-gtk3-0v5 | tee /dev/fd/3
sudo apt-get -y install exfat-fuse exfat-utils | tee /dev/fd/3
sudo apt-get -y install veracrypt | tee /dev/fd/3
printf "Complete\n\n" | tee /dev/fd/3

# Onionshare:
printf "Installing Onionshare\n" | tee /dev/fd/3
sudo snap install onionshare | tee /dev/fd/3
sudo snap connect onionshare:removable-media | tee /dev/fd/3
printf "Complete\n\n" | tee /dev/fd/3

# KeepassXC:
printf "Installing KeePassXC\n" | tee /dev/fd/3
sudo snap install keepassxc | tee /dev/fd/3
sudo snap connect keepassxc:raw-usb | tee /dev/fd/3
sudo snap connect keepassxc:removable-media | tee /dev/fd/3
printf "Complete\n\n" | tee /dev/fd/3

#Yubikey:
printf "Installing Yubikey\n" | tee /dev/fd/3
sudo apt-get -y install yubikey-manager | tee /dev/fd/3
sudo apt-get -y install libykpers-1-1 | tee /dev/fd/3
##For yubikey authorization
sudo apt-get -y install libpam-u2f | tee /dev/fd/3
sudo wget https://raw.githubusercontent.com/Yubico/libu2f-host/master/70-u2f.rules /etc/udev/rules.d/70-u2f.rules | tee /dev/fd/3
sudo mkdir -p ~/.config/Yubico | tee /dev/fd/3
printf "Complete\n\n" | tee /dev/fd/3

# Nextcloud:
printf "Installing Nextcloud Client\n" | tee /dev/fd/3
sudo apt-get -y install nextcloud-client | tee /dev/fd/3
printf "Complete\n\n" | tee /dev/fd/3

# Load OSINT tools scripts
printf "Installing OSINT tools and scripts\n" | tee /dev/fd/3
cd ~/Documents 
git clone https://github.com/rdbh/osint.git | tee /dev/fd/3
cd osint
sudo chmod 755 *.sh
cd install
sudo chmod 755 *.sh
bash jupyter-install.sh
printf "Complete\n\n" | tee /dev/fd/3

# Cleanup
printf "Cleaning up\n" | tee /dev/fd/3
sudo apt-get -y autoremove | tee /dev/fd/3
sudo apt-get -y clean | tee /dev/fd/3
printf "Complete\n\n" | tee /dev/fd/3

printf "\n\tPress [Enter] to reboot\n" 1>&3
read throwaway

sudo reboot