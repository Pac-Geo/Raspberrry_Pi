#!/bin/bash
# Emergency/manual stop for the entire photo-frame application.
# Works whether a photo or a separate video-player window currently has focus.

PROJECT_DIR="/home/pacgeo/photo_frame"
STOP_FLAG="$PROJECT_DIR/.stop_requested"

mkdir -p "$PROJECT_DIR"
touch "$STOP_FLAG"

# Stop external video players first, if one is active.
pkill -TERM -x vlc 2>/dev/null || true
pkill -TERM -x cvlc 2>/dev/null || true
pkill -TERM -x mpv 2>/dev/null || true

# Stop the Python slideshow.
pkill -TERM -f '/home/pacgeo/photo_frame/photo_frame.py' 2>/dev/null || true

sleep 1

# Escalate only if something ignored TERM.
pkill -KILL -x vlc 2>/dev/null || true
pkill -KILL -x cvlc 2>/dev/null || true
pkill -KILL -x mpv 2>/dev/null || true
pkill -KILL -f '/home/pacgeo/photo_frame/photo_frame.py' 2>/dev/null || true

echo "Photo frame stopped."
