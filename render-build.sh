#!/usr/bin/env bash

# Set up Chromium in a writable directory
mkdir -p /tmp/chrome
cd /tmp/chrome

# Download a prebuilt Chromium binary
wget -q https://storage.googleapis.com/chrome-for-testing-public/119.0.6045.159/linux64/chrome-linux64.zip
unzip chrome-linux64.zip

# Set execute permissions
chmod +x chrome-linux64/chrome

# Confirm that Chrome is available
/tmp/chrome/chrome-linux64/chrome --version
