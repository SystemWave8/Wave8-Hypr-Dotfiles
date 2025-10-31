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
if ! grep -q "Arch" /etc/os-release; then
  warn "This script is designed for Arch Linux systems only."
  exit 1
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
    udiskie gvfs gvfs-mtp gvfs-gphoto2
}

install_desktop() {
  log "Installing Hyprland environment..."
  sudo pacman -S --noconfirm --needed \
    hyprland uwsm xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-utils \
    dunst waybar wofi thunar thunar-archive-pluin tumbler polkit-kde-agent \
    sddm gnome-keyring seahorse dotnet-runtime-8.0 hyprpaper
  #enable_service sddm.service
}

install_fonts_themes() {
  log "Installing fonts & themes..."
  sudo pacman -S --noconfirm --needed \
    gnome-themes-extra \ adwaita-gtk3 adwaita-icon-theme
    ttf-dejavu ttf-hack-nerd ttf-jetbrains-mono-nerd \
    ttf-nerd-fonts-symbols woff2-font-awesome
}

install_audio() {
  log "Installing audio stack..."
  sudo pacman -S --noconfirm --needed \
    pipewire pipewire-alsa pipewire-pulse wireplumber wiremix gst-plugin-pipewire
  yay -S --noconfirm --needed pithos cavalier
}

install_apps() {
  log "Installing main apps..."
  yay -S --noconfirm --needed \
    brave-bin chromium thunderbird libreoffice-fresh mousepad gnome-clocks gnome-weather
}

install_video_drivers() {
  log "Installing GPU / media drivers..."
  sudo pacman -S --noconfirm --needed \
    vulkan-intel vulkan-radeon vulkan-nouveau intel-media-driver libva-intel-driver \
    sof-firmware xf86-video-amdgpu xf86-video-ati xf86-video-nouveau
  # nvidia-dkms nvidia-settings nvidia-utils # Likely will need these few

}

install_extras() {
  log "Installing fun / extras..."
  yay -S --noconfirm --needed tty-clock cmatrix impala
}

link_dotfiles() {
  log "Linking dotfiles..."
  bash ./link.sh
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
install_extras
link_dotfiles

log "🎉 Setup complete! You can reboot now."
