#!/usr/bin/bash

set -eo pipefail

# Set up trap to remove temporary file on exit
deb_file="${TEMPDIR:-/tmp}/tabby.deb"
trap 'rm -f "$deb_file"; echo "Cleaning up temporary files."' EXIT INT TERM

# Check if required tools are available
for cmd in curl jq wget gdebi; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "Error: $cmd is required but not installed."; exit 1; }
done

echo "Checking for latest Tabby release..."
url=$(curl -s -H "Accept: application/vnd.github+json" \
      https://api.github.com/repos/Eugeny/tabby/releases/latest | 
      jq -rM '.assets[] | select(.name | contains("linux-x64.deb")) | .browser_download_url')

# Validate URL
if [ -z "$url" ]; then
    echo "Error: No download URL found for the latest release."
    exit 1
fi

echo "Downloading Tabby from $url..."
wget -qO "$deb_file" "$url" || { echo "Error: Failed to download the file."; exit 1; }

echo "Installing Tabby..."
sudo gdebi --non-interactive "$deb_file" || { echo "Error: Installation failed."; exit 1; }

echo "Tabby has been successfully updated to version $(tabby --version)."
rm -f "$deb_file"
