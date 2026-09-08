#!/bin/bash
set -u

PROJECT_DIR="/home/pacgeo/photo_frame"
LOCK_FILE="$PROJECT_DIR/.photo_frame.lock"
PID_FILE="$PROJECT_DIR/.frame_group_pid"

cd "$PROJECT_DIR" || exit 1

# Only one slideshow/watchdog stack may run at a time.
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    echo "Another photo-frame instance is already running. This launch will exit."
    exit 0
fi

echo "$$" > "$PID_FILE"

cleanup() {
    rm -f "$PID_FILE"
}
trap cleanup EXIT

while true; do
    /usr/bin/python3 "$PROJECT_DIR/photo_frame.py"
    code=$?

    # Q / Esc are intentional normal exits.
    # Do NOT restart after a clean exit.
    if [ "$code" -eq 0 ]; then
        exit 0
    fi

    echo "Photo frame crashed with exit code $code. Restarting in 5 seconds..." >&2
    sleep 5
done
