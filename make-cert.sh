# Nebula certificate management script
# (C) Richard Dawson 2021

# Functions
## Log ip address and name
log() {
  log_string="${1},${2},${3}"
  sudo chmod 0777 certs
  echo "$log_string" >> ./certs/cert-log.csv
  sudo chmod 0755 certs
}


#TODO make this accessible from the command line as well
read -p "Cert Name: " cert_name
read -p "IP Address (CIDR): " ip_address
read -p "Comment or tag: " cert_comment

printf "\nCreating certificate for %s\n\tat IP address %s\n" "$cert_name" "$ip_address"
read -n 1 -p "Press [Enter] to continue" continue

if [[ $continue = "" ]]; then
    printf "\n\n./nebula-cert sign -name %s -ip %s\n" "$cert_name" "$ip_address"
    sudo ./nebula-cert sign -name $cert_name -ip $ip_address
    # TODO: Distribution process
    log $cert_name $ip_address $cert_comment
    exit 0
else
    printf "\n\nExiting without creating certificate\n"
        exit 1
fi

