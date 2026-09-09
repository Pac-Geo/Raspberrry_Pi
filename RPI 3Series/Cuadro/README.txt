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


V5.4 PROGRESSIVE DRIVE SYNC
---------------------------
Google Drive downloading and slideshow playback now happen progressively.

Behavior with an empty PHOTOS folder:

  Photo 1 finishes downloading
      -> it is added to the slideshow within about 1 second
      -> slideshow starts immediately

  While Photo 1 is being displayed:
      -> Photo 2 continues downloading in the background

  Photo 2 finishes
      -> it is added to the live slideshow list

  While the slideshow continues:
      -> Photo 3, Photo 4, and the rest continue downloading

The frame DOES NOT wait for the complete Drive sync before showing photos.

Safety:
  Downloads still use DOWNLOAD.TMP.
  find_photos() ignores DOWNLOAD.TMP.
  A photo becomes visible to the slideshow only after the full file has
  downloaded and os.replace() has renamed it to its final filename.

Config:
  "progressive_media_scan_seconds": 1.0


V5.5 20-SECOND PLAYBACK + ROTATION KEYS
---------------------------------------
Slideshow timing:
  Each photo is displayed for 20 seconds.

Keyboard:
  Right Arrow -> next media item
  Left Arrow  -> previous media item
  Up Arrow    -> rotate current photo 90 degrees CLOCKWISE
  Down Arrow  -> rotate current photo 90 degrees COUNTERCLOCKWISE
  Q / Esc     -> quit

Photo rotation:
  - happens immediately
  - rotates in 90-degree steps
  - preserves the FIT behavior after rotation
  - is remembered for that photo for the current running session
  - resets when the photo-frame program is restarted

Video:
  Up/Down are now reserved as the same clockwise/counterclockwise controls for
  video media. The existing video playback code is not modified in this release;
  the key mapping is ready to be connected when video work resumes.


V5.6 FASTER CONTROLS + QR POSITION FIX
--------------------------------------
Responsiveness:
  - Normal event loop increased from 30 FPS to 60 FPS.
  - Empty/waiting screen polling increased from 5 FPS to 30 FPS.
  - Up to 6 rendered photo/orientation frames are cached in RAM.
  - Returning to a recently shown photo or a recently used rotation should
    therefore be nearly immediate.

Important:
  The first time a very large photo is decoded/rendered can still take some
  time on a Raspberry Pi 3B+, because the full image, blurred background, FIT
  scaling, and rotation must be generated. Repeated access uses the RAM cache.

QR overlay:
  - QR is no longer drawn onto the logical slideshow canvas before portrait
    rotation.
  - It is now drawn AFTER final display rotation.
  - This keeps it upright and anchored to the viewer's bottom-right corner,
    including after Up/Down photo rotation.

Controls remain:
  Right Arrow -> next
  Left Arrow  -> previous
  Up Arrow    -> rotate photo clockwise
  Down Arrow  -> rotate photo counterclockwise
  Q / Esc     -> quit


V5.7 QR SIZE + IMAGE-RELATIVE ROTATION
--------------------------------------
QR changes:
  - QR size is back to 12%.
  - QR is no longer anchored to the monitor.
  - It is composited onto the displayed photo itself.
  - It stays at the photo's bottom-right corner.
  - When Up/Down rotates the photo, the QR rotates with that photo.

This keeps the watermark visually attached to the image rather than the screen.
All V5.6 fast-key/caching behavior remains.


V5.8 QR MONITOR-CORNER + IMAGE-RELATIVE POSITION
------------------------------------------------
This combines the two QR behaviors:

  - QR is anchored to an actual corner of the monitor.
  - The chosen corner represents the photo's relative bottom-right.
  - QR rotates with the photo.
  - QR remains 12% of the monitor width.

Corner behavior:
  normal photo       -> monitor bottom-right
  clockwise 90 deg   -> monitor bottom-left
  180 deg             -> monitor top-left
  counterclockwise 90 -> monitor top-right

So the QR stays at a clean monitor corner while still behaving as though it is
attached to the bottom-right corner of the rotated image.


V5.9 QR SIZE 15%
----------------
QR placement remains monitor-corner anchored while following the photo's
relative bottom-right as the photo rotates.

QR size changed:
  12% -> 15% of the monitor width


V6.0 EXTENDED IMAGE FORMAT SUPPORT
----------------------------------
The frame now accepts a much broader set of still-image formats, including:

  JPEG / JPG / JFIF
  PNG
  HEIC / HEIF
  AVIF
  WebP
  GIF (first frame)
  TIFF / TIF
  BMP / DIB
  ICO
  PPM / PGM / PBM / PNM
  PCX
  TGA
  DDS
  EPS (when Pillow/system support is available)

Google Drive sync is also more tolerant:
  - known image MIME types are accepted
  - image/* MIME types are accepted when the filename extension is supported

QUALITY / ORIGINAL PRESERVATION
-------------------------------
The original photo file is preserved byte-for-byte on the USB drive.
The program does NOT convert or recompress the original HEIC/JPEG/etc. file.

For display only:
  - EXIF orientation is applied correctly
  - the image is decoded into RGB
  - LANCZOS is used for FIT resizing
  - aspect ratio is preserved
  - no foreground cropping
  - sharpening after enlargement is OFF by default to preserve the source look

New config:
  "max_photo_size_mb": 250
  "sharpen_upscaled_photos": false
  "accept_extended_image_formats": true

HEIC/HEIF support is provided by pillow-heif and libheif.


V6.1 HEIC + QR ROTATION CORRECTION
----------------------------------
QR:
  - size changed to 13%
  - QR and photo now receive the same manual rotation
  - QR is placed at the monitor corner corresponding to the photo's relative
    bottom-right
  - QR is composed before the frame's portrait-display rotation, so the QR and
    image cannot drift into different orientations

HEIC/HEIF:
  - explicit high-quality pillow-heif decoder path
  - EXIF orientation retained
  - originals remain untouched; decoding/resizing occurs only in memory
  - no recompression is written to the USB original
  - installer verifies pillow-heif after installation

IMPORTANT DRIVE LIMITATION:
  If Apps Script says it returned only 2 files, the Pi cannot discover 4 HEIC
  files that the server did not include. See APPS_SCRIPT_IMAGE_FILTER_PATCH.txt.


V6.2 QR ALIGNMENT FIX
---------------------
This release changes ONLY the QR behavior.

- QR size is 12%.
- QR is placed at the monitor-corner position corresponding to the photo's
  relative bottom-right.
- QR is rotated by the SAME manual rotation value as the photo.
- QR and photo are then passed through the SAME final portrait-display rotation
  together as one composed frame.

This fixes the previous version where present_frame() received the QR arguments
but never actually drew the overlay.


V6.3 ALL-IMAGE SUPPORT + CURRENT DEPLOYMENT
-------------------------------------------
This version leaves QR placement, QR size, rotation behavior, slideshow timing,
sleep/wake, and all other visual behavior from V6.2 unchanged.

Current Apps Script deployment embedded:
  https://script.google.com/macros/s/AKfycbySgtGdqgBXB2F6IpvvGTGY4itR5cDGmQOC0jrqwZ5SGknjqWNq2ZWIg0FMMi7ZvnOAUg/exec

The Pi now accepts supported images by filename extension even when Google Drive
reports a generic MIME type. It also accepts every image/* MIME returned by the
Apps Script.

HEIC/HEIF originals:
  - downloaded byte-for-byte
  - never converted or recompressed on disk
  - decoded only in RAM for display using pillow-heif/libheif

The terminal now prints every Drive item returned, including filename, MIME type,
size, total image count, and HEIC/HEIF count.


V6.4 DOWNLOAD-STAGE FIX
-----------------------
The Apps Script can now list HEIC/HEIF correctly, but the previous chunk
transport still depended on Google Drive HTTP Range responses. Some binary
formats can list correctly and then fail during chunk download.

The accompanying Apps Script fixes that by:
  - reading the original Drive file bytes directly
  - slicing the requested chunk in Apps Script
  - returning the exact original bytes without conversion/recompression
  - using 1 MiB chunks to match the Pi

QR size, QR rotation, slideshow rendering, photo FIT behavior, and all other
visual behavior are unchanged from the working V6.2/V6.3 lineage.


V6.5 UNIVERSAL PHOTO + QR ROTATION
----------------------------------
Up/Down now rotate the entire slideshow content universally, not one photo at a time.
The same rotation applies to every existing and newly downloaded image and to the QR.
The setting is saved as "universal_media_rotation_degrees" and survives restart.
"display_rotation_degrees": 270 remains the separate physical wall-mount rotation.
All other V6.4 behavior is unchanged.


V6.6 SINGLE ROTATION SYSTEM
---------------------------
Rotation has been simplified to ONE setting only:

  "display_rotation_degrees"

There is no separate per-image rotation and no separate universal-media
rotation anymore.

Up / Down:
  - rotate the ENTIRE completed frame
  - every photo rotates the same way
  - HEIC/JPEG/PNG/etc. all use the same orientation
  - blurred background rotates with the photo
  - QR rotates with the photo
  - the setting is saved and survives restart
  - newly downloaded photos automatically use the same setting

HEIC ORIENTATION FIX:
HEIC/HEIF/AVIF now use the same Pillow Image.open() path as JPEG/PNG/etc.
The image is then normalized once with ImageOps.exif_transpose(). This avoids
giving HEIC a different orientation pipeline from the older JPEG files.

The original photo files are never rewritten, converted, or recompressed.

All other slideshow behavior is left unchanged.


V6.7 RELIABILITY / INDEX / REAL SLEEP
-------------------------------------
Visual behavior, 12% QR placement, single global rotation, FIT rendering,
HEIC handling, slideshow timing, and Drive bridge settings are left intact.

Added:
1. STARTUP HEALTH CHECK
   Reports USB, Drive reachability, HEIC decoder, PIR, QR file, readable media
   count, index path, free storage, and available display-power backend.

2. CORRUPT / UNREADABLE IMAGE HANDLING
   A bad still image is logged by filename, marked unreadable in the index,
   removed from the active slideshow, and skipped without stopping playback.
   Replacing the file or pressing R for a full rescan gives it a fresh chance.

3. DUPLICATE DETECTION
   New Drive images are SHA-256 hashed. If a differently named file is
   byte-for-byte identical to an existing image, the duplicate is not stored.
   The Drive file ID is remembered so it is not repeatedly downloaded later.

4. REAL 20-MINUTE DISPLAY SLEEP
   After 1200 seconds of inactivity the frame blanks first, then requests real
   display/HDMI power-off using the best available backend: wlopm, vcgencmd,
   xset DPMS, or wlr-randr. PIR/keyboard/mouse powers the display back on and
   redraws the current slide. If no backend works, black-screen fallback remains.

5. STORAGE PROTECTION
   Keeps a 2048 MiB reserve on CUADRO. A sync stops cleanly before a download
   would consume that reserve.

6. PERSISTENT PHOTO INDEX
   Stored at:
     CUADRO/.photo_frame_cache/photo_index.json
   Tracks filename, relative path, size, modified date, type, SHA-256 hash,
   readability/error state, and Drive-file handling metadata.
   The slideshow reads this index instead of recursively walking the entire
   PHOTOS tree every second. A full scan runs hourly and when R is pressed.
   Missing SHA-256 values are filled in by a background hashing worker.
