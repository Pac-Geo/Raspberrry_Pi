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


V3.5 HARD STOP
--------------
F12 now stops the entire photo-frame stack:
  - slideshow
  - VLC/mpv
  - run_photo_frame.sh watchdog

A .stop_requested flag remains after F12 so nothing can automatically
restart the frame.

To intentionally start the frame again:
  ~/photo_frame/start_photo_frame.sh


V3.6 F12 TOGGLE
---------------
F12 is now a two-state toggle:

  Frame running
      F12 -> HARD STOP ON
      - slideshow stops
      - VLC/mpv stops
      - watchdog stops
      - .stop_requested blocks automatic restart

  Frame stopped
      F12 -> HARD STOP OFF
      - .stop_requested is removed
      - watchdog starts again
      - slideshow starts again

No terminal command is required for either action.

The F12 listener remains a separate systemd service, so it continues listening
even while the photo-frame application itself is fully stopped.


V3.7 F12 TOGGLE FIX
-------------------
- Fixed installer so the #!/bin/bash line is correctly first.
- Replaced the old F12 service with photo-frame-f12-toggle.service.
- Installer removes any stale .stop_requested file from older versions.
- F12 daemon runs as root so it can read /dev/input/event* directly.
- The service prints the keyboard device it is listening to.
- start_photo_frame.sh now checks photo_frame.py directly rather than
  accidentally matching its own wrapper command.


V3.8 SAFE SLEEP / WAKE
----------------------
- Removed HDMI/DPMS power-off commands.
- Sleep is now a black fullscreen while HDMI stays active.
- PIR motion wakes the slideshow.
- Any normal keyboard key or mouse movement/click also wakes it.
- Q/Esc still exit and F12 still toggles hard stop/start.
- Test timeout remains 45 seconds; final target is 2700 seconds (45 minutes).


V3.9 HDMI POWER SLEEP
---------------------
Sleep behavior now conserves display power:

  - At the inactivity timeout, the frame first draws black.
  - It then disables the HDMI/display output.
  - The Raspberry Pi itself remains running.
  - PIR motion turns HDMI/display output back on and restores the slideshow.
  - Keyboard activity turns HDMI/display output back on and restores the slideshow.
  - Mouse activity turns HDMI/display output back on and restores the slideshow.
  - Q/Esc and the F12 hard-stop/start toggle remain unchanged.

The program remembers which display-power method worked for sleep and tries
that same method first when waking.

Current test timeout:
  45 seconds

Final intended timeout after testing:
  2700 seconds = 45 minutes

V4.1 STOP + PIR FILTER FIX
--------------------------
F12 STOP now blocks restart first and kills every current or old
photo_frame.py/run_photo_frame.sh copy, including leftovers from older versions.

PIR raw HIGH is now treated only as the module output state, not as proof of a
new person. Startup PIR activity is ignored for 30 seconds and a new event is
accepted only after the line has been LOW continuously for 2 seconds.

The 45-second sleep/wake test remains unchanged.


V4.2 TRUE SINGLE-INSTANCE LOCK
------------------------------
The slideshow now uses a Linux flock lock around the entire watchdog process.

File used:
  /home/pacgeo/photo_frame/.photo_frame.lock

Important:
  The file itself is not the lock. Linux holds the lock in the kernel while
  run_photo_frame.sh is alive.

Behavior:
  - Only ONE run_photo_frame.sh supervisor can own the lock.
  - A second autostart/manual/F12 launch immediately exits without starting
    another slideshow.
  - The lock stays owned through watchdog restarts of photo_frame.py.
  - F12 STOP kills the active supervisor, which releases the lock.
  - F12 START clears the stop flag and starts exactly one new supervisor.
  - Old duplicate slideshow processes are still cleaned up during STOP/install.

This directly fixes the hidden second slideshow problem.


V4.3 CLEAN Q / ESC EXIT
-----------------------
The special F12 control has been removed.

Controls:
  Q   -> quit slideshow normally
  Esc -> quit slideshow normally

Behavior:
  - A normal Q/Esc exit returns code 0.
  - The watchdog sees code 0 and exits too, so the slideshow stays closed.
  - The Linux flock single-instance lock remains in place, so a second hidden
    slideshow cannot start at the same time.
  - Crash-only restart behavior remains: if photo_frame.py exits with an error,
    the watchdog restarts it after 5 seconds.
  - Old F12 systemd services are disabled and removed by the installer.
  - Any stale .stop_requested file from the old F12 design is removed.

Autostart:
  The frame still starts once at desktop login through start_photo_frame.sh.


V4.4 SLEEP FIX
--------------
V4.3 accidentally carried forward the old display-power stub even though the
config said "hdmi_power_off".  That mismatch is corrected here.

Testing behavior:
  - inactivity timeout = 45 seconds
  - screen is first drawn black
  - HDMI/display output is then actually disabled
  - PIR, keyboard, or mouse wake re-enables display output and redraws slideshow
  - Q/Esc clean exit and the single-instance lock remain unchanged

The terminal/log prints the raw PIR level, inactivity timer, and display state
every 5 seconds so the 45-second countdown can be verified directly.


V4.5 PIR SLEEP / WAKE FILTER FIX
--------------------------------
- PIR must remain LOW for 3 seconds before a new event can arm.
- PIR must then remain HIGH for at least 0.75 seconds before motion is accepted.
- When the display enters sleep, PIR wake is disarmed.
- The PIR must remain LOW for 5 seconds after sleep before wake can arm again.
- This prevents the same/noisy PIR transition from immediately waking the display.
- Mouse movement no longer wakes the frame because synthetic mouse-motion events
  can occur when fullscreen/display state changes.
- Keyboard keypress or mouse click can still wake as a manual fallback.
- Test timeout remains 45 seconds.


V4.6 PORTRAIT ORIENTATION
-------------------------
The slideshow is now configured for portrait mounting.

Setting:
  "display_rotation_degrees": 270

This means the slideshow content is rotated 90 degrees counterclockwise
relative to the original landscape orientation.

The physical monitor resolution is left unchanged.  The photo-frame program
creates a portrait logical canvas, renders photos into that canvas, and rotates
the final frame onto the display.

To change orientation later:
  0   = normal landscape
  90  = 90 degrees clockwise
  180 = upside down
  270 = 90 degrees counterclockwise


V4.7 FIT RESIZE
---------------
Photo foreground scaling now uses true FIT behavior.

- Small photos are enlarged until one dimension reaches the available frame.
- Large photos are reduced until the entire image fits.
- Aspect ratio is always preserved.
- The foreground photo is NEVER cropped.
- It does NOT use "fill" behavior.
- The existing blurred background remains behind photos whose aspect ratio does
  not match the portrait display.

Example:
  A small 600x400 image can now be enlarged to fit the portrait frame.
  A very large image is reduced to fit the same frame.
  In both cases the complete original photo remains visible.


V4.8 HIGH-QUALITY FIT
---------------------
The photo FIT behavior is unchanged, but small images are no longer enlarged
without limit.

New setting:
  "max_photo_upscale_factor": 2.0

Meaning:
  - Large photos are still reduced to fit the display.
  - Small photos may be enlarged, but by no more than 2x by default.
  - Aspect ratio remains preserved.
  - No foreground cropping.
  - A mild high-quality sharpening pass is applied only after enlargement.

Why:
  A very small source photo simply does not contain enough detail to look sharp
  when expanded to a 2K portrait display. Limiting the enlargement prevents the
  program from making that loss of quality much more obvious.

If desired, this value can later be changed:
  1.5 = more conservative / sharper small photos
  2.0 = current balance
  3.0 = fills more space but exposes more source-image softness


V4.9 20-MINUTE LOW-POWER SLEEP
------------------------------
The inactivity timeout is now:

  1200 seconds = 20 minutes

After 20 minutes with no qualified motion:
  - slideshow rendering pauses
  - the screen is blanked
  - HDMI/display output is powered off
  - Raspberry Pi remains running so the PIR can still be read
  - qualified PIR motion wakes the display and resumes the slideshow

NOTE:
  Raspberry Pi 3B+ does not provide an ESP32-style software deep-sleep mode
  that can shut the Pi almost completely down and then wake directly from this
  PIR GPIO in the current setup. This version uses the deepest reliable
  software sleep that still allows automatic PIR wake without extra hardware.


V5.0 QR UPLOAD OVERLAY
----------------------
The supplied "Subir Foto" QR graphic is now included in the slideshow.

Location:
  bottom-right corner

Default size:
  24% of the logical portrait-frame width

Default margin:
  30 pixels from the right and bottom edges

Default opacity:
  235 / 255

Config settings:
  "upload_overlay_enabled": true
  "upload_overlay_width_fraction": 0.24
  "upload_overlay_margin_px": 30
  "upload_overlay_opacity": 235

Original overlay dimensions:
  1584 x 2048

The overlay is rendered on top of each photo while preserving the existing
portrait rotation, FIT scaling, PIR sleep/wake, 20-minute timeout, Q/Esc exit,
and single-instance lock.


V5.1 QR BASE DIRECTORY FIX
--------------------------
Fixed startup error:
  NameError: BASE_DIR is not defined

The QR overlay path is now resolved directly from the folder containing
photo_frame.py:

  Path(__file__).resolve().parent / "upload_qr_overlay.png"

No other slideshow behavior was changed.


V5.2 QR HALF SIZE
-----------------
The QR upload overlay is now 50% smaller.

Old width:
  24% of the portrait frame width

New width:
  12% of the portrait frame width


V5.3 ARROW-KEY NAVIGATION
-------------------------
Slideshow navigation is standardized to:

  Right Arrow -> next media item
  Left Arrow  -> previous media item
  Q / Esc     -> quit

N and P are not used for navigation.

The arrow-key mapping is now centralized in photo_frame.py so the same
Left/Right controls can be connected to video playback when video work resumes.
No video-playback behavior was changed in this version.
