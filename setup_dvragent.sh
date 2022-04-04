#!/bin/bash
# Install Microsoft Packages
wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Install .NET runtime
sudo apt-get update 
sudo apt-get install -y apt-transport-https 
sudo apt-get update 
sudo apt-get install -y aspnetcore-runtime-3.1

# Add ffmpeg4 repository
sudo add-apt-repository ppa:savoury1/ffmpeg4
sudo apt-get update
sudo apt-get install -y ffmpeg

# Add VLC (optional)
sudo apt-get install -y libvlc-dev vlc libx11-dev

# Install DVR Agent
wget https://ispyfiles.azureedge.net/downloads/Agent_Linux64_3_4_7_0.zip
unzip Agent_Linux64_3_4_7_0.zip -d ~/agent

cd agent
dotnet Agent.dll
