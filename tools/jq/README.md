```bash
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
```

Key improvements and explanations:

* **Error Handling:**  `set -euo pipefail` ensures the script exits immediately if any command fails.  Each crucial step is checked for success (using `$?`) and an appropriate error message is displayed before exiting.  This makes debugging much easier.  The use of `>&2` redirects error messages to standard error.
* **`get_latest_jq_url()` Function:** This crucial addition fetches the *actual* download URL from the GitHub API.  This is much more robust than hardcoding a URL because it always gets the *latest* version.  Uses `jq` command to parse the API response.
* **Temporary Directory:** Uses `/tmp` as the download directory which is automatically cleaned after a reboot.  Creates the directory if it doesn't exist.
* **`download_file()` Function:**  Encapsulates the download logic, making the script more readable and maintainable. Handles download errors explicitly.
* **`basename`:**  Correctly extracts the filename from the URL.
* **Path Handling:**  Includes logic to *add* the installation directory (`/usr/local/bin` in this case) to your `PATH` *if* it's not already there. It also sources your `.zshrc` to update the current shell environment.  Critically, it only updates the `PATH` if it's running under `zsh`.  This is important, as you don't want to modify `.zshrc` if the script is run from `bash`, or some other shell. The script checks if `export PATH=` is already in `.zshrc` and adds `$INSTALL_DIR` to existing export or create one.
* **Uses `curl -sLo`: This combines silent mode (`-s` avoiding the progress bar), `-L` to follow redirects, and `-o` to specify the output file.**
* **Configuration:** Uses variables for the install directory, binary name, and zsh configuration file.  This makes the script easier to customize.
* **Clearer Messages:** More informative messages are printed to the console to guide the user.
* **Robust Zsh PATH update**: Checks if already in the PATH before adding.

**How to use the script:**

1.  **Save:** Save the script to a file, for example, `install_jq.sh`.
2.  **Make Executable:** `chmod +x install_jq.sh`
3.  **Run as Sudo:** `sudo ./install_jq.sh`  (You need `sudo` because it installs to `/usr/local/bin`).

This improved script provides a reliable and automated way to install the latest version of `jq` on your system, while also ensuring it is easily accessible from your terminal and correctly handles the oh-my-zsh environment.  Remember to review and understand the script before running it, especially the parts that modify your shell configuration.
