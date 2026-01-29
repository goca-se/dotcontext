#!/bin/bash
set -e

# dotcontext installer
# Usage: curl -sSL https://raw.githubusercontent.com/USER/dotcontext/main/install.sh | bash

REPO="goca-se/dotcontext"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="dotcontext"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_green() { printf "${GREEN}%s${NC}\n" "$1"; }
print_red() { printf "${RED}%s${NC}\n" "$1"; }
print_yellow() { printf "${YELLOW}%s${NC}\n" "$1"; }
print_blue() { printf "${BLUE}%s${NC}\n" "$1"; }

echo ""
print_blue "📦 Installing dotcontext..."
echo ""

# Check for curl or wget
if command -v curl &> /dev/null; then
  DOWNLOADER="curl -sSL"
elif command -v wget &> /dev/null; then
  DOWNLOADER="wget -qO-"
else
  print_red "Error: curl or wget is required but not installed."
  exit 1
fi

# Download the script
DOWNLOAD_URL="https://raw.githubusercontent.com/${REPO}/main/dotcontext"
TMP_FILE=$(mktemp)

echo "Downloading from ${DOWNLOAD_URL}..."
if ! $DOWNLOADER "$DOWNLOAD_URL" > "$TMP_FILE"; then
  print_red "Error: Failed to download dotcontext"
  rm -f "$TMP_FILE"
  exit 1
fi

# Check if download was successful (file should not be empty and should start with shebang)
if [ ! -s "$TMP_FILE" ] || ! head -1 "$TMP_FILE" | grep -q "^#!/bin/bash"; then
  print_red "Error: Downloaded file is invalid"
  rm -f "$TMP_FILE"
  exit 1
fi

# Make executable
chmod +x "$TMP_FILE"

# Install to INSTALL_DIR
if [ -w "$INSTALL_DIR" ]; then
  mv "$TMP_FILE" "${INSTALL_DIR}/${BINARY_NAME}"
else
  print_yellow "Need sudo to install to ${INSTALL_DIR}"
  sudo mv "$TMP_FILE" "${INSTALL_DIR}/${BINARY_NAME}"
  sudo chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
fi

# Verify installation
if command -v "$BINARY_NAME" &> /dev/null; then
  echo ""
  print_green "✅ dotcontext installed successfully!"
  echo ""
  echo "Version: $(dotcontext --version)"
  echo ""
  echo "Get started:"
  echo "  cd your-project"
  echo "  dotcontext init"
  echo ""
else
  print_yellow "⚠️  dotcontext installed to ${INSTALL_DIR}/${BINARY_NAME}"
  print_yellow "   but it's not in your PATH."
  echo ""
  echo "Add this to your shell profile:"
  echo "  export PATH=\"\$PATH:${INSTALL_DIR}\""
  echo ""
fi
