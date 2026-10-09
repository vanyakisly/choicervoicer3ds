# Old 3DS native target

The native source is in `3ds_port/`. This is a hardware-compatible native runtime, separate from the original Godot desktop project; it is not a direct export of Godot Forward+.

## GitHub Actions (recommended)

See [`GITHUB-BUILD.md`](GITHUB-BUILD.md). The workflow is `.github/workflows/build-3ds.yml` at the repository root and builds with the official devkitPro ARM container. Download the `TheChoicerVoicer-Old3DS` artifact from the workflow run; it includes both the raw `.3dsx` and `TheChoicerVoicer-Old3DS-SD-Install.zip`, which bundles generated runtime sprites/fonts, original artwork/assets/models, all original audio and converted PCM companions, and all default pack categories.

## Local build

Install the official devkitPro 3DS development tools, then run `make` in `3ds_port/`. On Windows, use `BUILD-3DS-WINDOWS.bat` from the project root.

Expected outputs in `3ds_port/`:

- `TheChoicerVoicer3DS.3dsx`
- `TheChoicerVoicer3DS.smdh`

User data is stored under `SD:/luma/3ds/The Choicer Voicer/`. The `.3dsx` homebrew executable itself should be placed in `SD:/3ds/`.


## Voice and dub pack compatibility

The native runtime reads voice packs from `packs_voice/<Pack Name>/`. Supported input audio is WAV, MP3 and OGG; the build preparation step preserves those source files and creates `.3ds.wav` companions normalized to PCM16/22.05 kHz (mono for lines, stereo for `_backing_track`). Clip metadata in matching `.ini`, `.cfg`, or `.txt` files supplies captions, character names, optional artwork, `dub_only`, and absolute `dub_timestamps`. Timestamp suffixes such as `_44-048` are also recognized.

For Dub Mode, each pack needs the original `dub_video.ogv` plus per-line timestamps. The build creates `dub_video.tcv`, a 160×90 RGB565 stream at 10 fps, with periodic keyframes and zlib-compressed frame deltas. The OGV is retained unchanged. Clip images (PNG/JPG/JPEG/WebP/BMP) receive bounded `.tcvr` companions. Dub recordings are saved under `recordings/dub_recordings/<Pack Name>/3DS Session/` and replayed against their line timestamps.

To convert a pack locally before copying it to the SD card, install Python 3, Pillow and FFmpeg, then run `python tools/prepare_3ds_dub_packs.py --tree packs_voice`. The GitHub workflow runs a synthetic video/audio/image test and a host-side regression test of the actual C metadata scanner before attempting the devkitARM build.

This is a hardware-adapted native port, not an execution of Godot scenes on the 3DS. It targets the original pack structures, but the completed ARM build and physical-device behavior still need validation from the GitHub Actions build and on an Old 3DS.
