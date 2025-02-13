#!/bin/bash

set -e  # Exit immediately if any command fails

# Create a temporary directory for Chrome
mkdir -p /tmp/chrome
cd /tmp/chrome

# Download Google Chrome (official stable version)
wget -O chrome-linux64.zip https://dl.google.com/linux/chrome/linux_signing_key.pub

# Unzip Chrome
unzip chrome-linux64.zip
chmod +x chrome-linux64/chrome

# Set Chrome path in environment variables
export CHROME_BIN="/tmp/chrome/chrome-linux64/chrome"

# Verify installation
$CHROME_BIN --version
