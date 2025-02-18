#!/bin/bash

# Script to download and install the latest eza release for x86_64 Linux Musl

# Check if necessary tools are installed
if ! command -v curl &> /dev/null; then
  echo "Error: curl is required. Please install it (e.g., sudo apt install curl)."
  exit 1
fi

if ! command -v unzip &> /dev/null; then
  echo "Error: unzip is required. Please install it (e.g., sudo apt install unzip)."
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "Error: jq is required. Please install it (e.g., sudo apt install jq)."
  echo "Please install jq (e.g., sudo apt install jq, brew install jq)"
  exit 1
fi

# Define variables
REPO="eza-community/eza"
DOWNLOAD_URL="https://api.github.com/repos/$REPO/releases/latest"
INSTALL_DIR="$HOME/.local/bin"  # Where to install eza
EZA_EXECUTABLE="eza"           # Name of the eza executable
ZSH_PATH="$HOME/.zshrc"          # Path to your .zshrc file

# Get the latest release tag
echo "Fetching latest release information..."
TAG=$(curl -s "$DOWNLOAD_URL" | jq -r '.tag_name')

if [ -z "$TAG" ]; then
  echo "Error: Could not retrieve the latest release tag. Check your internet connection and GitHub API rate limits."
  exit 1
fi

echo "Latest release tag: $TAG"

# Construct the download URL
ASSET_NAME="eza_x86_64-unknown-linux-musl.zip"
DOWNLOAD_URL="https://github.com/$REPO/releases/download/$TAG/$ASSET_NAME"

echo "Downloading: $DOWNLOAD_URL"

# Download the release
TEMP_FILE="/tmp/eza.zip" # Changed to a zip file
curl -L "$DOWNLOAD_URL" -o "$TEMP_FILE"

if [ ! -f "$TEMP_FILE" ]; then
    echo "Error: Failed to download the release. Check the URL and your internet connection."
    exit 1
fi

# Create the installation directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Extract the executable and place in install dir.  Error handling added
echo "Extracting and installing to $INSTALL_DIR..."
unzip -d "$INSTALL_DIR" "$TEMP_FILE" > /dev/null 2>&1 # Suppress unzip output
if [ $? -ne 0 ]; then
    echo "Error: Failed to extract the archive. Check the file integrity."
    rm -f "$TEMP_FILE"
    exit 1
fi

#Rename
mv "$INSTALL_DIR/eza" "$INSTALL_DIR/$EZA_EXECUTABLE"

# Make executable
chmod +x "$INSTALL_DIR/$EZA_EXECUTABLE"

# Clean up the temporary file
rm -f "$TEMP_FILE"

# Update ZSH path if necessary
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo "Adding $INSTALL_DIR to PATH in $ZSH_PATH..."

  # Check if the line is already present
  if ! grep -q "export PATH=\"\$PATH:$INSTALL_DIR\"" "$ZSH_PATH"; then
      echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$ZSH_PATH"
  else
      echo "$INSTALL_DIR already in PATH in $ZSH_PATH. Skipping addition."
  fi

  echo "You may need to restart your terminal or run 'source $ZSH_PATH' for the changes to take effect."
else
  echo "$INSTALL_DIR already in PATH. No changes needed to $ZSH_PATH."
fi

echo "Installation complete! You can now run eza."

# Optional:  Verify installation
echo "Verifying installation..."
eza --version 2>&1 | grep -q "eza"
if [ $? -eq 0 ]; then
  echo "eza installed successfully!"
else
  echo "Warning: eza may not be installed correctly.  Try restarting your terminal."
fi

exit 0