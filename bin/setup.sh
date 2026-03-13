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
# Detect NVIDIA GPU via lspci — covers all controller types (VGA, 3D, Display)
# On Optimus setups the NVIDIA card appears as "3D controller", not "VGA compatible controller"
HAS_NVIDIA=false
lspci | grep -qi nvidia && HAS_NVIDIA=true

if [ "$HAS_NVIDIA" = true ]; then
  log "NVIDIA GPU detected — NVIDIA driver stack will be installed."
else
  log "No NVIDIA GPU detected — skipping NVIDIA setup."
fi

sudo -v  # ask for sudo password upfront

log "Updating system..."
sudo pacman -Syu --noconfirm

log "Ensuring essential build tools..."
sudo pacman -S --noconfirm --needed git base-devel

# === YAY BOOTSTRAP ===
if ! command -v yay &>/dev/null; then
  log "Installing yay (AUR helper)..."
  cd /tmp
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  cd ~
else
  log "yay already installed."
fi

# === SERVICE ENABLE HELPER ===
enable_service() {
  local svc=$1
  if [ "$IN_CONTAINER" = false ]; then
    log "Enabling and starting $svc..."
    sudo systemctl enable --now "$svc"
  else
    log "Skipping $svc inside container..."
  fi
}

# === INSTALLATION GROUPS ===

install_base() {
  log "Installing base packages..."
  sudo pacman -S --noconfirm --needed \
    base base-devel linux linux-firmware amd-ucode efibootmgr \
    dosfstools exfatprogs ntfs-3g unzip wget smartmontools zram-generator
}

install_network() {
  log "Installing network & Bluetooth..."
  sudo pacman -S --noconfirm --needed \
    bluez bluez-utils blueman iwd wpa_supplicant openssh
  #enable_service bluetooth.service
}

install_tools() {
  log "Installing system tools..."
  sudo pacman -S --noconfirm --needed \
    htop btop fastfetch jq 7zip file-roller vim nano yad zenity \
    udiskie gvfs gvfs-mtp gvfs-gphoto2 cpio cmake konsole
}

install_desktop() {
  log "Installing Hyprland environment..."
  sudo pacman -S --noconfirm --needed \
    hyprland uwsm xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-utils \
    dunst waybar wofi thunar thunar-archive-plugin tumbler polkit-kde-agent \
    sddm gnome-keyring seahorse dotnet-runtime-8.0 hyprpaper mpv flatpak
  #enable_service sddm.service
}

install_fonts_themes() {
  log "Installing fonts & themes..."
  sudo pacman -S --noconfirm --needed \
    gnome-themes-extra adwaita-icon-theme \
    ttf-dejavu ttf-hack-nerd ttf-jetbrains-mono-nerd \
    ttf-nerd-fonts-symbols woff2-font-awesome
}

install_audio() {
  log "Installing audio stack..."
  sudo pacman -S --noconfirm --needed \
    pipewire pipewire-alsa pipewire-pulse wireplumber wiremix gst-plugin-pipewire picard yt-dlp chromaprint mpd mpc rmpc
  yay -S --noconfirm --needed pithos cavalier
}

install_apps() {
  log "Installing main apps..."
  yay -S --noconfirm --needed \
    brave-bin chromium thunderbird onlyoffice-bin mousepad gnome-clocks gnome-weather localsend-bin helium-browser-bin
}

install_video_drivers() {
  log "Installing GPU / media drivers..."
  sudo pacman -S --noconfirm --needed \
    vulkan-intel vulkan-radeon vulkan-nouveau intel-media-driver libva-intel-driver lib32-vulkan-radeon lib32-mesa\
    sof-firmware xf86-video-amdgpu xf86-video-ati xf86-video-nouveau
}

install_nvidia_gpu() {
  # Requires: NVIDIA GPU detected via HAS_NVIDIA flag
  # Installs the open DKMS driver stack and explicitly triggers the DKMS build.
  # Without linux-headers + manual dkms install, nvidia-smi fails silently
  # and apps like Ollama fall back to CPU. This sequence is the known-good fix.
  # Nouveau is blacklisted at the kernel module level to prevent conflicts.
  # Note: userspace packages (vulkan-nouveau, xf86-video-nouveau) are left
  # in place from install_video_drivers — only the kernel module is blocked.

  log "Installing NVIDIA drivers (open DKMS)..."
  sudo pacman -S --noconfirm --needed \
    linux-headers \
    linux-firmware-nvidia \
    nvidia-open-dkms \
    nvidia-utils \
    nvidia-settings \
    lib32-nvidia-utils

  log "Blacklisting nouveau kernel module..."
  sudo tee /etc/modprobe.d/blacklist-nouveau.conf > /dev/null <<EOF
blacklist nouveau
options nouveau modeset=0
EOF

  log "Triggering DKMS build for NVIDIA module..."
  NVIDIA_VER=$(pacman -Q nvidia-open-dkms | awk '{print $2}' | cut -d- -f1)
  KERNEL_VER=$(uname -r)

  # Check if module is already built for this kernel — skip if so
  if dkms status nvidia/"$NVIDIA_VER" -k "$KERNEL_VER" 2>/dev/null | grep -q "installed"; then
    log "NVIDIA DKMS module already built for kernel $KERNEL_VER — skipping build."
  else
    log "Building NVIDIA DKMS module for kernel $KERNEL_VER..."
    if sudo dkms install nvidia/"$NVIDIA_VER" -k "$KERNEL_VER"; then
      log "DKMS build successful."
    else
      warn "DKMS build failed — nvidia-smi may not work until after a reboot or manual fix."
      warn "Run: sudo dkms install nvidia/$NVIDIA_VER -k $KERNEL_VER"
    fi
  fi

  log "NVIDIA setup complete — reboot required for module to load."
}

install_extras() {
  log "Installing fun / extras..."
  yay -S --noconfirm --needed impala
}

link_dotfiles() {
  log "Linking dotfiles..."
  bash ~/.dotfiles/bin/link.sh
}

# === EXECUTION ORDER ===
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

# Disable systemd-boot menu timeout (instant boot)
# loader.conf is usually located at:
#   /boot/loader/loader.conf   (most Arch installs)
#   /efi/loader/loader.conf    (some EFI layouts)
for LOADER_CONF in /boot/loader/loader.conf /efi/loader/loader.conf; do
  if [ -f "$LOADER_CONF" ]; then
    sudo sed -i 's/^timeout .*/timeout 0/' "$LOADER_CONF"
    if ! grep -q '^timeout ' "$LOADER_CONF"; then
      echo "timeout 0" | sudo tee -a "$LOADER_CONF" >/dev/null
    fi
    echo "systemd-boot timeout set to 0 in $LOADER_CONF"
  fi
done


# --- SDDM autologin configuration ---
# Drop-in config location: /etc/sddm.conf.d/

#USER_NAME="${SUDO_USER:-$USER}"
#SESSION_NAME="hyprland"

#sudo mkdir -p /etc/sddm.conf.d

#sudo tee /etc/sddm.conf.d/autologin.conf > /dev/null <<EOF
#[Autologin]
#User=$USER_NAME
#Session=$SESSION_NAME
#EOF

# ---- GTK Dark Mode ----
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'

#=======================================================

# --- Install Flatpaks - for now, only Brave ---

log "Checking Flatpak installation"

if ! command -v flatpak >/dev/null 2>&1; then
  log "Installing Flatpak"
  sudo pacman -S --needed --noconfirm flatpak
else
  log "Flatpak already installed"
fi

log "Checking Flatpak Brave Browser"

if ! flatpak list --app | grep -q "^Brave Browser"; then
  log "Installing Flatpak Brave Browser"
  flatpak install -y flathub com.brave.Browser
else
  log "Flatpak Brave already installed"
fi

#=======================================================


BASHRC="$HOME/.bashrc"

# Ensure each source line is only added once
grep -qxF '[[ -f ~/.dotfiles/.bash_prompt ]] && source ~/.dotfiles/.bash_prompt' "$BASHRC" || echo '[[ -f ~/.dotfiles/.bash_prompt ]] && source ~/.dotfiles/.bash_prompt' >> "$BASHRC"
grep -qxF '[[ -f ~/.dotfiles/bash_env ]] && source ~/.dotfiles/bash_env' "$BASHRC" || echo '[[ -f ~/.dotfiles/bash_env ]] && source ~/.dotfiles/bash_env' >> "$BASHRC"
grep -qxF '[[ -f ~/.dotfiles/bash_aliases ]] && source ~/.dotfiles/bash_aliases' "$BASHRC" || echo '[[ -f ~/.dotfiles/bash_aliases ]] && source ~/.dotfiles/bash_aliases' >> "$BASHRC"

echo "Dotfiles sources added to .bashrc."

echo "Finalizing/enabling service for audio stack for mpd — allows rmpc to function"

# MPD section -------------------

systemctl --user enable mpd
systemctl --user start mpd

# run this after cloning @ .dotfiles:
# git update-index --skip-worktree config/mpd/database config/mpd/state

# After cloning use this command to block any updates to git:
# 'git update-index --skip-worktree config/mpd/database config/mpd/state'
# make sure to navigate to your root dotfiles folder — cd .dotfiles :)

# -----------------------------
# Hyprland local window rules - necessary for layout capture
# -----------------------------
RULE_DIR="$HOME/.config/hypr-local-windowrules"

mkdir -p "$RULE_DIR"

touch \
  "$RULE_DIR/floating.conf" \
  "$RULE_DIR/tiled.conf"

# -----------------------------
# Hyprpaper local configuration
# -----------------------------
HYPRPAPER_LOCAL_DIR="$HOME/.config/hyprpaper-local"
WALLPAPER_DIR="$HOME/Pictures/Starfield"
DOTFILES_WALL_DIR="$HOME/.dotfiles/Pictures/Starfield"

mkdir -p "$HYPRPAPER_LOCAL_DIR"
mkdir -p "$WALLPAPER_DIR"

# Copy Starfield wallpapers from dotfiles if missing
for img in "$DOTFILES_WALL_DIR"/*.png; do
  base_img="$(basename "$img")"

  if [ ! -f "$WALLPAPER_DIR/$base_img" ]; then
    cp "$img" "$WALLPAPER_DIR/"
  fi
done

# Create local hyprpaper config if it doesn't exist
HYPRPAPER_CONF="$HYPRPAPER_LOCAL_DIR/hyprpaper-local.conf"

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

log "🎉 Setup complete! You can reboot now."
