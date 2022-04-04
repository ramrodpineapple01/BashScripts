#!/bin/bash
sudo apt update
sudo apt -y full-upgrade
sudo apt -y autoremove

# Disable this if OS doesn't support snaps
sudo snap refresh