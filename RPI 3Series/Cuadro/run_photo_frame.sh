#!/bin/bash
set -u
PROJECT_DIR="/home/pacgeo/photo_frame"
STOP_FLAG="$PROJECT_DIR/.stop_requested"

cd "$PROJECT_DIR" || exit 1

# A fresh manual/autostart launch means the user wants the frame running again.
rm -f "$STOP_FLAG"

while true; do
    /usr/bin/python3 "$PROJECT_DIR/photo_frame.py"
    code=$?

    # Emergency stop script creates this before terminating Python/VLC.
    # Do not let the watchdog immediately restart the application.
    if [ -f "$STOP_FLAG" ]; then
        rm -f "$STOP_FLAG"
        exit 0
    fi

    # Normal Q/Esc exit: stay stopped.
    if [ "$code" -eq 0 ]; then
        exit 0
    fi

    echo "Photo frame crashed with exit code $code. Restarting in 5 seconds..." >&2
    sleep 5
done
