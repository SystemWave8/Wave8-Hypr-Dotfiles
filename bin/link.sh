#!/usr/bin/env bash
set -e

DOTFILES_DIR="$HOME/.dotfiles"
CONFIG_DIR="$HOME/.config"
BIN_DIR="$HOME/.local/bin"
BACKUP_DIR="$HOME/.config-backups"

mkdir -p "$BACKUP_DIR"
mkdir -p "$BIN_DIR"

# List of config folders to link
declare -a CONFIGS=("dunst" "gtk-3.0" "gtk-4.0" "hypr" "waybar")

echo ">>> Linking configs..."
for cfg in "${CONFIGS[@]}"; do
    SRC="$DOTFILES_DIR/config/$cfg"
    DEST="$CONFIG_DIR/$cfg"

    if [ -e "$DEST" ] || [ -L "$DEST" ]; then
        echo ">>> Backing up existing $cfg to $BACKUP_DIR"
        mv "$DEST" "$BACKUP_DIR/${cfg}_$(date +%Y%m%d_%H%M%S)"
    fi

    echo ">>> Linking $cfg..."
    ln -sfn "$SRC" "$DEST"
done

echo ">>> Linking bin scripts individually..."
for file in "$DOTFILES_DIR/bin"/*; do
    ln -sfn "$file" "$BIN_DIR/$(basename "$file")"
done

# Ensure ~/.local/bin is in PATH
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo "Added ~/.local/bin to PATH in ~/.bashrc"
fi

echo ">>> All symlinks created successfully!"
