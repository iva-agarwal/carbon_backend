#!/bin/bash
set -e  # Exit if any command fails
set -x  # Enable debug output

# Define a writable directory for our binaries
CHROME_DIR="/opt/render/chrome"
CHROMEDRIVER_DIR="$CHROME_DIR/chromedriver"

echo "Cleaning up any existing installation..."
if [ -d "$CHROMEDRIVER_DIR" ]; then
    rm -rf "$CHROMEDRIVER_DIR"/*  # Remove contents but keep directory
fi
rm -f "$CHROME_DIR"/*.deb "$CHROME_DIR"/*.zip  # Remove any leftover archives

echo "Creating directories..."
mkdir -p "$CHROME_DIR"
if [ ! -d "$CHROMEDRIVER_DIR" ]; then
    mkdir -p "$CHROMEDRIVER_DIR"
fi

cd "$CHROME_DIR"

echo "Downloading Chrome..."
wget -q -O chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

echo "Installing Chrome..."
if [ ! -f chrome.deb ]; then
    echo "Chrome download failed!"
    exit 1
fi

dpkg -x chrome.deb "$CHROME_DIR"

echo "Setting Chrome binary path..."
CHROME_BIN="$CHROME_DIR/opt/google/chrome/google-chrome"
if [ ! -f "$CHROME_BIN" ]; then
    echo "Chrome binary not found at expected location!"
    exit 1
fi

chmod +x "$CHROME_BIN"

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
CHROMEDRIVER_VERSION=$(curl -s "https://chromedriver.storage.googleapis.com/LATEST_RELEASE")

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

echo "Moving ChromeDriver..."
mv chromedriver "$CHROMEDRIVER_DIR/"

echo "Setting environment variables..."
export CHROME_BIN="$CHROME_BIN"
export PATH="$CHROMEDRIVER_DIR:$PATH"
echo "export CHROME_BIN=$CHROME_BIN" >> ~/.bashrc
echo "export PATH=$CHROMEDRIVER_DIR:\$PATH" >> ~/.bashrc
source ~/.bashrc  # Apply changes to the current shell

echo "Cleaning up..."
rm -f chrome.deb chromedriver.zip

echo "Verifying installations..."
echo "Chrome version:"
$CHROME_BIN --version || { echo "Chrome verification failed!"; exit 1; }

echo "ChromeDriver version:"
"$CHROMEDRIVER_DIR/chromedriver" --version || { echo "ChromeDriver verification failed!"; exit 1; }

echo "Installation completed successfully!"
