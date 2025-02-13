#!/bin/bash
set -e  # Exit if any command fails

# Install required dependencies
apt-get update && apt-get install -y \
    wget \
    curl \
    unzip \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libxkbcommon-x11-0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpango-1.0-0 \
    libpangocairo-1.0-0

# Create directories
mkdir -p /tmp/chrome
mkdir -p /opt/chrome
mkdir -p /opt/chromedriver

# Download and install Chrome
echo "Downloading Chrome..."
wget -q -O /tmp/chrome/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
dpkg -x /tmp/chrome/chrome.deb /opt/chrome

# Make Chrome executable
chmod +x /opt/chrome/opt/google/chrome/google-chrome

# Set Chrome binary path
export CHROME_BIN="/opt/chrome/opt/google/chrome/google-chrome"

# Download compatible ChromeDriver
CHROME_VERSION=$($CHROME_BIN --version | cut -d ' ' -f 3 | cut -d '.' -f 1)
echo "Chrome version: $CHROME_VERSION"

CHROMEDRIVER_VERSION=$(curl -s "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$CHROME_VERSION")
echo "Installing ChromeDriver version: $CHROMEDRIVER_VERSION"

wget -q -O /tmp/chromedriver.zip "https://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip"
unzip -q /tmp/chromedriver.zip -d /opt/chromedriver
chmod +x /opt/chromedriver/chromedriver

# Create symlinks
ln -sf /opt/chromedriver/chromedriver /usr/local/bin/chromedriver
ln -sf $CHROME_BIN /usr/local/bin/google-chrome

# Verify installation
echo "Verifying Chrome installation..."
$CHROME_BIN --version
chromedriver --version

# Clean up
rm -rf /tmp/chrome/chrome.deb /tmp/chromedriver.zip

# Set permanent environment variable
echo "export CHROME_BIN=/opt/chrome/opt/google/chrome/google-chrome" >> ~/.bashrc
echo "export PATH=/opt/chromedriver:\$PATH" >> ~/.bashrc

echo "Installation completed successfully!"
