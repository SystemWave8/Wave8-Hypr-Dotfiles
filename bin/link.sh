#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/.dotfiles"
CONFIG_DIR="$HOME/.config"
BIN_DIR="$HOME/.local/bin"
APPLICATIONS_DIR="$HOME/.local/share/applications"

mkdir -p "$BIN_DIR"
mkdir -p "$APPLICATIONS_DIR"

echo ">>> Linking configs..."

for SRC in "$DOTFILES_DIR/config"/*; do
    [ -d "$SRC" ] || continue
    cfg="$(basename "$SRC")"
    DEST="$CONFIG_DIR/$cfg"

    # If already the correct symlink, skip
    if [ "$(readlink -f "$DEST" 2>/dev/null)" = "$(readlink -f "$SRC")" ]; then
        echo ">>> $cfg already linked correctly"
        continue
    fi

    # Remove anything that is in the way
    rm -rf "$DEST"

    echo ">>> Linking $cfg..."
    ln -s "$SRC" "$DEST"
done

echo ">>> Linking bin scripts..."

for file in "$DOTFILES_DIR/bin"/*; do
    [ -f "$file" ] || continue
    dest="$BIN_DIR/$(basename "$file")"

    if [ "$(readlink -f "$dest" 2>/dev/null)" = "$(readlink -f "$file")" ]; then
        echo ">>> Skipping $(basename "$file") (already linked)"
        continue
    fi

    rm -f "$dest"
    ln -s "$file" "$dest"
done

echo ">>> Linking application files..."

if [ -d "$DOTFILES_DIR/applications" ]; then
    for appfile in "$DOTFILES_DIR/applications"/*; do
        [ -f "$appfile" ] || continue
        dest="$APPLICATIONS_DIR/$(basename "$appfile")"

        if [ "$(readlink -f "$dest" 2>/dev/null)" = "$(readlink -f "$appfile")" ]; then
            echo ">>> Skipping $(basename "$appfile") (already linked)"
            continue
        fi

        rm -f "$dest"
        ln -s "$appfile" "$dest"
    done
fi

# Ensure ~/.local/bin is in PATH once
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo ">>> Added ~/.local/bin to PATH"
fi

echo ">>> All symlinks created successfully!"
