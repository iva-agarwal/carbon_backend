#!/bin/bash

set -e  # Exit immediately if a command fails

# Create a writable directory
mkdir -p /tmp/chrome
cd /tmp/chrome

# Download the correct Chrome package
wget -O chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

# Install Chrome in a writable directory
dpkg -x chrome.deb /tmp/chrome

# Set Chrome binary path
export CHROME_BIN="/tmp/chrome/opt/google/chrome/google-chrome"

# Verify installation
$CHROME_BIN --version
