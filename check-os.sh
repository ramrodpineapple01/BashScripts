#!/bin/bash
# Simple check for architectures in current use

raspi() {
    printf "Raspberry Pi"
  }

amd64(){
    printf "64-bit architecture"
  }

proc_arch=$(uname -m)

case $proc_arch in

    x86_64)
	  amd64
	  ;;

    aarch64)
	  raspi
	  ;;
	  
	*)
	  printf "/n/n Unknown architecture %s" "$proc_arch"
	  ;;
	  
esac

printf "\nEnd of script\n"
