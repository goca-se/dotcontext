#!/bin/bash
set -e

# dotcontext installer
# Usage: curl -sSL https://raw.githubusercontent.com/goca-se/dotcontext/main/install.sh | bash

REPO="goca-se/dotcontext"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="dotcontext"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

# Braille spinner
SPINNER_PID=""
start_spinner() {
  local msg="$1"
  local frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
  local i=0
  while true; do
    printf "\r  ${BLUE}${frames[$i]}${NC} ${msg}"
    i=$(( (i + 1) % 10 ))
    sleep 0.1
  done &
  SPINNER_PID=$!
}

stop_spinner() {
  if [ -n "$SPINNER_PID" ]; then
    kill "$SPINNER_PID" 2>/dev/null
    wait "$SPINNER_PID" 2>/dev/null || true
    SPINNER_PID=""
  fi
  printf "\r\033[K"
}

# Check for curl or wget
if command -v curl &> /dev/null; then
  DOWNLOADER="curl -fsSL"
elif command -v wget &> /dev/null; then
  DOWNLOADER="wget -qO-"
else
  printf "${RED}Error: curl or wget is required but not installed.${NC}\n"
  exit 1
fi

start_spinner "Installing dotcontext..."

# Get latest release tag
API_RESPONSE=$($DOWNLOADER "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null || echo "")
LATEST_TAG=$(echo "$API_RESPONSE" | grep '"tag_name"' | head -1 | sed -E 's/.*"([^"]+)".*/\1/')

# Fallback to tags if no release
if [ -z "$LATEST_TAG" ]; then
  API_RESPONSE=$($DOWNLOADER "https://api.github.com/repos/${REPO}/tags" 2>/dev/null || echo "")
  LATEST_TAG=$(echo "$API_RESPONSE" | grep '"name"' | head -1 | sed -E 's/.*"([^"]+)".*/\1/')
fi

# Fallback to main if no tags
if [ -z "$LATEST_TAG" ]; then
  LATEST_TAG="main"
fi

DOWNLOAD_URL="https://raw.githubusercontent.com/${REPO}/${LATEST_TAG}/dotcontext"

# Download
TMP_FILE=$(mktemp)
if ! $DOWNLOADER "$DOWNLOAD_URL" > "$TMP_FILE" 2>/dev/null; then
  stop_spinner
  printf "${RED}Error: Failed to download dotcontext${NC}\n"
  rm -f "$TMP_FILE"
  exit 1
fi

# Validate
if [ ! -s "$TMP_FILE" ] || ! head -1 "$TMP_FILE" | grep -q "^#!/bin/bash"; then
  stop_spinner
  printf "${RED}Error: Downloaded file is invalid${NC}\n"
  rm -f "$TMP_FILE"
  exit 1
fi

stop_spinner

# Install
chmod +x "$TMP_FILE"
if [ -w "$INSTALL_DIR" ]; then
  mv "$TMP_FILE" "${INSTALL_DIR}/${BINARY_NAME}"
else
  sudo mv "$TMP_FILE" "${INSTALL_DIR}/${BINARY_NAME}" 2>/dev/null || {
    printf "${YELLOW}Need sudo to install to ${INSTALL_DIR}${NC}\n"
    sudo mv "$TMP_FILE" "${INSTALL_DIR}/${BINARY_NAME}"
    sudo chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
  }
fi

# Verify
if ! command -v "$BINARY_NAME" &> /dev/null; then
  printf "${YELLOW}Installed to ${INSTALL_DIR}/${BINARY_NAME} but not in PATH.${NC}\n"
  echo "Add to your shell profile:"
  echo "  export PATH=\"\$PATH:${INSTALL_DIR}\""
  exit 0
fi

VERSION=$(dotcontext --version 2>/dev/null | sed 's/dotcontext //')

# Welcome screen (side-by-side layout with braille circle)
echo ""
printf "  ${BLUE}⠀⠀⣀⣴⣶⣶⣶⣶⣦⣀⠀⠀${NC}      ${BOLD}dotcontext${NC} ${GRAY}v${VERSION}${NC}\n"
printf "  ${BLUE}⢀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣧⡀${NC}      ${GRAY}AI context toolkit for your codebase${NC}\n"
printf "  ${BLUE}⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇${NC}\n"
printf "  ${BLUE}⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇${NC}      ${GREEN}✓${NC} Installed successfully\n"
printf "  ${BLUE}⠈⢻⣿⣿⣿⣿⣿⣿⣿⣿⡟⠁${NC}      ${GRAY}CLAUDE.md${NC}  ${GRAY}.context/${NC}  ${GRAY}.claude/commands/${NC}\n"
printf "  ${BLUE}⠀⠀⠉⠻⠿⠿⠿⠿⠟⠉⠀⠀${NC}      ${CYAN}/setup-context${NC}  ${CYAN}/fix-bug${NC}  ${CYAN}/deep-context${NC}  ${GRAY}+8 more${NC}\n"
echo ""
printf "  ${BOLD}Quick start:${NC}  ${CYAN}cd${NC} your-project ${GRAY}&&${NC} ${CYAN}dotcontext init${NC}\n"
printf "  ${GRAY}Docs: https://github.com/${REPO}${NC}\n"
echo ""
