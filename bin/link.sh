#!/usr/bin/env bash
set -e

DOTFILES_DIR="$HOME/.dotfiles"
CONFIG_DIR="$HOME/.config"
BIN_DIR="$HOME/.local/bin"
BACKUP_DIR="$HOME/.config-backups"
APPLICATIONS_DIR="$HOME/.local/share/applications"

mkdir -p "$BACKUP_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$APPLICATIONS_DIR"

# List of config folders to link
declare -a CONFIGS=($(ls -1 "$DOTFILES_DIR/config"))

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
    [ -f "$file" ] || continue
    dest="$BIN_DIR/$(basename "$file")"
    if [ "$(readlink -f "$dest" 2>/dev/null)" = "$(readlink -f "$file")" ]; then
        echo ">>> Skipping $(basename "$file") (already linked)"
        continue
    fi
    ln -sfn "$file" "$dest"
done

echo ">>> Linking application files individually..."
if [ -d "$DOTFILES_DIR/applications" ]; then
    for appfile in "$DOTFILES_DIR/applications"/*; do
        [ -f "$appfile" ] || continue
        dest="$APPLICATIONS_DIR/$(basename "$appfile")"
        if [ "$(readlink -f "$dest" 2>/dev/null)" = "$(readlink -f "$appfile")" ]; then
            echo ">>> Skipping $(basename "$appfile") (already linked)"
            continue
        fi
        ln -sfn "$appfile" "$dest"
    done
else
    echo ">>> No applications folder found in dotfiles. Skipping..."
fi

# Ensure ~/.local/bin is in PATH
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo "Added ~/.local/bin to PATH in ~/.bashrc"
fi

echo ">>> All symlinks created successfully!"
