#!/bin/bash
# Kali VM base setup script
# R. Dawson 2022
VERSION="3.0.0"

## Variables
# Configuration Variables
BIN_PATH=${HOME}/Downloads/Programs
DOC_PATH=${HOME}/Documents/osint
JUP_PATH=/usr/share/jupyter

BRANCH="main"                           # Default to main branch
DATE_VAR=$(date +'%y%m%d-%H%M')         # Today's Date and time
LOG_FILE="${DATE_VAR}_kali_install.log" # Log File name
SCRIPT_ARGS=""
VERBOSE="false"

## Functions
check_root() {
  # Check to ensure script is not run as root
  if [[ "${UID}" -eq 0 ]]; then
    printf "\nThis script should not be run as root.\n\n" >&2
    usage
  fi
}

echo_out() {
  # Get input from stdin OR $1
  local MESSAGE=${1:-$(</dev/stdin)} | tr -d '\r'

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
    printf "${MESSAGE}" >>${LOG_FILE}
  fi
}

pause_for() {
  declare -i COUNT=${2}
  printf "${1}" | tee /dev/fd/3
  RUN="true"
  while [ ${RUN} == "true" ]; do
    printf "${COUNT}" | tee /dev/fd/3
    for ((i = 0; i <= ${COUNT}; i++)); do
      printf "\b" | tee /dev/fd/3
    done
    RUN="false"
  done
}

usage() {
  echo "Usage: ${0} [-bcfhrsvw] [-p VPN_name] " >&2
  echo "Sets up Kali Desktop with useful apps."
  #echo "Do not run as root."
  echo
  echo "-b 			Install multiple browsers."
  echo "-c 			Check internet connection before starting."
  echo "-f			Install Flatpak (not Snaps)."
  echo "-h 			Help (this list)."
  echo "-p VPN_NAME	  Install VPN client(s) or 'all'."
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
while getopts bcdfhp:rsvw OPTION; do
  case ${OPTION} in
  b)
    SCRIPT_ARGS="${SCRIPT_ARGS} -b"
    ;;
  c)
    SCRIPT_ARGS="${SCRIPT_ARGS} -c"
    ;;
  d)
    # Set installation to dev branch
    BRANCH="dev"
    echo_out "Branch set to dev branch"
    ;;
  f)
    SCRIPT_ARGS="${SCRIPT_ARGS} -f"
    ;;
  h)
    usage
    ;;
  p)
    SCRIPT_ARGS="${SCRIPT_ARGS} -p ${OPTARG}"
    ;;
  r)
    SCRIPT_ARGS="${SCRIPT_ARGS} -r"
    ;;
  s)
    SCRIPT_ARGS="${SCRIPT_ARGS} -s"
    ;;
  v)
    VERBOSE='true'
    SCRIPT_ARGS="${SCRIPT_ARGS} -v"
    echo_out "Verbose mode on."
    ;;
  w)
    SCRIPT_ARGS="${SCRIPT_ARGS} -w"
    ;;
  ?)
    echo "invalid option" >&2
    usage
    ;;
  esac
done

# Redirect outputs
exec 3>&1 1>>${LOG_FILE} 2>&1

# Clear the options from the arguments
shift "$((OPTIND - 1))"

# Start installation message
echo_out "Script version ${VERSION}\n"
# Get OS distribution
if [[ "${1}" == "Kali" ]]; then
  OS_NAME="Kali"
elif [[ "${1}" == "Ubuntu" ]]; then
  OS_NAME="Ubuntu"
else
  OS_NAME=$(lsb_release -a | grep '^Distributor' | cut -c 17-)
fi

printf "Installing for ${OS_NAME}" | tee /dev/fd/3
printf "Ctrl-C to abort" | tee /dev/fd/3
pause_for "Ctrl-C to abort" 9
printf "\nThis may take some time and the system may appear to be unresponsive\n" 1>&3
printf "\nPlease be patient\n\n" 1>&3
sudo :

# Create config file
touch ~/osint.config
echo DOC_PATH=${DOC_PATH} >~/osint.config
echo BIN_PATH=${BIN_PATH} >>~/osint.config
echo JUP_PATH=${JUP_PATH} >>~/osint.config

# Create program paths
mkdir -p "${BIN_PATH}"

# Download and run desktop script
printf "\nInstalling desktop from ${BRANCH} branch.\n\n" | tee /dev/fd/3
if [[ ${BRANCH} == "dev" ]]; then
  LINK="desktop-dev"
else
  LINK="desktop"
fi

cd ${HOME}
wget https://links.clockworx.tech/${LINK}
bash ${LINK} ${SCRIPT_ARGS} -x | echo_out
rm ${LINK}
printf "\nDesktop Script complete\n\n"

# Load OSINT tools scripts
printf "Installing OSINT tools and scripts\n" | tee /dev/fd/3
cd "${HOME}"
if [[ "${BRANCH}" == "dev" ]]; then
  git clone https://github.com/radawson/osint.git | echo_out
  cd osint
  sudo chmod 755 install.sh
  ./install.sh -d
else
  git clone https://github.com/rdbh/osint.git | echo_out
  cd osint
  sudo chmod 755 *.sh
  cd install
  sudo chmod 755 *.sh
  bash jupyter-install.sh
fi
printf "Complete\n\n" | tee /dev/fd/3

printf "\n\tPress [Enter] to reboot\n" 1>&3
read throwaway

sudo reboot
