#!/bin/bash
# Script for adding an external drive as the data drive for nextcloud snap

# Disable nextcloud while moving files
sudo snap disable nextcloud

# Is this a new drive?
sudo fdisk -l
##TODO: create a new partition

#get the UUID from blkid
sudo blkid


# Format the new drive
sudo mkfs.ext4 /dev/sda1

# Create the mount point
read -p 'Enter mount point: ' mount_point

sudo mkdir $mount_point
sudo chown -R root:root $mount_point
sudo chmod 0770 $mount_point

# Add UUID to fstab
UUID=$drive_uuid $mount_point ext4 auto,user,rw,exec 0 0
##sudo mount -t auto /dev/sdb1 $mount_point


# Move /data to the new directory
# Assumes /data is in the default location
sudo mv /var/snap/nextcloud/common/nextcloud/data $mount_point 

# Edit the nextcloud config
sudo nano /var/snap/nextcloud/current/nextcloud/config/config.php

# Copy existing data dir to new dir
cp 

# Re-enble nextcloud
sudo snap enable nextcloud
