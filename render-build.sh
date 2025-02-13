#!/bin/bash
set -e  # Exit if any command fails
set -x  # Enable debug output

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

echo "Getting Chrome version..."
CHROME_VERSION=$($CHROME_BIN --version)
echo "Chrome version: $CHROME_VERSION"

# Extract major version more reliably
CHROME_MAJOR_VERSION=$(echo "$CHROME_VERSION" | sed -n 's/.*Chrome \([0-9]*\).*/\1/p')
echo "Chrome major version: $CHROME_MAJOR_VERSION"

if [ -z "$CHROME_MAJOR_VERSION" ]; then
    echo "Failed to extract Chrome version!"
    exit 1
fi

echo "Downloading ChromeDriver..."
# Try known compatible versions in descending order
# List of recent stable Chrome versions
VERSIONS_TO_TRY="120 119 118"

for VERSION in $VERSIONS_TO_TRY; do
    echo "Trying ChromeDriver version $VERSION..."
    CHROMEDRIVER_VERSION=$(curl -s "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$VERSION")
    
    if [ ! -z "$CHROMEDRIVER_VERSION" ] && ! echo "$CHROMEDRIVER_VERSION" | grep -q "Error"; then
        echo "Found compatible ChromeDriver version: $CHROMEDRIVER_VERSION"
        break
    fi
done

if [ -z "$CHROMEDRIVER_VERSION" ] || echo "$CHROMEDRIVER_VERSION" | grep -q "Error"; then
    echo "Failed to find compatible ChromeDriver version, trying latest stable..."
    CHROMEDRIVER_VERSION=$(curl -s "https://chromedriver.storage.googleapis.com/LATEST_RELEASE")
fi

if [ -z "$CHROMEDRIVER_VERSION" ] || echo "$CHROMEDRIVER_VERSION" | grep -q "Error"; then
    echo "Failed to get ChromeDriver version!"
    exit 1
fi

echo "ChromeDriver version to be installed: $CHROMEDRIVER_VERSION"

# Download with retry logic
MAX_RETRIES=3
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if wget -q -O chromedriver.zip "https://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip"; then
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "Download attempt $RETRY_COUNT failed. Retrying..."
    sleep 2
done

if [ ! -f chromedriver.zip ]; then
    echo "ChromeDriver download failed after $MAX_RETRIES attempts!"
    exit 1
fi

echo "Extracting ChromeDriver..."
unzip -q chromedriver.zip
if [ ! -f chromedriver ]; then
    echo "ChromeDriver extraction failed!"
    exit 1
fi

chmod +x chromedriver

echo "Moving ChromeDriver to path..."
mv chromedriver /usr/local/bin/

echo "Setting environment variables..."
export CHROME_BIN="$CHROME_BIN"
echo "export CHROME_BIN=$CHROME_BIN" >> ~/.bashrc

echo "Cleaning up..."
rm chrome.deb chromedriver.zip

echo "Verifying installations..."
echo "Chrome version:"
$CHROME_BIN --version || { echo "Chrome verification failed!"; exit 1; }

echo "ChromeDriver version:"
chromedriver --version || { echo "ChromeDriver verification failed!"; exit 1; }

echo "Installation completed successfully!"
