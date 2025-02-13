#!/usr/bin/env bash

# Create a directory for Chrome
mkdir -p /opt/chrome
cd /opt/chrome

# Download Chrome
wget -q https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_116.0.5845.187-1_amd64.deb

# Extract Chrome without installing via dpkg (since we can't use apt-get)
ar x google-chrome-stable_116.0.5845.187-1_amd64.deb
tar -xvf data.tar.xz

# Set Chrome binary path
mv usr/bin/google-chrome-stable /opt/chrome/google-chrome
chmod +x /opt/chrome/google-chrome

# Verify installation
/opt/chrome/google-chrome --version
