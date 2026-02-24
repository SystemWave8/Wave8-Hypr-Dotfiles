#!/bin/bash

# ─────────────────────────────────────────
#  git-ready.sh — Post-clone Git setup
#  Run this after cloning your dotfiles
#  on a fresh system to get Git working.
# ─────────────────────────────────────────

GIT_USER="SystemWave8"
GIT_EMAIL="systemwave@outlook.com"
DOTFILES_DIR="$HOME/.dotfiles"
REMOTE_URL="git@github.com:SystemWave8/Wave8-Hypr-Dotfiles.git"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Git Ready — Fresh System Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Step 1: Set global Git identity ──────
echo "👤 Setting global Git identity..."
git config --global user.name "$GIT_USER"
git config --global user.email "$GIT_EMAIL"
echo "   Name  → $GIT_USER"
echo "   Email → $GIT_EMAIL"
echo ""

# ── Step 2: Generate SSH key ─────────────
KEY_PATH="$HOME/.ssh/id_ed25519"

if [ -f "$KEY_PATH" ]; then
    echo "🔑 SSH key already exists at $KEY_PATH — skipping generation."
else
    echo "🔑 Generating SSH key..."
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$KEY_PATH" -N ""
    echo "   ✅ SSH key generated."
fi
echo ""

# ── Step 3: Start ssh-agent and add key ──
echo "🚀 Starting ssh-agent..."
eval "$(ssh-agent -s)"
ssh-add "$KEY_PATH"
echo ""

# ── Step 4: Write SSH config ─────────────
SSH_CONFIG="$HOME/.ssh/config"
if ! grep -q "github.com" "$SSH_CONFIG" 2>/dev/null; then
    mkdir -p "$HOME/.ssh"
    echo "" >> "$SSH_CONFIG"
    echo "Host github.com" >> "$SSH_CONFIG"
    echo "  HostName github.com" >> "$SSH_CONFIG"
    echo "  User git" >> "$SSH_CONFIG"
    echo "  IdentityFile ~/.ssh/id_ed25519" >> "$SSH_CONFIG"
    echo "  AddKeysToAgent yes" >> "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
    echo "✅ SSH config written."
else
    echo "✅ SSH config already set — skipping."
fi
echo ""

# ── Step 5: Show public key ───────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📋 Your PUBLIC key — add this to GitHub:"
echo "  → https://github.com/settings/ssh/new"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
cat "${KEY_PATH}.pub"
echo ""

# Copy to clipboard (Wayland/Hyprland)
if command -v wl-copy &>/dev/null; then
    wl-copy < "${KEY_PATH}.pub"
    echo "📎 Copied to clipboard!"
else
    echo "💡 Install wl-clipboard to auto-copy: sudo pacman -S wl-clipboard"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
read -rp "  Press Enter once you've added the key to GitHub..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Step 6: Test SSH connection ───────────
echo "🔍 Testing GitHub connection..."
ssh -T git@github.com 2>&1
echo ""

# ── Step 7: Fix dotfiles remote to SSH ───
echo "🔗 Checking dotfiles remote..."
cd "$DOTFILES_DIR" || { echo "❌ Could not find $DOTFILES_DIR — did you clone first?"; exit 1; }

CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null)

if [ "$CURRENT_REMOTE" = "$REMOTE_URL" ]; then
    echo "   ✅ Remote already set to SSH — nothing to change."
elif [ -z "$CURRENT_REMOTE" ]; then
    git remote add origin "$REMOTE_URL"
    echo "   ✅ Remote added → $REMOTE_URL"
else
    git remote set-url origin "$REMOTE_URL"
    echo "   ✅ Remote updated → $REMOTE_URL"
    echo "   (was: $CURRENT_REMOTE)"
fi
echo ""

# ── Done ──────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ All done! You're ready to push."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Useful commands:"
echo "  git pull          → grab latest from GitHub"
echo "  git add .         → stage your changes"
echo "  git commit -m ''  → save with a message"
echo "  git push          → send changes to GitHub"
echo ""
