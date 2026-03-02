#!/usr/bin/bash
# =============================================================================
# Hyprland <-> Gamescope Session Switcher — Arch Linux Install Script
# =============================================================================
# Based on SteamOS steamos-session-select mechanism, adapted for vanilla Arch.
#
# Prerequisites (install before running this script):
#   pacman: sddm hyprland gamescope polkit xdg-desktop-portal xdg-desktop-portal-hyprland
#   AUR:    gamescope-session-plus
#
# What this script configures:
#   - /usr/share/wayland-sessions/ desktop files (if missing)
#   - /usr/lib/os-session-select        (core session switching logic)
#   - /usr/bin/steamos-session-select   (wrapper, called by Steam)
#   - /etc/polkit-1/rules.d/99-os-session-select.rules  (pkexec policy)
#   - /etc/sddm.conf.d/autologin.conf   (SDDM autologin config)
#   - systemd drop-in for gamescope-session-plus@steam.service
#   - SDDM enabled as display manager
#
# Usage after install:
#   steamos-session-select gamescope   — switch to Steam Big Picture
#   steamos-session-select hyprland    — switch to Hyprland
#   Steam's "Switch to Desktop" button works automatically.
#
# Run with:
#   sudo bash install-session-switcher.sh
# =============================================================================

set -e

# =============================================================================
# Helpers
# =============================================================================
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
section() { echo -e "\n${BLUE}=== $* ===${NC}"; }

# =============================================================================
# Root check
# =============================================================================
if [[ $EUID != 0 ]]; then
    error "Please run as root: sudo bash $0"
fi

# =============================================================================
# Detect the target username
# =============================================================================
# SUDO_USER is set when running via sudo — this is the actual human user.
# Username is never hardcoded anywhere in this script beyond autologin.conf.
if [[ -z "$SUDO_USER" || "$SUDO_USER" == "root" ]]; then
    error "Please run via sudo as a regular user: sudo bash $0\nDo not run directly as root."
fi

USERNAME="$SUDO_USER"
info "Detected user: $USERNAME"

# =============================================================================
# 1. Verify prerequisites are installed
# =============================================================================
section "Verifying prerequisites"

REQUIRED_COMMANDS=(sddm Hyprland gamescope pkexec gamescope-session-plus)
for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if command -v "$cmd" &>/dev/null; then
        info "$cmd — found"
    else
        error "$cmd not found. Please install all prerequisites before running this script."
    fi
done

# =============================================================================
# 2. Verify wheel group membership
# =============================================================================
section "Checking wheel group membership"

if groups "$USERNAME" | grep -q '\bwheel\b'; then
    info "$USERNAME is in the wheel group — pkexec will work correctly."
else
    warn "$USERNAME is NOT in the wheel group."
    warn "Adding $USERNAME to wheel group now..."
    usermod -aG wheel "$USERNAME"
    warn "Group change will take effect on next login."
fi

# =============================================================================
# 3. Verify/create wayland session desktop files
# =============================================================================
section "Checking wayland session desktop files"

SESSIONS_DIR="/usr/share/wayland-sessions"
mkdir -p "$SESSIONS_DIR"

if [[ -f "$SESSIONS_DIR/hyprland.desktop" ]]; then
    info "hyprland.desktop — exists"
else
    info "Creating hyprland.desktop..."
    cat > "$SESSIONS_DIR/hyprland.desktop" << 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=/usr/bin/Hyprland
Type=Application
DesktopNames=Hyprland
Keywords=tiling;wayland;compositor;
EOF
fi

if [[ -f "$SESSIONS_DIR/gamescope-session-steam.desktop" ]]; then
    info "gamescope-session-steam.desktop — exists"
else
    info "Creating gamescope-session-steam.desktop..."
    cat > "$SESSIONS_DIR/gamescope-session-steam.desktop" << 'EOF'
[Desktop Entry]
Encoding=UTF-8
Name=Steam Big Picture
Comment=Steam Big Picture session
Exec=gamescope-session-plus steam
Type=Application
DesktopNames=gamescope
EOF
fi

# =============================================================================
# 4. Write /usr/lib/os-session-select
# =============================================================================
section "Writing /usr/lib/os-session-select"

# Username is read dynamically from autologin.conf at switch time.
# This keeps os-session-select fully portable — no hardcoded values.

cat > /usr/lib/os-session-select << 'EOF'
#!/usr/bin/bash
set -e
die() { echo >&2 "!! $*"; exit 1; }

CONF="/etc/sddm.conf.d/autologin.conf"
session="${1:-gamescope}"

# Become root via pkexec
if [[ $EUID != 0 ]]; then
    pkexec "$(realpath $0)" "$session" --sentinel-created
    # Stop current session
    if [[ "$2" != "--no-restart" ]]; then
        systemctl --user --no-block stop gamescope-session-plus@steam.service 2>/dev/null || true
        pkill -f "gamescope-session-plus steam" 2>/dev/null || true
        pkill -x Hyprland 2>/dev/null || true
    fi
    exit
fi

if [[ "$2" != "--sentinel-created" ]]; then
    die "Running $0 as root is not allowed directly"
fi

# Read current user dynamically from conf — never hardcoded
CURRENT_USER=$(grep "^User=" "$CONF" | cut -d= -f2)
[[ -z "$CURRENT_USER" ]] && die "Could not determine current user from $CONF"

session_launcher=""
case "$session" in
    hyprland|desktop|plasma)
        session_launcher="hyprland"
    ;;
    gamescope)
        session_launcher="gamescope-session-steam"
    ;;
    *)
        die "Unrecognized session '$session'"
    ;;
esac

echo "Switching session to $session_launcher for user $CURRENT_USER"
{
    echo "[Autologin]"
    echo "User=$CURRENT_USER"
    echo "Session=$session_launcher"
    echo "Relogin=true"
} > "$CONF"

systemctl restart sddm
EOF

chmod +x /usr/lib/os-session-select
info "Done."

# =============================================================================
# 5. Write /usr/bin/steamos-session-select
# =============================================================================
section "Writing /usr/bin/steamos-session-select"

cat > /usr/bin/steamos-session-select << 'EOF'
#!/usr/bin/bash
# Wrapper called by Steam's "Switch to Desktop" button.
# Delegates to /usr/lib/os-session-select which contains the real logic.
GAMESCOPE_SESSION_SCRIPT="/usr/lib/os-session-select"
if [[ -f "$GAMESCOPE_SESSION_SCRIPT" ]]; then
    "${GAMESCOPE_SESSION_SCRIPT}" "$@"
else
    # Fallback if os-session-select is missing
    steam -shutdown
fi
EOF

chmod +x /usr/bin/steamos-session-select
info "Done."

# =============================================================================
# 6. Write polkit rule
# =============================================================================
section "Writing polkit rule"

mkdir -p /etc/polkit-1/rules.d
chmod 755 /etc/polkit-1/rules.d

cat > /etc/polkit-1/rules.d/99-os-session-select.rules << 'EOF'
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.policykit.exec" &&
        action.lookup("program") == "/usr/lib/os-session-select" &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
EOF

chmod 644 /etc/polkit-1/rules.d/99-os-session-select.rules
info "Done."

# =============================================================================
# 7. Write systemd drop-in for gamescope-session-plus@steam.service
# =============================================================================
section "Writing systemd drop-in for gamescope-session-plus"

# This prevents gamescope from inheriting WAYLAND_DISPLAY from the current
# session which causes it to try to connect to an existing compositor
# instead of starting as its own display server.

DROPIN_DIR="/etc/systemd/user/gamescope-session-plus@steam.service.d"
mkdir -p "$DROPIN_DIR"

cat > "$DROPIN_DIR/unset-wayland.conf" << 'EOF'
[Service]
UnsetEnvironment=WAYLAND_DISPLAY DISPLAY XAUTHORITY
EOF

info "Done."

# Reload systemd user daemon for the target user
sudo -u "$USERNAME" systemctl --user daemon-reload 2>/dev/null || true

# =============================================================================
# 8. Write SDDM autologin config
# =============================================================================
section "Writing SDDM autologin config"

mkdir -p /etc/sddm.conf.d

# Preserve the current Session= value if the file already exists
# so re-running the script doesn't reset a mid-session switch.
# Username is always updated to match the detected SUDO_USER.
if [[ -f /etc/sddm.conf.d/autologin.conf ]]; then
    CURRENT_SESSION=$(grep "^Session=" /etc/sddm.conf.d/autologin.conf | cut -d= -f2)
    info "autologin.conf exists — preserving current session: $CURRENT_SESSION"
else
    CURRENT_SESSION="hyprland"
    info "autologin.conf not found — creating with default session: hyprland"
fi

cat > /etc/sddm.conf.d/autologin.conf << EOF
[Autologin]
User=$USERNAME
Session=$CURRENT_SESSION
EOF

info "Done."

# =============================================================================
# 9. Enable SDDM
# =============================================================================
section "Enabling SDDM"

# Disable any other display managers that might conflict
for dm in gdm lightdm lxdm xdm; do
    if systemctl is-enabled "$dm" &>/dev/null; then
        warn "Disabling conflicting display manager: $dm"
        systemctl disable "$dm"
    fi
done

if systemctl is-enabled sddm &>/dev/null; then
    info "SDDM already enabled."
else
    info "Enabling SDDM..."
    systemctl enable sddm
fi

# =============================================================================
# Done
# =============================================================================
echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  Session switcher installed successfully!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "  User:            $USERNAME"
echo "  Default session: $CURRENT_SESSION"
echo ""
echo "Usage:"
echo "  steamos-session-select gamescope   — switch to Steam Big Picture"
echo "  steamos-session-select hyprland    — switch to Hyprland"
echo "  Steam's 'Switch to Desktop' works automatically."
echo ""
echo "Recommended aliases (~/.bashrc or ~/.zshrc):"
echo "  alias soss='steamos-session-select'"
echo "  alias catoss='cat /usr/lib/os-session-select'"
echo "  alias catsddm='cat /etc/sddm.conf.d/autologin.conf'"
echo ""
echo "Reboot or restart SDDM to apply:"
echo "  sudo systemctl restart sddm"
echo ""
