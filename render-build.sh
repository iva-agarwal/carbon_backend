#!/bin/bash

set -e  # Exit if any command fails

# Install required dependencies
apt-get update && apt-get install -y wget curl unzip libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libxkbcommon-x11-0

# Create a writable directory
mkdir -p /tmp/chrome
cd /tmp/chrome

# Download and install Chrome
wget -O chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
dpkg -x chrome.deb /tmp/chrome

# Set Chrome binary path
export CHROME_BIN="/tmp/chrome/opt/google/chrome/google-chrome"

# Verify Chrome installation
$CHROME_BIN --version
