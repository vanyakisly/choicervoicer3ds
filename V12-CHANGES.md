# v12 — blank-screen and SD path fix

## What was fixed

- Corrected native framebuffer dimension checks. libctru reports physical framebuffer dimensions (240x400 top, 240x320 bottom), while the UI canvases are logical dimensions (400x240 top, 320x240 bottom). The previous check rejected both valid framebuffers, so no pixels were displayed.
- Corrected sideways BGR8 framebuffer mapping to use `fw` (the 240-pixel framebuffer stride), not `fh`. This prevents writing past the framebuffer allocation.
- Changed all native runtime data lookup and creation from `SD:/luma/3ds/The Choicer Voicer/` to `SD:/3ds/The Choicer Voicer/`.
- Updated asset staging and the GitHub SD-install bundle so runtime assets, packs, audio, saves and recordings use the same `/3ds/The Choicer Voicer/` path.
- Added a host-side framebuffer regression test to GitHub Actions. It checks rotated and direct layouts and checks that the rotated case does not write beyond its framebuffer.

## Install

Replace the existing repository contents with this source and commit/push. Run **Actions → Build The Choicer Voicer for Old 3DS**. Extract `TheChoicerVoicer-Old3DS-SD-Install.zip` to the SD card root. It creates `/3ds/TheChoicerVoicer3DS.3dsx` and `/3ds/The Choicer Voicer/`.

Host-side framebuffer, pack-loader and video/audio preprocessing tests pass. This environment has not tested the resulting build on a physical Old 3DS.
