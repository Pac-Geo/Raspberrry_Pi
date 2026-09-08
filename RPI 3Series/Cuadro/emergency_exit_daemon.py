#!/usr/bin/env python3
"""Global emergency-exit key listener for the Raspberry Pi photo frame.

Runs as a small root system service and listens directly to Linux input devices,
so it still sees the key even when VLC or another window owns keyboard focus.

Emergency key: F12
"""

import os
import select
import signal
import subprocess
import time
from pathlib import Path

from evdev import InputDevice, ecodes, list_devices

USER = os.environ.get("PHOTO_FRAME_USER", "pacgeo")
HOME = Path(f"/home/{USER}")
PROJECT_DIR = HOME / "photo_frame"
STOP_FLAG = PROJECT_DIR / ".stop_requested"

RUNNING = True


def handle_signal(_signum, _frame):
    global RUNNING
    RUNNING = False


def emergency_stop():
    PROJECT_DIR.mkdir(parents=True, exist_ok=True)
    STOP_FLAG.touch()

    # Stop video players first, then the slideshow. The watchdog sees the
    # stop flag and therefore does not restart the application.
    for name in ("vlc", "cvlc", "mpv"):
        subprocess.run(["pkill", "-TERM", "-x", name], check=False,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    subprocess.run(
        ["pkill", "-TERM", "-f", str(PROJECT_DIR / "photo_frame.py")],
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    print("F12 emergency exit triggered.", flush=True)


def open_keyboards():
    devices = []
    for path in list_devices():
        try:
            dev = InputDevice(path)
            caps = dev.capabilities().get(ecodes.EV_KEY, [])
            # Only keep devices that can produce F12.
            if ecodes.KEY_F12 in caps:
                devices.append(dev)
            else:
                dev.close()
        except (OSError, PermissionError):
            pass
    return devices


def main():
    signal.signal(signal.SIGTERM, handle_signal)
    signal.signal(signal.SIGINT, handle_signal)

    devices = []
    last_scan = 0.0

    while RUNNING:
        now = time.monotonic()

        # Rescan periodically so USB/Bluetooth keyboards can be hot-plugged.
        if not devices or now - last_scan >= 5.0:
            for dev in devices:
                try:
                    dev.close()
                except OSError:
                    pass
            devices = open_keyboards()
            last_scan = now

        if not devices:
            time.sleep(1.0)
            continue

        try:
            ready, _, _ = select.select(devices, [], [], 1.0)
        except (OSError, ValueError):
            devices = []
            continue

        for dev in ready:
            try:
                for event in dev.read():
                    if (
                        event.type == ecodes.EV_KEY
                        and event.code == ecodes.KEY_F12
                        and event.value == 1
                    ):
                        emergency_stop()
            except OSError:
                devices = []
                break

    for dev in devices:
        try:
            dev.close()
        except OSError:
            pass


if __name__ == "__main__":
    main()
