#!/usr/bin/env fish

set -l INSTALL_DIR "$HOME/Music Production/Micro MK3 Driver"
set -l REPO_DIR "$INSTALL_DIR/maschine-mikro-mk3-driver"
set -l REPO_URL "https://github.com/r00tman/maschine-mikro-mk3-driver.git"

echo "🎛️  Maschine Mikro MK3 Linux Driver"
echo "=================================="
echo

# --------------------------------------------------
# System dependencies
# --------------------------------------------------

echo "📦 Checking system dependencies..."

sudo pacman -S --needed rust base-devel alsa-lib pipewire-jack libusb systemd-libs

if test $status -ne 0
    echo "❌ Package installation failed."
    exit 1
end

# --------------------------------------------------
# Clone repository
# --------------------------------------------------

echo
echo "📥 Checking driver source..."

mkdir -p "$INSTALL_DIR"

if test -d "$REPO_DIR/.git"
    echo "✓ Driver repository already exists."
else
    echo "⬇️  Cloning driver..."
    git clone "$REPO_URL" "$REPO_DIR"

    if test $status -ne 0
        echo "❌ Git clone failed."
        exit 1
    end
end

cd "$REPO_DIR"

# --------------------------------------------------
# udev rule
# --------------------------------------------------

echo
echo "🔐 Checking udev rule..."

if not test -f 98-maschine.rules
    echo "❌ udev rule not found in driver source."
    exit 1
end

if not test -f /etc/udev/rules.d/98-maschine.rules
    sudo cp 98-maschine.rules /etc/udev/rules.d/98-maschine.rules
    echo "✅ udev rule installed."
else
    echo "✓ udev rule already exists."
end

sudo udevadm control --reload-rules
sudo udevadm trigger

# --------------------------------------------------
# Build
# --------------------------------------------------

echo
echo "🔨 Building driver..."

cargo build --release

if test $status -ne 0
    echo "❌ Driver build failed."
    exit 1
end

# --------------------------------------------------
# Done
# --------------------------------------------------

echo
echo "✅ Maschine Mikro MK3 driver is ready."
echo
echo "Driver:"
echo "  $REPO_DIR/target/release/driver"
echo
echo "Run:"
echo "  $REPO_DIR/target/release/driver --config $REPO_DIR/example_config.toml"
echo


# After install
	# cd ~/Music\ Production/Micro\ MK3\ Driver/maschine-mikro-mk3-driver

	#./target/release/driver --config example_config.toml

# this should get you to the right directory and test the micro as needed