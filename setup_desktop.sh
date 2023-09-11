#!/bin/bash
# Ubuntu VM desktop setup script
# R. Dawson 2021-2023
VERSION="2.8.9"

## Variables
#TODO: ADAPTER: This works for a VM, but needs a better method
ADAPTER1=$(ls /sys/class/net | grep e) 	# 1st Ethernet adapter on VM
BRANCH="main"							    # Default to main branch
CHECK_IP="8.8.8.8"						# Test ping to google DNS
DATE_VAR=$(date +'%y%m%d-%H%M')	# Today's Date and time
REBOOT_COMPLETE="true"          # Reboot when complete by default
LOG_FILE="${DATE_VAR}_desktop_install.log"  	# Log File name
PACKAGE="apt" 							  # Install snaps by default
RTP_ENABLE="false"            # Do not enable RTP by default
VPN_INSTALL="false"						# Do not install VPN clients by default
WIFI_TOOLS="false"						# Do not install wifi tools by default

## Functions
check_internet() {
	# SETTINGS
	TEST="${1}"       

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
		sudo ifconfig $ADAPTER1 up; sudo dhclient -r $ADAPTER1; sleep 5; sudo dhclient $ADAPTER1
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

install_browsers () {
  printf "Installing Additional Browsers.\n" | tee /dev/fd/3
  # Brave
  echo_out "Brave Browser"
  sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg | echo_out
  echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
  sudo apt update
  sudo apt-get -y install brave-browser

  # Chrome
  wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo apt-get -y install google-chrome-stable_current_amd64.deb

  printf "Browser Installation Complete.\n\n" | tee /dev/fd/3
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

install_wifi_tools() {
  printf "Installing WiFi tools.\n" | tee /dev/fd/3
  wget -O - https://www.kismetwireless.net/repos/kismet-release.gpg.key | sudo tee /etc/apt/trusted.gpg.d/kismet.asc | echo_out
  echo 'deb https://www.kismetwireless.net/repos/apt/release/jammy jammy main' | sudo tee /etc/apt/sources.list.d/kismet.list | echo_out
  sudo apt update
  sudo apt-get -y install kismet
  pip install kismet_rest
  
  # Kismon installation
  #sudo apt-get -y install python3-gi 
  #sudo apt-get -y install gir1.2-gtk-3.0
  #sudo apt-get -y install gir1.2-gdkpixbuf-2.0 
  #sudo apt-get -y install python3-cairo 
  sudo apt-get -y install python3-simplejson
  sudo apt-get -y install gir1.2-osmgpsmap-1.0
  cd ~
  git clone https://github.com/radawson/kismon.git kismon
  cd kismon
  sudo make install
  printf "Kismet and Kismon Installation Complete.\n\n" | tee /dev/fd/3

}

usage() {
  echo "Usage: ${0} [-bcfhrsvw] [-p VPN_name] " >&2
  echo "Sets up Ubuntu Desktop with useful apps."
  #echo "Do not run as root."
  echo
  echo "-b 			Install multiple browsers."
  echo "-c 			Check internet connection before starting."
  echo "-f			Install Flatpak (not Snaps)."
  echo "-h 			Help (this list)."
  echo "-p      VPN_NAME	  Install VPN client(s) or 'all'."
  echo "-r      Install and enable RDP."
  echo "-s			Install Snaps (not flatpak)"
  echo "-v 			Verbose mode."
  echo "-w			WiFi tools (kismet)."
  exit 1
}

## MAIN
# Create a log file with current date and time
touch ${LOG_FILE}

# Provide usage statement if no parameters
while getopts bcdfhp:rsvwx OPTION; do
  case ${OPTION} in
  b)
    # Install browser packages
      install_browsers
      ;;
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
	  ;;  
	h)
  # Help statement
	  usage
	  ;;
	p)
	  VPN_INSTALL="${OPTARG}"
    echo_out "${OPTARG} configured for VPN client install"
	  ;;

  r)
    RDP_ENABLE="true"
    echo_out "Remote Desktop Protocol daemon installation enabled"
    ;;
	s)
	# Flag for snap installation
	  PACKAGE="snap"
	  echo_out "Snap use set to true"
	  ;; 
	v)
    VERBOSE='true'
    echo_out "Verbose mode on."
    ;;
	w)
	  WIFI_TOOLS='true'
	  echo_out "WiFi tools will be installed"
	  ;;
  x)
    REBOOT_COMPLETE="false"
    echo_out "Reboot on complete disabled"
    ;;
  ?)
    echo "invalid option" >&2
    usage
    ;;
  esac
done

# Clear the options from the arguments
shift "$(( OPTIND - 1 ))"

# Redirect outputs
exec 3>&1 1>>${LOG_FILE} 2>&1

# Start installation message
echo_out "Script version ${VERSION}\n"
printf "\nConfiguring Ubuntu Desktop\n" 1>&3
printf "\nThis may take some time and the system may appear to be unresponsive\n" 1>&3
printf "\nPlease be patient\n\n" 1>&3

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

# Install git
if [[ $(which git) == "" ]]; then
  printf "Installing git\n" | tee /dev/fd/3
  sudo apt-get -y install git
  printf "Complete\n\n" | tee /dev/fd/3
fi

# Install flatpak
if [[ ${PACKAGE} == "flatpak" ]]; then
  printf "Installing flatpak\n" | tee /dev/fd/3
  install_flatpak
  printf "Complete\n\n" | tee /dev/fd/3
fi

# Install VM management software:
printf "Checking for Virtual Machine\n\n" | tee /dev/fd/3
SYSTEM_HW="$(sudo dmidecode -s system-product-name)"
case ${SYSTEM_HW} in 
  Parallels*)
    printf "\tInstalling VM management software\n" | tee /dev/fd/3
    sudo apt-get -y install prltools-linux | echo_out
    printf "Complete\n\n" | tee /dev/fd/3
    ;;
  QEMU*)
    printf "\tInstalling VM management software\n" | tee /dev/fd/3
    sudo apt-get -y install qemu-guest-agent | echo_out
    printf "Complete\n\n" | tee /dev/fd/3
    ;;
  VirtualBox*|Virtualbox*)
    printf "\tInstalling VirtualBox Guest Additions\n" | tee /dev/fd/3
	  sudo apt-get -y install dkms | echo_out
	  sudo apt-get -y install gcc | echo_out
	  sudo apt-get -y install make | echo_out
	  sudo apt-get -y install perl | echo_out
	  sudo apt-get -y install virtualbox-guest-additions-iso | echo_out
	  sudo mount -o loop /usr/share/virtualbox/VBoxGuestAdditions.iso /media/ | echo_out
	  /media/autorun.sh
	  ;;
  VMware*)
    printf "\tInstalling VMWare Tools\n" | tee /dev/fd/3
    sudo apt install -y --reinstall open-vm-tools-desktop fuse3
    ;;
  *)
    echo_out "\tNo virtualization recognized.\n"
	;;
esac
printf "Complete\n\n" | tee /dev/fd/3

# Install python PIP
printf "Installing python PIP\n" | tee /dev/fd/3
sudo apt-get -y install python3-pip | echo_out
printf "Complete\n\n" | tee /dev/fd/3

# Install Tor Browser:
printf "Installing TOR browser bundle\n" | tee /dev/fd/3
## You may need this if you get a key error
# gpg --homedir "$HOME/.local/share/torbrowser/gnupg_homedir" --refresh-keys --keyserver keyserver.ubuntu.com
case ${PACKAGE} in
  flatpak)
    flatpak install flathub com.github.micahflee.torbrowser-launcher -y | echo_out
    ;;
  snap)
    sudo snap install tor-mkg20001 | echo_out
    ;;
  *)
    mkdir ~/Desktop | echo_out
	cd ~/Desktop
  wget https://www.torproject.org/dist/torbrowser/11.5.2/tor-browser-linux64-11.5.2_en-US.tar.xz | echo_out
	tar -xvf tor-browser-linux64-11.5.2_en-US.tar.xz | echo_out
	rm tor-browser-linux64-11.5.2_en-US.tar.xz | echo_out
	ln ./tor-browser_en-US/start-tor-browser.desktop /usr/share/applications/ | echo_out
  TOR_INSTALL=$(ls | grep tor)
  cd ${TOR_INSTALL}
  ./start-tor-browser.desktop --register-app | echo_out
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
printf "\nA warning about a missing repository 'exfat-utils' is expected behavior for Ubuntu 22.04\n\n" | tee /dev/fd/3
sudo apt-get -y install libwxgtk3.0-gtk3-0v5 | echo_out
sudo apt-get -y install exfat-fuse exfat-utils | echo_out
# Use either of these options but not both
## Option 1
sudo apt-get -y install veracrypt | echo_out
## Option 2
#sudo wget https://launchpad.net/veracrypt/trunk/1.25.9/+download/veracrypt-1.25.9-Ubuntu-22.04-amd64.deb
#sudo apt-get -y install ./veracrypt*.deb | tee /dev/fd/3
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

# Nextcloud:
printf "Installing Nextcloud Client\n\nThis can take a while\n" | tee /dev/fd/3
sudo apt-get -y install nextcloud-client | echo_out
printf "Complete\n\n" | tee /dev/fd/3

# OnlyOffice:
printf "Installing OnlyOffice\n" | tee /dev/fd/3

case ${PACKAGE} in
  flatpak)
    flatpak install flathub org.onlyoffice.desktopeditors -y | echo_out
	;;
  *)
    sudo snap install onlyoffice-desktopeditors | echo_out
	;;
esac
printf "Complete\n\n" | tee /dev/fd/3

# Remote Desktop Protocol
if [[ RDP_ENABLE == "true" ]]; then
  printf "Installing and Enabling RDP\n" | tee /dev/fd/3
  sudo apt-get -y install xrdp | echo_out
  sudo systemctl enable xrdp --now | echo_out
  printf "Complete\n\n" | tee /dev/fd/3
fi

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

# WiFi Tools
if [[ ${WIFI_TOOLS} == "true" ]]; then
  install_wifi_tools
fi  

# Create update.sh file
printf "Creating update.sh\n" | tee /dev/fd/3
cat << @EOF > ~/update.sh
#!/bin/bash
sudo apt-get update
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove --purge
sudo apt-get -y clean
echo "Update complete"
@EOF
sudo chmod 744 ~/update.sh
printf "Complete\n\n" | tee /dev/fd/3

# Cleanup
printf "Cleaning up\n" | tee /dev/fd/3
sudo apt-get -y autoremove --purge | echo_out
sudo apt-get -y clean | echo_out
sudo rm 70-u2f.rules | echo_out # May not exist
printf "Complete\n\n" | tee /dev/fd/3

# Flatpak message
if [[ ${PACKAGE} == "flatpak" ]]; then
  printf "Flatpak apps will be visible in Launcher after reboot\n" | tee /dev/fd/3
fi

# Reboot by default
if [[ ${REBOOT_COMPLETE} == "true" ]]; then
  printf "\n\tPress [Enter] to reboot\n" 1>&3
  read throwaway
  sudo reboot
fi