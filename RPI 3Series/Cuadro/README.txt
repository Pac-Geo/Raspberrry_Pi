PHOTO FRAME V3 - INSTALL

1. Copy these files into /home/pacgeo/photo_frame/:
   photo_frame.py
   photo_frame_config.json
   run_photo_frame.sh
   photo-frame.desktop
   install_photo_frame.sh

2. Run:
   cd ~/photo_frame
   chmod +x run_photo_frame.sh install_photo_frame.sh
   ./install_photo_frame.sh

3. Test manually:
   ./run_photo_frame.sh

4. Reboot to test automatic startup:
   sudo reboot

Log file:
   ~/photo_frame/logs/photo_frame.log

Folder-based ordering:
   Put media in subfolders under CUADRO/PHOTOS.
   Example:
     PHOTOS/1950s/...
     PHOTOS/1960s/...
     PHOTOS/Christmas/...
   Folders and filenames are ordered alphabetically.

Video behavior was intentionally not changed in this revision.

EMERGENCY / MANUAL EXIT
-----------------------
If Q/Esc cannot reach the slideshow because another window (for example a
video player) owns keyboard focus:

1. Press Ctrl+Alt+T to open a Terminal.
2. Run:
       ~/photo_frame/stop_photo_frame.sh

The stop script terminates the slideshow and any VLC/mpv video player and
sets a stop flag so the crash watchdog does NOT restart the application.
A "Stop Photo Frame" launcher is also installed in the desktop application menu.

V3.2 GLOBAL EMERGENCY EXIT
--------------------------
Press F12 at any time to stop the entire photo-frame application.
The listener runs independently of the slideshow and reads the physical
keyboard directly, so it still works if another full-screen application owns
keyboard focus. The watchdog is told this was a manual stop and will not
restart the frame.

Install once with ./install_photo_frame.sh. After that, no command is needed
to exit: just press F12.


V3.3 PIR / POWER MANAGEMENT
---------------------------
PIR wiring:
  VCC -> 5V (physical pin 2 or 4)
  GND -> Ground (physical pin 6 is convenient)
  OUT -> physical pin 11 = BCM GPIO17 = WiringPi/Pi4J GPIO0

Behavior:
  - PIR motion resets the inactivity timer.
  - After 1800 seconds (30 minutes) of no motion, the display is powered off.
  - PIR motion wakes the display automatically.
  - The Pi itself remains running while the display sleeps.
  - Drive sync, USB monitoring, logging, watchdog and F12 emergency exit remain active.
  - Video logic is unchanged in this release.

Config keys:
  pir_enabled
  pir_bcm_pin
  pir_poll_seconds
  inactivity_timeout_seconds
  display_sleep_enabled


V3.4 PIR SLEEP FIX
------------------
Testing timeout is 45 seconds.
Final desired timeout is 45 minutes = 2700 seconds.

Important behavior change:
  - The inactivity timer resets only on a new PIR LOW->HIGH motion event.
  - A PIR that holds its OUT pin HIGH no longer resets the timer continuously.
  - At timeout, pygame is first forced to a black screen.
  - The program then also attempts hardware display power-off.
  - A NEW PIR LOW->HIGH event wakes the display and redraws the slideshow.
  - Terminal/log diagnostics print PIR HIGH/LOW state and inactivity time every 5 seconds.

When testing is complete, change:
  "inactivity_timeout_seconds": 45
To:
  "inactivity_timeout_seconds": 2700
