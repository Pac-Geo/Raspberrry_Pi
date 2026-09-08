#!/bin/bash
PROJECT_DIR="/home/pacgeo/photo_frame"
mkdir -p "$PROJECT_DIR"

setsid /bin/bash "$PROJECT_DIR/run_photo_frame.sh" >/dev/null 2>&1 &
echo "PHOTO FRAME START REQUESTED."
