#!/bin/bash
set -e

PROJECT_DIR="$HOME/photo_frame"
AUTOSTART_DIR="$HOME/.config/autostart"
APPLICATIONS_DIR="$HOME/.local/share/applications"
CURRENT_USER="$(id -un)"

# Clean leftovers from previous versions.
pkill -TERM -f "/usr/bin/python3 /home/pacgeo/photo_frame/photo_frame.py" 2>/dev/null || true
pkill -TERM -f "/home/pacgeo/photo_frame/run_photo_frame.sh" 2>/dev/null || true
sleep 0.5
pkill -KILL -f "/usr/bin/python3 /home/pacgeo/photo_frame/photo_frame.py" 2>/dev/null || true
pkill -KILL -f "/home/pacgeo/photo_frame/run_photo_frame.sh" 2>/dev/null || true
sudo systemctl disable --now photo-frame-emergency-exit.service 2>/dev/null || true
sudo systemctl disable --now photo-frame-f12-toggle.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/photo-frame-emergency-exit.service
sudo rm -f /etc/systemd/system/photo-frame-f12-toggle.service
sudo systemctl daemon-reload
rm -f "$PROJECT_DIR/.stop_requested" "$PROJECT_DIR/.frame_group_pid"
rm -f "$PROJECT_DIR/.photo_frame.lock"


# Remove the old F12 emergency/toggle services.
sudo systemctl disable --now photo-frame-f12-toggle.service 2>/dev/null || true
sudo systemctl disable --now photo-frame-emergency-exit.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/photo-frame-f12-toggle.service
sudo rm -f /etc/systemd/system/photo-frame-emergency-exit.service
sudo systemctl daemon-reload

echo "Installing photo-frame controls for user: $CURRENT_USER"

sudo apt update
sudo apt install -y python3-gpiozero util-linux python3-pip python3-pil libheif1

mkdir -p "$PROJECT_DIR/logs"
mkdir -p "$AUTOSTART_DIR"
mkdir -p "$APPLICATIONS_DIR"

chmod +x "$PROJECT_DIR/run_photo_frame.sh"
chmod +x "$PROJECT_DIR/start_photo_frame.sh"
chmod +x "$PROJECT_DIR/stop_photo_frame.sh"
chmod +x "$PROJECT_DIR/install_photo_frame.sh"

cp "$PROJECT_DIR/photo-frame.desktop" "$AUTOSTART_DIR/photo-frame.desktop"
if [ -f "$PROJECT_DIR/stop-photo-frame.desktop" ]; then
    cp "$PROJECT_DIR/stop-photo-frame.desktop" "$APPLICATIONS_DIR/stop-photo-frame.desktop"
fi


# Clear any stale hard-stop from an older broken version.
rm -f "$PROJECT_DIR/.stop_requested"

echo
echo "Installed."

rm -f "$PROJECT_DIR/.frame_group_pid"


# HEIC / HEIF / AVIF decoding support.
# Raspberry Pi OS may mark system Python as externally managed, so install
# pillow-heif into this user's site-packages while explicitly allowing it.
python3 -m pip install --user --break-system-packages --upgrade pillow-heif || {
    echo "WARNING: pillow-heif install failed. HEIC/HEIF decoding will not work until installed."
}

# Confirm decoder availability immediately.
python3 - <<'PYTEST'
try:
    import pillow_heif
    print('HEIC/HEIF decoder: OK')
except Exception as exc:
    print('HEIC/HEIF decoder: FAILED ->', exc)
PYTEST
