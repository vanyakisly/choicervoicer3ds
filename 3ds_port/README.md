# The Choicer Voicer — Old 3DS native port

This folder is the hardware-adapted native target placed alongside the original Godot project.

## What this revision adds

- Full native UI flow for the major game screens:
  - Home
  - Play / game mode
  - Player count
  - Match setup
  - Standard gameshow round
  - Results
  - Dub mode
  - Pack browser
  - Settings
  - Data management
  - Extras
  - Guide
  - Credits
- Dual-screen layout: information/game presentation on the top screen and interactive controls on the bottom screen.
- **Stylus/touch activation for every native UI button.**
- Dub Mode opens a dedicated, alphabetized list of packs discovered recursively under `SD:/3ds/The Choicer Voicer/packs_voice/`. It finds the directory containing `dub_video.tcv`/`dub_video.ogv`, filters out ordinary voice-only packs, prioritizes converted/timestamp-ready packs, and opens the exact selected nested path.
- In gameplay and Dub Mode the bottom screen specifically contains:
  - `START + RECORD` / `STOP & SAVE` for the current line
  - `NEXT` to move to the next timestamped clip
  - `WATCH DUB` to play the compressed video with the player's recorded takes overlaid at their original timestamps
  - `SAVE DUB` to write the takes and `session.ini` timeline manifest
  - an actual signed PCM microphone waveform while recording, followed by the latest recorded waveform for review.
- Native Old 3DS microphone capture through the 3DS MIC service, using a 0x1000-aligned shared-memory allocation and an eight-second recording cap.
- Native PCM WAV recording and playback through NDSP, with graceful fallback if audio initialization fails.
- Bounded WAV parsing (4 MiB audio-data cap) to avoid excessive memory allocation on Old 3DS.
- Save-value validation, checked file writes, and clearer SD/microphone error messages.
- Native persistent data and recording storage.
- Original Waukegan LDO font rendered into compact native glyph atlases.
- Original logo, Shae/host art, player/judge art, tutorial thumbnails, game examples, help slides, credits portraits, and waveform/microphone artwork.
- Original menu hover/back/select/decrease sounds, judge score blips, tutorial-pack clips, and the project's music tracks.
- UI rendering is capped at every other 60 Hz VBlank (30 FPS maximum); the 160x90 video frame blit uses a 2x fast path that converts each RGB565 source pixel once. The source remains 10 FPS video for lower decoder load.
- The Watch Dub player overlays saved voice takes only. Unrecorded lines are silent rather than quietly playing the original cue audio, so it is clear which lines have actually been dubbed.

## Requested data location

`sdmc:/3ds/The Choicer Voicer/`

The runtime creates:

- `packs_host/`
- `packs_judges/`
- `packs_menu/`
- `packs_studio/`
- `packs_voice/`
- `packs_player/`
- `saves/`
- `recordings/`

Save data is `saves/save.json`; recorded lines are stored as PCM WAV files under `recordings/dub_recordings/<Pack Name>/3DS Session/`. `session.ini` lists source clips, timestamps, take filenames, and which lines have a recording. The separate `recordings/dub_latest.wav` is used by non-pack single-take mode.

## Controls

### Choosing a dub pack

1. Choose `PLAY` → `DUB MODE` (or `DUB CINEMA` → `START DUB MODE`).
2. The app searches `packs_voice/` and displays folders that contain `dub_video.tcv` or `dub_video.ogv`. Tap a row to select it, then tap `USE`.
3. A pack can start only when it has a converted `dub_video.tcv` and line metadata containing `dub_timestamps`. Packs with only the original `.ogv` need to be included in the source repository and run through GitHub Actions to generate the `.tcv` companion.

### Recording and reviewing

1. On the bottom screen, press `START + RECORD`. The movie seeks to the selected line timestamp, plays the source line as a cue, and starts the microphone and video.
2. Press `STOP & SAVE` or `NEXT`; stopping saves that line automatically. Press `NEXT` to move through the lines.
3. Press `WATCH DUB` to replay the scene with your takes overlaid on the same timestamp timeline. It warns when there are no takes yet; it doesn't substitute the pack's original dialogue for your recording.
4. Press `SAVE DUB` to flush the session manifest and per-line WAV takes to SD. This is a saved dubbing session (separate take WAVs + timestamps), not a newly muxed MP4/OGV video file; the Old 3DS build does not currently render/export a final video file.

### Touch
Tap the visible bottom-screen button.

### Buttons
- D-pad: move selection
- A: activate
- B: back
- START: exit to Homebrew Menu

## Important compatibility note

The original project is a Godot 4.4 Forward+ desktop project. This native target intentionally does not try to run Godot's desktop renderer. The 3DS implementation supplies native equivalents for the UI/state/storage/audio-recording portions. Desktop-only features such as the Forward+ 3D renderer, Twitch/WebSocket services, and some desktop media codecs still require separate native implementations.

The original Godot source remains intact in the parent directory. This is a native, source-asset-based recreation of the main UI and a partial gameplay/audio/storage conversion, not a direct execution of Godot scenes. Some desktop-only systems remain unavailable in this conversion, including Twitch/WebSocket features and full desktop video playback. The render cadence is capped at 30 FPS, but a stable sustained 30 FPS is not guaranteed until measured on the actual Old 3DS. The GitHub Actions cross-build and physical console test are still required before it can be considered fully verified.

## Build

Use the current devkitPro/devkitARM + libctru environment and run:

`make`

Output:

`TheChoicerVoicer3DS.3dsx`

The Makefile follows the current devkitPro 3DS toolchain architecture (`armv6k`, `3dsx.specs`, libctru). It treats implicit-function declarations and missing returns as build errors. libctru's startup code initializes HID/FS and mounts `sdmc:`; the native entry point does not initialize or unmount those services a second time.

## Automatic GitHub build

A GitHub Actions workflow is included at `.github/workflows/build-3ds.yml` in the project root. It uses the official `devkitpro/devkitarm` container to build the native target, converts MP3/OGG audio to PCM WAV companions, creates the SD data directory containing the original graphic/assets/model trees, original audio and default packs, and uploads `TheChoicerVoicer-Old3DS-SD-Install.zip` alongside the raw `.3dsx` and `.smdh` files. Extract the install ZIP directly to the SD card root so it creates `/3ds/` and `/3ds/The Choicer Voicer/`.

## Windows build

For a normal Windows PC, from the project root double-click:

`build_windows.bat`

This detects the standard `C:\devkitPro` installation, uses its bundled MSYS2 Bash shell, sets `DEVKITPRO` / `DEVKITARM`, and runs the 3DS Makefile. See `BUILD-WINDOWS.md` for setup details.


Build dependency note: GitHub Actions deliberately avoids refreshing devkitPro package databases during each run. It uses the zlib portlib already in the official image, with a fallback that builds pinned upstream zlib v1.3.1 source if the installed portlib is absent. Local builds must provide a matching ARM zlib header and static library.
