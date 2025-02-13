#!/bin/bash
set -e  # Exit if any command fails

echo "Creating directories..."
mkdir -p /opt/render/chrome
cd /opt/render/chrome

echo "Downloading Chrome..."
wget -q -O chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

echo "Installing Chrome..."
if [ ! -f chrome.deb ]; then
    echo "Chrome download failed!"
    exit 1
fi

dpkg -x chrome.deb /opt/render/chrome

echo "Setting Chrome binary path..."
CHROME_BIN="/opt/render/chrome/opt/google/chrome/google-chrome"
if [ ! -f "$CHROME_BIN" ]; then
    echo "Chrome binary not found at expected location!"
    exit 1
fi

chmod +x $CHROME_BIN

echo "Downloading ChromeDriver..."
CHROME_VERSION=$($CHROME_BIN --version | cut -d ' ' -f 3 | cut -d '.' -f 1)
CHROMEDRIVER_VERSION=$(curl -s "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$CHROME_VERSION")

if [ -z "$CHROMEDRIVER_VERSION" ]; then
    echo "Failed to get ChromeDriver version!"
    exit 1
fi

wget -q -O chromedriver.zip "https://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip"

if [ ! -f chromedriver.zip ]; then
    echo "ChromeDriver download failed!"
    exit 1
fi

unzip -q chromedriver.zip
chmod +x chromedriver

echo "Moving ChromeDriver to path..."
mv chromedriver /usr/local/bin/

echo "Setting environment variables..."
export CHROME_BIN="$CHROME_BIN"
echo "export CHROME_BIN=$CHROME_BIN" >> ~/.bashrc

echo "Cleaning up..."
rm chrome.deb chromedriver.zip

echo "Verifying installations..."
if ! $CHROME_BIN --version; then
    echo "Chrome verification failed!"
    exit 1
fi

if ! chromedriver --version; then
    echo "ChromeDriver verification failed!"
    exit 1
fi

echo "Installation completed successfully!"
