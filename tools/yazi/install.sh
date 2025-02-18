#!/bin/bash

# Script to download and install the latest yazi-x86_64-unknown-linux-musl.zip

# Set variables
YAZI_URL="https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-musl.zip"
INSTALL_DIR="$HOME/.local/bin"  # Recommended location for user-installed binaries
TEMP_DIR="$(mktemp -d)"       # Create a temporary directory
YAZI_EXECUTABLE="yazi"

# Check if required tools are installed
if ! command -v curl &> /dev/null; then
  echo "Error: curl is not installed. Please install it (e.g., sudo apt install curl)."
  exit 1
fi

if ! command -v unzip &> /dev/null; then
  echo "Error: unzip is not installed. Please install it (e.g., sudo apt install unzip)."
  exit 1
fi

# Create install directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Download the latest yazi release
echo "Downloading latest Yazi release..."
curl -L "$YAZI_URL" -o "$TEMP_DIR/yazi.zip"

# Check download success
if [ $? -ne 0 ]; then
  echo "Error: Failed to download Yazi release."
  rm -rf "$TEMP_DIR"
  exit 1
fi

# Extract the archive
echo "Extracting archive..."
unzip "$TEMP_DIR/yazi.zip" -d "$TEMP_DIR"

# Check extraction success
if [ $? -ne 0 ]; then
  echo "Error: Failed to extract Yazi archive."
  rm -rf "$TEMP_DIR"
  exit 1
fi

# Find the yazi executable within the extracted directory (more robust)
YAZI_PATH=$(find "$TEMP_DIR" -type f -name "$YAZI_EXECUTABLE" 2>/dev/null)

if [ -z "$YAZI_PATH" ]; then
    echo "Error: Yazi executable not found in the extracted archive."
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Move the executable to the install directory
echo "Installing Yazi..."
mv "$YAZI_PATH" "$INSTALL_DIR/$YAZI_EXECUTABLE"

# Make the executable executable
chmod +x "$INSTALL_DIR/$YAZI_EXECUTABLE"

# Clean up temporary directory
echo "Cleaning up..."
rm -rf "$TEMP_DIR"

# Handle PATH updates for Oh My Zsh (OMZ)
SHELL_CONFIG="$HOME/.zshrc" # Assumes Zsh with Oh My Zsh

if [[ -f "$SHELL_CONFIG" ]]; then
    # Check if the PATH already contains INSTALL_DIR
    if ! grep -q "export PATH=.*$INSTALL_DIR" "$SHELL_CONFIG"; then
        # Add the PATH to the end of the .zshrc file
        echo "Adding $INSTALL_DIR to PATH in $SHELL_CONFIG. Please open a new terminal or run 'source $SHELL_CONFIG'."
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$SHELL_CONFIG"
    else
        echo "$INSTALL_DIR already in PATH in $SHELL_CONFIG"
    fi

    # Refresh OMZ by running source. This may not always work automatically
    echo "Attempting to refresh Oh My Zsh by sourcing $SHELL_CONFIG"
    source "$SHELL_CONFIG" 2>/dev/null # suppress errors to continue if fails

    # Check if yazi is now available
    if command -v yazi &> /dev/null; then
       echo "Yazi is now available.  You can type 'yazi' in your terminal."
    else
       echo "Yazi installed, but not found in PATH. Please open a new terminal or run 'source $SHELL_CONFIG'."
    fi

else
  echo "Zsh configuration file not found at $SHELL_CONFIG.  Please manually add $INSTALL_DIR to your PATH"
fi

echo "Yazi installation complete!"