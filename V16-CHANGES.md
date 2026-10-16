# v16 — Embedded assets and runtime optimization

## No external assets folder required

The GitHub build prepares compact runtime assets and embeds them into `TheChoicerVoicer3DS.3dsx` as RomFS. On the SD card, place only the `.3dsx` and `.smdh` in `SD:/3ds/`. The application creates `SD:/3ds/TheChoicerVoicer3DS_User/` for writable saves and recordings. It does not require, replace, create, or write into `SD:/3ds/The Choicer Voicer/`; that old path is an optional read-only compatibility fallback for existing packs/save migration.

## Runtime and asset optimizations

- Converts large WAVs over 1 MiB to mono PCM16 at 16 kHz so music/backing tracks fit the native 4-MiB playback cap; the staging run saved about 57 MB by downsampling six large WAVs; source-duplicate pruning removed another 24.5 MB.
- Converts compressed MP3/OGG companions directly to mono where they will be played by the native runtime; backing tracks are mono too. Short lines keep 22.05 kHz; large tracks use 16 kHz.
- Keeps 160×90 RGB565/10-FPS TCV video with zlib level 6. Level 9 was slower and added little benefit on the sample clip, so level 6 is the better build-time trade-off.
- Uses cached ARGB colors for video blitting, a fast 2× pixel path, and skips redraw on static screens. Rendering is capped at 30 FPS maximum; stable 30 FPS still needs physical Old 3DS testing.
- Avoids redundant FFmpeg normalization passes. Converters produce compliant PCM companions directly; only large noncompliant WAVs receive a further conversion.
- `.godot/`, build outputs and generated `3ds_port/romfs/` are ignored. GitHub Actions builds RomFS from the committed source; the Windows helper prepares it automatically if absent.

## Validation

Host-side pack scanning, Save Dub/session manifest writing, video conversion, waveform/workflow static checks, framebuffer mapping and cached video blitting pass. A synthetic large stereo WAV optimization test confirms mono PCM16/16-kHz output and size reduction. The full native ARM cross-build and physical-console frame-rate test have not been performed in this environment.
