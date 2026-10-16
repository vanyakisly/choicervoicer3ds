# Old 3DS native target

The native source is in `3ds_port/`. This is a hardware-compatible native runtime, separate from the original Godot desktop project; it is not a direct export of Godot Forward+.

## GitHub Actions (recommended)

See [`GITHUB-BUILD.md`](GITHUB-BUILD.md). The workflow is `.github/workflows/build-3ds.yml` at the repository root and builds with the official devkitPro ARM container. Download the `TheChoicerVoicer-Old3DS` artifact from the workflow run; it includes both the raw `.3dsx` and `TheChoicerVoicer-Old3DS-SD-Install.zip`, which bundles generated runtime sprites/fonts, original artwork/assets/models, all original audio and converted PCM companions, and all default pack categories.

## Local build

Install the official devkitPro 3DS development tools, FFmpeg, Python 3, and Pillow. From the repository root prepare the embedded assets with `python3 tools/prepare_3ds_assets.py --source . --output 3ds_port/romfs/tcv`, then run `make` in `3ds_port/`. On Windows, `BUILD-3DS-WINDOWS.bat` checks for FFmpeg/Pillow and prepares the assets automatically if needed.

Expected outputs in `3ds_port/`:

- `TheChoicerVoicer3DS.3dsx`
- `TheChoicerVoicer3DS.smdh`

Stock artwork, audio and bundled packs are embedded in the `.3dsx` using RomFS. Writable saves and recordings are created automatically under `SD:/3ds/TheChoicerVoicer3DS_User/`. You do not need to copy or replace `SD:/3ds/The Choicer Voicer/`. Place only the `.3dsx` and `.smdh` in `SD:/3ds/`. Optional preconverted custom packs belong in `SD:/3ds/TheChoicerVoicer3DS_User/packs_voice/`.


## Voice and dub pack compatibility

The native runtime recursively searches `packs_voice/` for pack directories containing `dub_video.ogv` or `dub_video.tcv`, so `packs_voice/<Pack Name>/` and `packs_voice/<Collection>/<Pack Name>/` both work. Supported input audio is WAV, MP3 and OGG; the build preparation step preserves those source files and creates `.3ds.wav` companions as mono PCM16 (normally 22.05 kHz for short lines; large tracks are reduced to 16 kHz so shipped WAVs stay within the native 4-MiB playback cap). Clip metadata in matching `.ini`, `.cfg`, or `.txt` files supplies captions, character names, optional artwork, `dub_only`, and absolute `dub_timestamps`. Timestamp suffixes such as `_44-048` are also recognized.

For Dub Mode, each pack needs the original `dub_video.ogv` plus per-line timestamps. The build creates `dub_video.tcv`, a 160×90 RGB565 stream at 10 fps, with periodic keyframes and zlib-compressed frame deltas. The OGV is retained unchanged. Clip images (PNG/JPG/JPEG/WebP/BMP) receive bounded `.tcvr` companions. Dub recordings are saved under `recordings/dub_recordings/<Pack Name>/3DS Session/` and replayed against their line timestamps.

On v17, the lower screen draws a live, scrolling waveform from actual completed microphone PCM samples. When recording stops (manually or by reaching the limit), the status strip reports whether the take was saved or why it failed. Watch Dub displays the actual selected TCV movie in Dub Cinema as well as in Dub Mode, and schedules saved line recordings against the video timestamps. The current line's recorded/unrecorded indicator is cached to avoid repeated SD-card file checks every frame.

To convert a pack locally before copying it to the SD card, install Python 3, Pillow and FFmpeg, then run `python tools/prepare_3ds_dub_packs.py --tree packs_voice`. The GitHub workflow runs a synthetic video/audio/image test and a host-side regression test of the actual C metadata scanner before attempting the devkitARM build.

This is a hardware-adapted native port, not an execution of Godot scenes on the 3DS. It targets the original pack structures, but the completed ARM build and physical-device behavior still need validation from the GitHub Actions build and on an Old 3DS.
