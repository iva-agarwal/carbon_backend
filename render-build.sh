#!/bin/bash
set -e  # Exit if any command fails

echo "Creating directories..."
mkdir -p /opt/render/chrome
cd /opt/render/chrome

echo "Downloading Chrome..."
wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
dpkg -x chrome-stable_current_amd64.deb /opt/render/chrome

echo "Setting Chrome binary path..."
CHROME_BIN="/opt/render/chrome/opt/google/chrome/google-chrome"
chmod +x $CHROME_BIN

echo "Downloading ChromeDriver..."
CHROME_VERSION=$($CHROME_BIN --version | cut -d ' ' -f 3 | cut -d '.' -f 1)
CHROMEDRIVER_VERSION=$(curl -s "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$CHROME_VERSION")
wget -q -O chromedriver.zip "https://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip"
unzip -q chromedriver.zip
chmod +x chromedriver

echo "Moving ChromeDriver to path..."
mv chromedriver /usr/local/bin/

echo "Setting environment variables..."
export CHROME_BIN="$CHROME_BIN"
echo "export CHROME_BIN=$CHROME_BIN" >> ~/.bashrc

echo "Cleaning up..."
rm chrome-stable_current_amd64.deb chromedriver.zip

echo "Verifying installations..."
$CHROME_BIN --version || echo "Chrome verification failed"
chromedriver --version || echo "ChromeDriver verification failed"

echo "Installation completed!"
