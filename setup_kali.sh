#!/bin/bash
# Kali VM base setup script
# R. Dawson 2022
# v2.0.0

## Variables
#TODO: ADAPTER: This works for a VM, but needs a better method
ADAPTER1=$(ls /sys/class/net | grep e) 	# 1st Ethernet adapter on VM
BRANCH="main"							# Default to main branch
CHECK_IP="8.8.8.8"						# Test ping to google DNS
DATE_VAR=$(date +'%y%m%d-%H%M')			# Today's Date and time
LOG_FILE="${DATE_VAR}_install.log"  	# Log File name
PACKAGE="snap" 							# Install snaps by default
VPN_INSTALL="false"						# Do not install VPN clients by default

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

check_root() {
  # Check to ensure script is not run as root
  if [[ "${UID}" -eq 0 ]]; then
    UNAME=$(id -un)
    printf "\nThis script should not be run as root.\n\n" >&2
    usage
  fi
}

echo_out() {
  # Get input from stdin OR $1
  local MESSAGE=${1:-$(</dev/stdin)}
  
  # Check to see if we need a \n
  if [[ "${2}" == 'n' ]]; then
    :
  else
    MESSAGE="${MESSAGE}\n"
  fi
  
  # Decide if we output to console and log or just log
  if [[ "${VERBOSE}" = 'true' ]]; then
    printf "${MESSAGE}" | tee /dev/fd/3
  else 
    printf "${MESSAGE}" >> ${LOG_FILE}
  fi
}

install_airvpn () {
  printf "Installing AirVPN client.\n" | tee /dev/fd/3
  wget -qO - https://eddie.website/repository/keys/eddie_maintainer_gpg.key | sudo apt-key add - | echo_out
  echo "deb http://eddie.website/repository/apt stable main" | sudo tee /etc/apt/sources.list.d/eddie.website.list | echo_out
  sudo apt-get update | echo_out
  sudo apt-get -y install eddie-ui | echo_out
  printf "AirVPN Installation Complete.\n\n" | tee /dev/fd/3
}

install_flatpak () {
  printf "Installing Flatpak.\n" | tee /dev/fd/3
  sudo apt-get -y install flatpak | echo_out
  sudo apt-get -y install gnome-software-plugin-flatpak | echo_out
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo | echo_out
  printf "Flatpak Installation Complete.\n\n" | tee /dev/fd/3
}

install_ivpn() {
  printf "Installing IVPN client.\n" | tee /dev/fd/3
  wget -O - https://repo.ivpn.net/stable/ubuntu/generic.gpg | gpg --dearmor > ~/ivpn-archive-keyring.gpg | echo_out
  sudo mv ~/ivpn-archive-keyring.gpg /usr/share/keyrings/ivpn-archive-keyring.gpg | echo_out
  wget -O - https://repo.ivpn.net/stable/ubuntu/generic.list | sudo tee /etc/apt/sources.list.d/ivpn.list | echo_out
  sudo apt update | echo_out
  sudo apt-get -y install ivpn-ui | echo_out
  printf "IVPN Installation Complete.\n\n" | tee /dev/fd/3
}

install_mullvad () {
  printf "Installing Mullvad VPN client.\n" | tee /dev/fd/3
  wget --content-disposition https://mullvad.net/download/app/deb/latest | echo_out
  MV_PACKAGE=$(cat ls | grep Mullvad)
  sudo apt-get -y install ./"${MV_PACKAGE}" | echo_out
  printf "Mullvad Installation VPN Complete.\n\n" | tee /dev/fd/3
}

install_nordvpn () {
  printf "Installing Nord VPN client.\n" | tee /dev/fd/3
  sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh) | echo_out
  sudo usermod -aG nordvpn $USER | echo_out
  printf "Nord VPN Installation Complete.\n\n" | tee /dev/fd/3
}

install_openvpn () {
  printf "Installing OpenVPNclient.\n" | tee /dev/fd/3
  sudo curl -fsSL https://swupdate.openvpn.net/repos/openvpn-repo-pkg-key.pub | gpg --dearmor > /etc/apt/trusted.gpg.d/openvpn-repo-pkg-keyring.gpg | echo_out
  sudo curl -fsSL https://swupdate.openvpn.net/community/openvpn3/repos/openvpn3-$DISTRO.list >/etc/apt/sources.list.d/openvpn3.list | echo_out
  sudo apt-get update | echo_out
  sudo apt-get -y install openvpn3 | echo_out
  printf "OpenVPN Installation Complete.\n\n" | tee /dev/fd/3
}

install_protonvpn () {
  printf "Installing ProtonVPNclient.\n" | tee /dev/fd/3
  wget https://protonvpn.com/download/protonvpn-stable-release_1.0.1-1_all.deb
  sudo apt install protonvpn-stable-release_1.0.1-1_all.deb | echo_out
  sudo apt update | echo_out
  sudo apt-get -y install protonvpn | echo_out
  printf "ProtonVPN Installation Complete.\n\n" | tee /dev/fd/3
}

usage() {
  echo "Usage: ${0} [-cfh] [-p VPN_name] " >&2
  echo "Sets up Kali with useful OSINT apps."
  #echo "Do not run as root."
  echo
  echo "-c 			Check internet connection before starting."
  echo "-f			Install Flatpak."
  echo "-h 			Help (this list)."
  echo "-p VPN_NAME	Install VPN client(s) or 'all'."
  echo "-v 			Verbose mode."
  exit 1
}

## MAIN
# Create a log file with current date and time
touch ${LOG_FILE}

# Redirect outputs
exec 3>&1 1>>${LOG_FILE} 2>&1

# Provide usage statement if no parameters
while getopts cdfhp:v OPTION; do
  case ${OPTION} in
	c)
	# Check for internet connection
	  check_internet "${CHECK_IP}"
	  ;;
	d)
	# Set installation to dev branch
	  BRANCH="dev"
	  echo_out "Branch set to dev branch"
	  ;;
	f)
	# Flag for flatpak installation
	  PACKAGE="flatpak"
	  echo_out "Flatpak use set to true"
	  install_flatpak
	  ;;  
	h)
	  usage
	  ;;
	p)
	  VPN_INSTALL="${OPTARG}"
	  ;;
	v)
      # Verbose is first so any other elements will echo as well
      VERBOSE='true'
      echo_out "Verbose mode on."
      ;;
    ?)
      echo "invalid option" >&2
      usage
      ;;
  esac
done

# Clear the options from the arguments
shift "$(( OPTIND - 1 ))"

# Start installation message
echo_out "Script version ${VERSION}\n"
printf "\nConfiguring Kali Desktop\n" 1>&3
printf "\nThis may take some time and the system may appear to be unresponsive\n" 1>&3
printf "\nPlease be patient\n\n" 1>&3
sudo :

# Add Repositories
printf "Adding Repositories\n" | tee /dev/fd/3
echo_out "1" n
sudo add-apt-repository -y multiverse
echo_out "\b2" n
sudo add-apt-repository -y ppa:unit193/encryption
echo_out "\b3" n
sudo add-apt-repository -y ppa:yubico/stable
echo_out "\b4"
sudo add-apt-repository -y ppa:nextcloud-devs/client
printf "Complete\n\n" | tee /dev/fd/3

# Update the base OS
printf "Updating base OS\n" | tee /dev/fd/3
sudo apt-get update | echo_out
sudo apt-get -y install software-properties-common | echo_out
sudo apt-get -y dist-upgrade | echo_out
sudo apt-get -y install apt-transport-https | echo_out
printf "Complete\n\n" | tee /dev/fd/3

# Install VirtualBox Guest Additions:
printf "Installing VirtualBox Guest Additions\n" | tee /dev/fd/3
sudo apt-get -y install dkms | echo_out
sudo apt-get -y install gcc | echo_out
sudo apt-get -y install make | echo_out
sudo apt-get -y install perl | echo_out
sudo apt-get -y install virtualbox-guest-additions-iso | echo_out
sudo mount -o loop /usr/share/virtualbox/VBoxGuestAdditions.iso /media/ | echo_out
/media/autorun.sh
printf "Complete\n\n" | tee /dev/fd/3

# Install Tor Browser:
printf "Installing TOR browser bundle\n" | tee /dev/fd/3
## You may need this if you get a key error
# gpg --homedir "$HOME/.local/share/torbrowser/gnupg_homedir" --refresh-keys --keyserver keyserver.ubuntu.com
case ${PACKAGE} in
  flatpak)
    flatpak install flathub com.github.micahflee.torbrowser-launcher -y
    ;;
  snap)
    ;;
  *)
    sudo apt-get -y install torbrowser-launcher | echo_out
	;;
esac

printf "Complete\n\n" | tee /dev/fd/3

# GTKHash:
printf "Installing GTKHash\n" | tee /dev/fd/3
sudo apt-get install -y gtkhash | echo_out
#sudo snap install gtkhash | tee /dev/fd/3
printf "Complete\n\n" | tee /dev/fd/3

# Veracrypt:
printf "Installing Veracrypt\n" | tee /dev/fd/3
sudo apt-get -y install libwxgtk3.0-gtk3-0v5 | echo_out
sudo apt-get -y install exfat-fuse exfat-utils | echo_out
# Use either of these options but not both
## Option 1
sudo apt-get -y install veracrypt | echo_out
## Option 2
#sudo wget https://launchpad.net/veracrypt/trunk/1.24-update7/+download/veracrypt-console-1.24-Update7-Ubuntu-20.04-amd64.deb
#sudo apt-get -y install ./veracrypt-console-1.24-Update7-Ubuntu-20.04-amd64.deb | tee /dev/fd/3
printf "Complete\n\n" | tee /dev/fd/3

# Onionshare:
#TODO: troubleshoot onionshare snap installation
printf "Installing Onionshare\n" | tee /dev/fd/3

case ${PACKAGE} in
  flatpak)
    flatpak install flathub org.onionshare.OnionShare -y | echo_out
	;;
  snap)
    sudo snap install onionshare | echo_out
    sudo snap connect onionshare:removable-media | echo_out
	;;
  *)
    # Github install ** TESTING ONLY **
    #curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python - | tee /dev/fd/3
    #git clone https://github.com/onionshare/onionshare.git | tee /dev/fd/3
    #cd onionshare/desktop
    #poetry install
    #poetry run ./scripts/get-tor-linux.py
    #curl -sSL https://go.dev/dl/go1.18.1.linux-amd64.tar.gz
    #sudo rm -rf /usr/local/go && tar -C /usr/local -xzf go1.18.1.linux-amd64.tar.gz
    #echo 'export PATH=$PATH:/usr/local/go/bin' | tee -a .bashrc .profile
	
	# Temporarily make this the default
    sudo snap install onionshare | echo_out
    sudo snap connect onionshare:removable-media | echo_out
	;;
esac
printf "Complete\n\n" | tee /dev/fd/3

# KeepassXC:
printf "Installing KeePassXC\n" | tee /dev/fd/3
#sudo apt-get -y install keepassxc | echo_out
#TODO: Confirm this works with 22.04
sudo snap install keepassxc | echo_out
sudo snap connect keepassxc:raw-usb | echo_out
sudo snap connect keepassxc:removable-media | echo_out
printf "Complete\n\n" | tee /dev/fd/3

#Yubikey:
printf "Installing Yubikey\n" | tee /dev/fd/3
sudo apt-get -y install yubikey-manager | echo_out
sudo apt-get -y install libykpers-1-1 | echo_out

#For yubikey authorization
sudo apt-get -y install libpam-u2f | echo_out
sudo wget https://raw.githubusercontent.com/Yubico/libu2f-host/master/70-u2f.rules -O /etc/udev/rules.d/70-u2f.rules | echo_out
#sudo mv 70-u2f.rules /etc/udev/rules.d/70-u2f.rules | tee /dev/fd/3
sudo mkdir -p ~/.config/Yubico | echo_out
printf "Complete\n\n" | tee /dev/fd/3

#Nextcloud:
printf "Installing Nextcloud Client\n\nThis can take a while\n" | tee /dev/fd/3
sudo apt-get -y install nextcloud-client | echo_out
printf "Complete\n\n" | tee /dev/fd/3

# VPN Clients
case ${VPN_INSTALL} in
  false)
    :
	;;
  all)
    install_airvpn
	install_ivpn
    install_mullvad
    install_openvpn
	install_nordvpn
	install_protonvpn
    ;;
  airvpn)
    install_airvpn
	;;
  ivpn)
    install_ivpn
	;;
  mullvad)
    install_mullvad
	;;
  nordvpn)
    install_nordvpn
	;;
  openvpn)
    install_openvpn
	;;
  protonvpn)
    install_protonvpn
	;;
  *)
    printf "\nUnrecognized VPN option ${VPN_INSTALL}.\n" 
	;;
esac

# Create update.sh file
printf "Creating update.sh\n" | tee /dev/fd/3
cat << EOF > ~/update.sh
sudo apt update
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove --purge
sudo apt-get -y clean
EOF
sudo chmod 744 ~/update.sh
printf "Complete\n\n" | tee /dev/fd/3

# Load OSINT tools scripts
printf "Installing OSINT tools and scripts\n" | tee /dev/fd/3
cd "${HOME}"
git clone https://github.com/rdbh/osint.git | echo_out
cd osint
sudo chmod 755 *.sh
cd install
sudo chmod 755 *.sh
bash jupyter-install.sh
printf "Complete\n\n" | tee /dev/fd/3

# Cleanup
printf "Cleaning up\n" | tee /dev/fd/3
sudo apt-get -y autoremove --purge | echo_out
sudo apt-get -y clean | echo_out
sudo rm 70-u2f.rules | echo_out # May not exist
printf "Complete\n\n" | tee /dev/fd/3

printf "\n\tPress [Enter] to reboot\n" 1>&3
read throwaway

sudo reboot