#!/bin/bash

# Script to download and install the latest jq-linux64

set -euo pipefail  # Exit on error, unset variable, or pipe failure

# --- Configuration ---
INSTALL_DIR="/usr/local/bin"  # Where to install jq
JQ_BINARY_NAME="jq"         # Name of the jq executable
DOWNLOAD_DIR="/tmp"       # Temporary directory for the download
ZSH_CONFIG_FILE="$HOME/.zshrc" # Zsh configuration file

# --- Functions ---

# Function to find the latest jq release URL
get_latest_jq_url() {
  local jq_release_api="https://api.github.com/repos/stedolan/jq/releases/latest"
  local download_url

  download_url=$(curl -s "$jq_release_api" | jq -r '.assets[] | select(.name | contains("jq-linux64")) | .browser_download_url')

  if [[ -z "$download_url" ]]; then
    echo "Error: Could not find jq-linux64 download URL." >&2
    return 1
  fi

  echo "$download_url"
}


# Function to download a file and check its exit code.
download_file() {
  local url="$1"
  local filename="$2"

  echo "Downloading $url to $filename..."
  if ! curl -sLo "$filename" "$url"; then
    echo "Error: Failed to download $url." >&2
    return 1
  fi
  echo "Download complete."
}


# --- Main Script ---

# 1. Create a temporary download directory
mkdir -p "$DOWNLOAD_DIR"

# 2. Get the latest jq download URL
JQ_DOWNLOAD_URL=$(get_latest_jq_url)

if [[ $? -ne 0 ]]; then
  echo "Failed to get jq download URL.  Exiting." >&2
  exit 1
fi

# 3. Determine the download filename and path
JQ_FILENAME=$(basename "$JQ_DOWNLOAD_URL")
JQ_DOWNLOAD_PATH="$DOWNLOAD_DIR/$JQ_FILENAME"


# 4. Download the latest jq binary
download_file "$JQ_DOWNLOAD_URL" "$JQ_DOWNLOAD_PATH"

if [[ $? -ne 0 ]]; then
  echo "Failed to download jq.  Exiting." >&2
  exit 1
fi


# 5. Make the binary executable
chmod +x "$JQ_DOWNLOAD_PATH"

# 6. Install the binary to /usr/local/bin (requires sudo)
echo "Installing jq to $INSTALL_DIR/$JQ_BINARY_NAME..."
sudo mv "$JQ_DOWNLOAD_PATH" "$INSTALL_DIR/$JQ_BINARY_NAME"

if [[ $? -ne 0 ]]; then
  echo "Error: Failed to install jq.  Make sure you have sudo privileges." >&2
  exit 1
fi

# 7. Clean up temporary directory
rm -rf "$DOWNLOAD_DIR"

# 8. Refresh the zsh environment (if using zsh and the install dir is not already in your path)
if [[ "$SHELL" == *zsh* ]] && ! [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
  echo "Adding $INSTALL_DIR to PATH in $ZSH_CONFIG_FILE (if it's not already there)..."

  # Check if the PATH variable is already set in .zshrc
  if grep -q "export PATH=" "$ZSH_CONFIG_FILE"; then
    # Add install dir if not already present
    if ! grep -q "$INSTALL_DIR" "$ZSH_CONFIG_FILE"; then
      sed -i "s/export PATH=/\&:$INSTALL_DIR/g" "$ZSH_CONFIG_FILE"
    fi
  else
    echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$ZSH_CONFIG_FILE"
  fi

  echo "Refreshing zsh environment by sourcing $ZSH_CONFIG_FILE..."
  source "$ZSH_CONFIG_FILE"
fi


# 9. Verify the installation
echo "Verifying installation..."
jq --version

echo "jq installation complete!"