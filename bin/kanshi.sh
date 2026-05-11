#!/bin/bash
# kanshi-setup.sh - Setup kanshi display management for laptop systems
set -e

echo "Setting up kanshi..."

# Configure logind to ignore lid switch (kanshi handles display management)
LOGIND_DROPIN="/etc/systemd/logind.conf.d/kanshi-lid.conf"

if grep -q "HandleLidSwitch=ignore" "$LOGIND_DROPIN" 2>/dev/null; then
    echo "Lid switch settings already configured, skipping..."
else
    echo "Configuring lid switch behavior..."
    sudo mkdir -p /etc/systemd/logind.conf.d
    sudo tee "$LOGIND_DROPIN" > /dev/null << 'EOF'
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
EOF
   
fi

# Install kanshi from AUR if not already installed
if ! command -v kanshi &> /dev/null; then
    echo "Installing kanshi..."
    sudo pacman -S kanshi --noconfirm 
else
    echo "Kanshi already installed, skipping..."
fi

# Create systemd user service directory if needed
mkdir -p ~/.config/systemd/user

# Write the service file (safe to overwrite, it's static)
cat > ~/.config/systemd/user/kanshi.service << 'EOF'
[Unit]
Description=Dynamic display configuration daemon
PartOf=graphical-session.target

[Service]
ExecStart=/usr/bin/kanshi
Restart=on-failure

[Install]
WantedBy=default.target
EOF

echo "Kanshi service file written."

# Reload systemd user daemon to pick up the new service file
systemctl --user daemon-reload

# Enable and start only if not already active
if systemctl --user is-enabled --quiet kanshi.service; then
    echo "Kanshi service already enabled, restarting to apply any changes..."
    systemctl --user restart kanshi.service
else
    echo "Enabling and starting kanshi service..."
    systemctl --user enable --now kanshi.service
fi

# Create kanshi config dir if needed
mkdir -p ~/.config/kanshi

if [ ! -f ~/.config/kanshi/config ]; then
    cat > ~/.config/kanshi/config << 'EOF'
# Kanshi display profile config
# Run 'hyprctl monitors' while docked/undocked to get your output names

profile undocked {
    output eDP-1 enable
}

# profile docked {
#     output eDP-1 disable
#     output DP-2 enable scale 1
# }
EOF
    echo "Default kanshi config created at ~/.config/kanshi/config"
    echo "Edit it with your actual monitor output names (hyprctl monitors)"
else
    echo "Kanshi config already exists, skipping..."
fi

echo ""
echo "Kanshi setup complete!"
echo "Verify service status with: systemctl --user status kanshi"

echo "A reboot is required to apply lid switch settings."
read -rp "Reboot now? (y/N): " confirm
[[ "$confirm" == "y" ]] && sudo reboot