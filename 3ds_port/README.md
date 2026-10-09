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
- Native Old 3DS microphone capture through the 3DS MIC service.
- Native PCM WAV recording and playback through NDSP.
- Native persistent data and recording storage.

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

The original Godot source remains intact in the parent directory.

## Build

Use the current devkitPro/devkitARM + libctru environment and run:

`make`

Output:

`TheChoicerVoicer3DS.3dsx`

The Makefile follows the current devkitPro 3DS toolchain architecture (`armv6k`, `3dsx.specs`, libctru).

## Automatic GitHub build

A GitHub Actions workflow is included at `.github/workflows/build-3ds.yml` in the project root. It uses the official `devkitpro/devkitarm` container to build the native target and uploads the `.3dsx` and `.smdh` files as an Actions artifact.

## Windows build

For a normal Windows PC, from the project root double-click:

`build_windows.bat`

This detects the standard `C:\devkitPro` installation, uses its bundled MSYS2 Bash shell, sets `DEVKITPRO` / `DEVKITARM`, and runs the 3DS Makefile. See `BUILD-WINDOWS.md` for setup details.
