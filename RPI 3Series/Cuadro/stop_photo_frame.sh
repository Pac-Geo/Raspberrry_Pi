#!/bin/bash
PROJECT_DIR="/home/pacgeo/photo_frame"
PID_FILE="$PROJECT_DIR/.frame_group_pid"

if [ -f "$PID_FILE" ]; then
    GROUP_PID="$(cat "$PID_FILE" 2>/dev/null || true)"
    if [ -n "$GROUP_PID" ] && kill -0 "$GROUP_PID" 2>/dev/null; then
        kill -TERM -- "-$GROUP_PID" 2>/dev/null || true
        sleep 0.5
        kill -KILL -- "-$GROUP_PID" 2>/dev/null || true
    fi
fi

pkill -TERM -f "/usr/bin/python3 /home/pacgeo/photo_frame/photo_frame.py" 2>/dev/null || true
pkill -TERM -x vlc 2>/dev/null || true
pkill -TERM -x cvlc 2>/dev/null || true
pkill -TERM -x mpv 2>/dev/null || true

rm -f "$PID_FILE"

echo "PHOTO FRAME STOPPED."
