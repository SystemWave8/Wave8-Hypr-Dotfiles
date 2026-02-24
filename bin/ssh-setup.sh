#!/bin/bash

# ─────────────────────────────────────────
#  ssh-setup.sh — GitHub SSH Key Setup
#  User: SystemWave8 <systemwave@outlook.com>
# ─────────────────────────────────────────

GIT_EMAIL="systemwave@outlook.com"
KEY_PATH="$HOME/.ssh/id_ed25519"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  GitHub SSH Key Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if key already exists
if [ -f "$KEY_PATH" ]; then
    echo "⚠️  An SSH key already exists at $KEY_PATH"
    read -rp "   Overwrite it? (y/N): " OVERWRITE
    if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
        echo ""
        echo "↩️  Keeping existing key. Skipping generation."
        echo ""
    else
        GENERATE=true
    fi
else
    GENERATE=true
fi

# Generate key
if [ "$GENERATE" = true ]; then
    echo "🔑 Generating SSH key (ed25519)..."
    echo ""
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$KEY_PATH"
    echo ""
    echo "✅ SSH key generated at $KEY_PATH"
    echo ""
fi

# Start ssh-agent and add key
echo "🚀 Starting ssh-agent..."
eval "$(ssh-agent -s)"
ssh-add "$KEY_PATH"
echo ""

# Make SSH config persist the key (so it survives reboots)
SSH_CONFIG="$HOME/.ssh/config"
if ! grep -q "id_ed25519" "$SSH_CONFIG" 2>/dev/null; then
    echo "">> "$SSH_CONFIG"
    echo "Host github.com" >> "$SSH_CONFIG"
    echo "  HostName github.com" >> "$SSH_CONFIG"
    echo "  User git" >> "$SSH_CONFIG"
    echo "  IdentityFile ~/.ssh/id_ed25519" >> "$SSH_CONFIG"
    echo "  AddKeysToAgent yes" >> "$SSH_CONFIG"
    echo "✅ SSH config updated at $SSH_CONFIG"
else
    echo "✅ SSH config already has this key — skipping."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📋 Your PUBLIC key (copy this):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
cat "${KEY_PATH}.pub"
echo ""

# Copy to clipboard if xclip/wl-copy available (Hyprland = Wayland)
if command -v wl-copy &>/dev/null; then
    wl-copy < "${KEY_PATH}.pub"
    echo "📎 Public key copied to clipboard via wl-copy!"
elif command -v xclip &>/dev/null; then
    xclip -selection clipboard < "${KEY_PATH}.pub"
    echo "📎 Public key copied to clipboard via xclip!"
else
    echo "💡 Tip: Install wl-clipboard to auto-copy next time (sudo pacman -S wl-clipboard)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Next steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  1. Go to → https://github.com/settings/ssh/new"
echo "  2. Paste your public key into the 'Key' field"
echo "  3. Give it a title (e.g. 'Arch Hyprland')"
echo "  4. Click 'Add SSH Key'"
echo ""
echo "  Then test it with:"
echo "  ssh -T git@github.com"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
