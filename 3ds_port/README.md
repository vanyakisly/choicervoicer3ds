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
- In gameplay and Dub Mode the bottom screen specifically contains:
  - `START`
  - `NEXT`
  - `WATCH DUB`
  - `SAVE DUB`
  - an animated audio waveform area.
- Native Old 3DS microphone capture through the 3DS MIC service, using a 0x1000-aligned shared-memory allocation and an eight-second recording cap.
- Native PCM WAV recording and playback through NDSP, with graceful fallback if audio initialization fails.
- Bounded WAV parsing (4 MiB audio-data cap) to avoid excessive memory allocation on Old 3DS.
- Save-value validation, checked file writes, and clearer SD/microphone error messages.
- Native persistent data and recording storage.
- Original Waukegan LDO font rendered into compact native glyph atlases.
- Original logo, Shae/host art, player/judge art, tutorial thumbnails, game examples, help slides, credits portraits, and waveform/microphone artwork.
- Original menu hover/back/select/decrease sounds, judge score blips, tutorial-pack clips, and the project's music tracks.
- During microphone recording, a low-cost live level trace overlays the supplied waveform art.

## Requested data location

`sdmc:/luma/3ds/The Choicer Voicer/`

The runtime creates:

- `packs_host/`
- `packs_judges/`
- `packs_menu/`
- `packs_studio/`
- `packs_voice/`
- `packs_player/`
- `saves/`
- `recordings/`

Save data is `saves/save.json`; recorded dubs are stored as PCM WAV files under `recordings/`.

## Controls

### Touch
Tap the visible bottom-screen button.

### Buttons
- D-pad: move selection
- A: activate
- B: back
- START: exit to Homebrew Menu

## Important compatibility note

The original project is a Godot 4.4 Forward+ desktop project. This native target intentionally does not try to run Godot's desktop renderer. The 3DS implementation supplies native equivalents for the UI/state/storage/audio-recording portions. Desktop-only features such as the Forward+ 3D renderer, Twitch/WebSocket services, and some desktop media codecs still require separate native implementations.

The original Godot source remains intact in the parent directory. This is a native, source-asset-based recreation of the main UI and a partial gameplay/audio/storage conversion, not a direct execution of Godot scenes. Some desktop-only systems remain unavailable in this conversion, including Twitch/WebSocket features and full desktop video playback. The Github Actions cross-build and physical Old 3DS test are still required before it can be considered fully verified.

## Build

Use the current devkitPro/devkitARM + libctru environment and run:

`make`

Output:

`TheChoicerVoicer3DS.3dsx`

The Makefile follows the current devkitPro 3DS toolchain architecture (`armv6k`, `3dsx.specs`, libctru). It treats implicit-function declarations and missing returns as build errors. libctru's startup code initializes HID/FS and mounts `sdmc:`; the native entry point does not initialize or unmount those services a second time.

## Automatic GitHub build

A GitHub Actions workflow is included at `.github/workflows/build-3ds.yml` in the project root. It uses the official `devkitpro/devkitarm` container to build the native target, converts MP3/OGG audio to PCM WAV companions, creates the SD data directory containing the original graphic/assets/model trees, original audio and default packs, and uploads `TheChoicerVoicer-Old3DS-SD-Install.zip` alongside the raw `.3dsx` and `.smdh` files. Extract the install ZIP directly to the SD card root so it creates `/3ds/` and `/luma/3ds/The Choicer Voicer/`.

## Windows build

For a normal Windows PC, from the project root double-click:

`build_windows.bat`

This detects the standard `C:\devkitPro` installation, uses its bundled MSYS2 Bash shell, sets `DEVKITPRO` / `DEVKITARM`, and runs the 3DS Makefile. See `BUILD-WINDOWS.md` for setup details.
