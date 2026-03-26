#!/usr/bin/env bash
set -e

# === LOGGING ===
exec > >(tee -a "setup_$(date +%F_%H-%M-%S).log") 2>&1

# === COLORS ===
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RESET="\033[0m"

log()  { echo -e "${GREEN}==>${RESET} $1"; }
warn() { echo -e "${YELLOW}==>${RESET} $1"; }

# === ENVIRONMENT DETECTION ===
if [ -f /.dockerenv ] || [ -n "$DISTROBOX_ENTERED" ]; then
  IN_CONTAINER=true
  log "Running inside a container — systemd actions will be skipped."
else
  IN_CONTAINER=false
fi

# === PRE-FLIGHT CHECK ===
if ! grep -qiE "arch|steamos" /etc/os-release; then
  warn "This script is designed for Arch Linux or SteamOS systems only."
  exit 1
fi

# === HARDWARE DETECTION ===
ARCH=$(uname -m)
CPU_MODEL=$(lscpu | awk -F: '/Model name/ {print $2}' | xargs)
GPU_INFO=$(lspci | grep -Ei "vga|3d|display")

log "Detected ARCH: $ARCH"
log "Detected CPU: $CPU_MODEL"
log "Detected GPU: $GPU_INFO"

IS_MACBOOK_AIR=false
if echo "$CPU_MODEL" | grep -q "i5-4250U"; then
  IS_MACBOOK_AIR=true
  log "2013 MacBook Air detected"
fi

if echo "$GPU_INFO" | grep -qi intel; then
  GPU_TYPE="intel"
elif echo "$GPU_INFO" | grep -qi amd; then
  GPU_TYPE="amd"
elif echo "$GPU_INFO" | grep -qi nvidia; then
  GPU_TYPE="nvidia"
else
  GPU_TYPE="unknown"
fi

log "GPU type classified as: $GPU_TYPE"

HAS_NVIDIA=false
echo "$GPU_INFO" | grep -qi nvidia && HAS_NVIDIA=true

if [ "$HAS_NVIDIA" = true ]; then
  log "NVIDIA GPU detected — NVIDIA driver stack will be installed."
else
  log "No NVIDIA GPU detected — skipping NVIDIA setup."
fi

sudo -v

log "Updating system..."
sudo pacman -Syu --noconfirm

log "Ensuring essential build tools..."
sudo pacman -S --noconfirm --needed git base-devel

# === YAY BOOTSTRAP ===
if ! command -v yay &>/dev/null; then
  log "Installing yay..."
  cd /tmp
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  cd ~
else
  log "yay already installed."
fi

# === INSTALL GROUPS ===

install_base() {
  log "Installing base packages..."
  sudo pacman -S --noconfirm --needed \
    base base-devel linux linux-firmware amd-ucode efibootmgr \
    dosfstools exfatprogs ntfs-3g unzip wget smartmontools zram-generator
}

install_network() {
  log "Installing network..."
  sudo pacman -S --noconfirm --needed \
    bluez bluez-utils blueman iwd wpa_supplicant openssh
}

install_tools() {
  log "Installing tools..."
  sudo pacman -S --noconfirm --needed \
    htop btop fastfetch jq 7zip file-roller vim nano yad zenity brightnessctl \
    udiskie gvfs gvfs-mtp gvfs-gphoto2 cpio cmake konsole
}

install_desktop() {
  log "Installing Hyprland..."
  sudo pacman -S --noconfirm --needed \
    hyprland uwsm xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-utils \
    dunst waybar wofi thunar thunar-archive-plugin tumbler polkit-kde-agent \
    sddm gnome-keyring seahorse dotnet-runtime-8.0 hyprpaper mpv flatpak
}

install_fonts_themes() {
  log "Installing fonts..."
  sudo pacman -S --noconfirm --needed \
    gnome-themes-extra adwaita-icon-theme \
    ttf-dejavu ttf-hack-nerd ttf-jetbrains-mono-nerd \
    ttf-nerd-fonts-symbols woff2-font-awesome
}

install_audio() {
  log "Installing audio..."
  sudo pacman -S --noconfirm --needed \
    pipewire pipewire-alsa pipewire-pulse wireplumber wiremix \
    gst-plugin-pipewire picard yt-dlp chromaprint mpd mpc rmpc
  yay -S --noconfirm --needed pithos cavalier
}

install_apps() {
  log "Installing apps..."
  yay -S --noconfirm --needed \
    brave-bin chromium thunderbird onlyoffice-bin mousepad \
    gnome-clocks gnome-weather localsend-bin helium-browser-bin vscodium-bin
}

install_video_drivers() {
  log "Installing GPU drivers..."

  if [ "$IS_MACBOOK_AIR" = true ]; then
    log "MacBook Air profile"
    sudo pacman -S --noconfirm --needed \
      vulkan-intel intel-media-driver libva-intel-driver sof-firmware
    return
  fi

  case "$GPU_TYPE" in
    intel)
      sudo pacman -S --noconfirm --needed \
        vulkan-intel intel-media-driver libva-intel-driver
      ;;
    amd)
      sudo pacman -S --noconfirm --needed vulkan-radeon
      [ "$ARCH" = "x86_64" ] && sudo pacman -S --needed lib32-vulkan-radeon || true
      ;;
    nvidia)
      log "Handled separately"
      ;;
  esac

  sudo pacman -S --noconfirm --needed sof-firmware
}

install_nvidia_gpu() {
  log "Installing NVIDIA..."
  sudo pacman -S --noconfirm --needed \
    linux-headers linux-firmware-nvidia nvidia-open-dkms \
    nvidia-utils nvidia-settings lib32-nvidia-utils
}

install_extras() {
  log "Installing extras..."
  yay -S --noconfirm --needed impala
}

link_dotfiles() {
  log "Linking dotfiles..."
  bash ~/.dotfiles/bin/link.sh
}

# === EXECUTION ===
install_base
install_network
install_tools
install_desktop
install_fonts_themes
install_audio
install_apps
install_video_drivers
[ "$HAS_NVIDIA" = true ] && install_nvidia_gpu
install_extras
link_dotfiles

# === YOUR ORIGINAL CUSTOM SECTION (RESTORED) ===

gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'

# MPD
systemctl --user enable mpd
systemctl --user start mpd

# Hyprland local rules
RULE_DIR="$HOME/.config/hypr-local/windowrules"
mkdir -p "$RULE_DIR"
touch "$RULE_DIR/floating.conf" "$RULE_DIR/tiled.conf"

# Hyprpaper setup
HYPRPAPER_LOCAL_DIR="$HOME/.config/hypr-local/hyprpaper"
WALLPAPER_DIR="$HOME/Pictures/Starfield"
DOTFILES_WALL_DIR="$HOME/.dotfiles/Pictures/Starfield"

mkdir -p "$HYPRPAPER_LOCAL_DIR" "$WALLPAPER_DIR"

for img in "$DOTFILES_WALL_DIR"/*.png; do
  base_img="$(basename "$img")"
  [ ! -f "$WALLPAPER_DIR/$base_img" ] && cp "$img" "$WALLPAPER_DIR/"
done

HYPRPAPER_CONF="$HYPRPAPER_LOCAL_DIR/hyprpaper.conf"

if [ ! -f "$HYPRPAPER_CONF" ]; then
cat <<EOF > "$HYPRPAPER_CONF"
wallpaper {
    monitor =
    path     = \$HOME/Pictures/Starfield/Starfield_14.png
    fit_mode = cover
}
splash = false
EOF
fi

# Hyprland local override setup
LOCAL_DIR="$HOME/.config/hypr-local/ScrollingToggle"
BASE_FILE="$HOME/.config/hypr/looknfeel.conf"
LOCAL_FILE="$LOCAL_DIR/looknfeel.conf"

# Create directory if it doesn't exist
mkdir -p "$LOCAL_DIR"

# Copy base file if override doesn't exist yet
if [ ! -f "$LOCAL_FILE" ]; then
    echo "Creating local override for looknfeel.conf"
    cp "$BASE_FILE" "$LOCAL_FILE"
else
    echo "Local override already exists, skipping copy"
fi

# Bashrc sourcing
BASHRC="$HOME/.bashrc"

grep -qxF '[[ -f ~/.dotfiles/.bash_prompt ]] && source ~/.dotfiles/.bash_prompt' "$BASHRC" || \
echo '[[ -f ~/.dotfiles/.bash_prompt ]] && source ~/.dotfiles/.bash_prompt' >> "$BASHRC"

grep -qxF '[[ -f ~/.dotfiles/bash_env ]] && source ~/.dotfiles/bash_env' "$BASHRC" || \
echo '[[ -f ~/.dotfiles/bash_env ]] && source ~/.dotfiles/bash_env' >> "$BASHRC"

grep -qxF '[[ -f ~/.dotfiles/bash_aliases ]] && source ~/.dotfiles/bash_aliases' "$BASHRC" || \
echo '[[ -f ~/.dotfiles/bash_aliases ]] && source ~/.dotfiles/bash_aliases' >> "$BASHRC"

log "🎉 Setup complete! Reboot recommended."