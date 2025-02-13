#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e 

# Create a temporary directory for Chrome
mkdir -p /tmp/chrome
cd /tmp/chrome

# Download Google Chrome (official stable version)
wget -O chrome-linux64.zip https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

# Unzip and install Chrome
ar x chrome-linux64.zip
tar -xf data.tar.xz
mv usr/bin/google-chrome-stable /usr/bin/google-chrome
chmod +x /usr/bin/google-chrome

# Verify installation
google-chrome --version
