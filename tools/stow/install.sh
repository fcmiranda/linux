#!/bin/bash

# Script to install Stow locally (into $HOME/.local)

# Check if Stow is already installed
if command -v stow &> /dev/null; then
  echo "Stow is already installed (likely globally)."
  echo "If you want to install locally anyway, uninstall the global version first."
  exit 1
fi

# Determine OS and suggest package manager installation
OS=$(uname -s)

echo "Attempting local installation of Stow..."

# Get the latest version of Stow from the GNU website
STOW_VERSION=$(curl -s https://ftp.gnu.org/gnu/stow/ | grep 'href="stow-[0-9.]*\.tar\.gz"' | head -n 1 | sed -E 's/.*href="stow-([0-9.]+)\.tar\.gz".*/\1/')

if [ -z "$STOW_VERSION" ]; then
  echo "Error: Could not determine the latest Stow version from the GNU website."
  exit 1
fi

STOW_FILE="stow-${STOW_VERSION}.tar.gz"
STOW_URL="https://ftp.gnu.org/gnu/stow/${STOW_FILE}"


# Installation directory
INSTALL_DIR="$HOME/.local"

# Check if installation directory exists, create if not
mkdir -p "$INSTALL_DIR/bin"

# Download and extract Stow source
echo "Downloading Stow source: $STOW_URL"
curl -OL "$STOW_URL"

if [ ! -f "$STOW_FILE" ]; then
  echo "Error: Failed to download Stow source."
  exit 1
fi

echo "Extracting Stow source..."
tar -xzf "$STOW_FILE"

STOW_DIR="stow-${STOW_VERSION}"

if [ ! -d "$STOW_DIR" ]; then
  echo "Error: Failed to extract Stow source."
  exit 1
fi

# Build and install Stow
echo "Building and installing Stow..."
cd "$STOW_DIR"

./configure --prefix="$INSTALL_DIR"

if [ $? -ne 0 ]; then
  echo "Error: ./configure failed.  Check dependencies."
  exit 1
fi

make

if [ $? -ne 0 ]; then
  echo "Error: make failed."
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "Error: make install failed."
  exit 1
fi


# Add to PATH
if grep -q "export PATH=\"$INSTALL_DIR/bin:\$PATH\"" "$HOME/.zshrc"; then
  echo "PATH already configured."
else

  if ! [ -f "$HOME/.zshrc" ]; then
    echo "creating $HOME/.zshrc file"
    echo "adding $INSTALL_DIR/bin to PATH in ~/.zshrc"
    echo "export PATH=\"$INSTALL_DIR/bin:\$PATH\"" > "$HOME/.zshrc"
  else
    echo "warning: .zshrc file found. You'll need to manually add $INSTALL_DIR/bin to your PATH."
  fi
fi

# Clean up
echo "cleaning up..."
cd ..
rm -rf "$STOW_DIR"
rm "$STOW_FILE"

# Source the configuration file to update the PATH
if [ -n "$CONFIG_FILE" ]; then
  echo "sourcing $CONFIG_FILE to update PATH..."
  source "$CONFIG_FILE"
fi

echo "stow installed locally to $INSTALL_DIR/bin"
echo "make sure to restart your terminal or run 'source ~/.zshrc' (or similar) to use Stow."

# Verification
echo "verifying installation..."
if stow --version &> /dev/null; then
  echo "stow installation verified successfully."
else
  echo "error: Stow installation verification failed.  Check your PATH."
fi

exit 0