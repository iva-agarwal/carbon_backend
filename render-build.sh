#!/usr/bin/env bash

# Update package lists
apt-get update 

# Install Google Chrome
apt-get install -y wget curl unzip
wget -q -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt-get install -y /tmp/chrome.deb

# Verify Installation
google-chrome --version
