sudo apt update
sudo apt install -y python3-gpiozero
#!/bin/bash
set -e

PROJECT_DIR="$HOME/photo_frame"
AUTOSTART_DIR="$HOME/.config/autostart"
APPLICATIONS_DIR="$HOME/.local/share/applications"
CURRENT_USER="$(id -un)"

mkdir -p "$PROJECT_DIR/logs"
mkdir -p "$AUTOSTART_DIR"
mkdir -p "$APPLICATIONS_DIR"

chmod +x "$PROJECT_DIR/run_photo_frame.sh"
chmod +x "$PROJECT_DIR/stop_photo_frame.sh"
chmod +x "$PROJECT_DIR/install_photo_frame.sh"
chmod +x "$PROJECT_DIR/emergency_exit_daemon.py"

cp "$PROJECT_DIR/photo-frame.desktop" "$AUTOSTART_DIR/photo-frame.desktop"
cp "$PROJECT_DIR/stop-photo-frame.desktop" "$APPLICATIONS_DIR/stop-photo-frame.desktop"

# evdev lets the emergency listener read the physical keyboard directly.
sudo apt-get update
sudo apt-get install -y python3-evdev

# Install a tiny system service. It runs as root only so it can read
# /dev/input/event* regardless of which application owns keyboard focus.
sudo tee /etc/systemd/system/photo-frame-emergency-exit.service >/dev/null <<EOF
[Unit]
Description=Photo Frame Global Emergency Exit Key
After=multi-user.target

[Service]
Type=simple
Environment=PHOTO_FRAME_USER=$CURRENT_USER
ExecStart=/usr/bin/python3=$PROJECT_DIR/emergency_exit_daemon.py
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

# Fix ExecStart typo safely after heredoc expansion.
sudo sed -i "s#ExecStart=/usr/bin/python3=#ExecStart=/usr/bin/python3 #" /etc/systemd/system/photo-frame-emergency-exit.service

sudo systemctl daemon-reload
sudo systemctl enable --now photo-frame-emergency-exit.service

printf '\nInstalled photo-frame autostart.\n'
printf 'It will start automatically the next time the Raspberry Pi desktop logs in.\n'
printf 'Crash watchdog: enabled by run_photo_frame.sh.\n'
printf 'Normal Q/Esc exit during photos: does not restart.\n'
printf '\nGLOBAL EMERGENCY EXIT: press F12 at any time.\n'
printf 'F12 works even when a video/player window has keyboard focus.\n'
printf 'No terminal or command is required after this installation.\n\n'
