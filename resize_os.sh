
#!/bin/bash
# Script for expanding VM os drive with LVM

sudo fdisk -l

printf "\n\tPress [ENTER] to continue\nCtrl-C to exit"
read throwaway

sudo cfdisk /dev/sda
sudo parted
# print
# resizepart
sudo pvresize /dev/sda3
sudo lvextend -r -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv
# sudo resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv

