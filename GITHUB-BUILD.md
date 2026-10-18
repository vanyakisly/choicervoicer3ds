# Build The Choicer Voicer for Old 3DS on GitHub

This repository includes a GitHub Actions workflow at `.github/workflows/build-3ds.yml`.
It uses the official `devkitpro/devkitarm` container so you do not need to install devkitPro on your own computer to produce the build.

## Set up the repository

1. Extract this ZIP into a folder.
2. Create a GitHub repository.
3. Upload/commit the **contents** of the extracted folder to the repository root. The `.github` folder must be at the repository root, alongside `project.godot` and `3ds_port/`—do not upload the outer folder as a nested directory.
4. Push/commit the files. The workflow starts automatically after a push. You can also open **Actions → Build The Choicer Voicer for Old 3DS → Run workflow**.
5. Open the finished workflow run and download the `TheChoicerVoicer-Old3DS` artifact. It includes the raw executable plus `TheChoicerVoicer-Old3DS-SD-Install.zip` with the app and required data/assets.

For this source size, GitHub Desktop or Git is more reliable than the browser's multi-file uploader. Make sure hidden files/folders are included so `.github/workflows/build-3ds.yml` is uploaded.

## Install the artifact

For the easiest install, extract `TheChoicerVoicer-Old3DS-SD-Install.zip` directly to the SD card root. It contains only `/3ds/TheChoicerVoicer3DS.3dsx`, the SMDH and an install note. The native sprites/fonts, optimized runtime music and sounds, default packs and converted dub videos are embedded inside the `.3dsx` RomFS; no assets directory is required on the SD card. Saves/recordings are auto-created under `/3ds/TheChoicerVoicer3DS_User/` on first launch. You do not need to put anything in `/3ds/The Choicer Voicer/`.

The workflow fails visibly if the native source/Makefile, required UI sprite/font outputs, audio tracks, starter packs, or compiled outputs are missing. It verifies the `.3dsx` header before publishing the artifact. The actual ARM cross-compilation happens in GitHub Actions; it has not been tested on a physical Old 3DS by this source-editing environment.


### zlib / package-server resilience (v13)

The native port uses zlib for the compressed video-frame format. The workflow avoids refreshing devkitPro package databases during each build (which can fail when pkg.devkitpro.org responds with HTTP 403). It locates the zlib portlib already present in the official image, and if missing, compiles pinned upstream zlib v1.3.1 from the checked-out GitHub source. It then checks the zlib header and `uncompress` symbol before building.


### v17 recording and playback feedback

The bottom screen includes a live sample-derived microphone waveform and a dedicated recording status strip. It explicitly reports when recording stops and whether the take was saved. Dub Cinema renders the actual selected dub video while Watch Dub is active and overlays saved takes at their timestamps. All default assets/packs remain embedded in the `.3dsx`; the SD card still only needs the app files under `/3ds/`, and the old `The Choicer Voicer` folder is not required or modified.


### v18 — Dub pack selection crash fix

The native pack scanner uses static bounded scratch buffers instead of large stack-local arrays, and iterative DFS for pack and clip discovery instead of recursive calls. GitHub Actions exercises user/legacy/embedded roots under a 64 KiB host stack limit on Linux and checks stack-frame reports before the ARM build.


## v19 microphone and dubbing controls

The MIC buffer is allocated with `memalign(0x1000, ...)`, as required by libctru's shared-memory API. `Repeat Line` replays the current source cue/video segment. `Watch Dub` is visibly locked until each timestamped clip has a saved recording, and the start function enforces the same check. Host-side regression tests check the alignment, failure diagnostics, button mapping and all-lines gating.

No manual assets are required in `SD:/3ds/The Choicer Voicer/`: defaults remain embedded in RomFS and writable recordings/settings are automatically created under `SD:/3ds/TheChoicerVoicer3DS_User/`.

## v20 — Avoid false "needs video conversion" on duplicate packs

The pack browser merges matching names across writable user packs, the legacy `SD:/3ds/The Choicer Voicer/packs_voice/` fallback, and embedded RomFS packs. It normalizes spaces, underscores, hyphens, and capitalization when comparing names and chooses the most-ready duplicate, so any raw legacy copy cannot hide a converted embedded pack. User custom packs with the same name still take precedence when they are equally ready.

GitHub Actions no longer requires a specific example pack. It processes every eligible dub-pack directory under repository-root `packs_voice/`, including nested collections, and validates every generated `dub_video.tcv` before compiling. Add any new pack under `packs_voice/<Pack Name>/` (or a nested collection folder) and rebuild. The converter is a build-time FFmpeg tool; the 3DS runtime does not decode the source containers or run FFmpeg itself.


## v21 — broader dub pack compatibility

The build-time converter now accepts common source video containers instead of only `dub_video.ogv`, normalizes voice audio from WAV/MP3/OGG/FLAC/M4A/AAC/Opus/WMA/AIFF and other FFmpeg-readable audio formats, and converts PNG/JPEG/WebP/BMP/TIFF/GIF artwork to native TCVR sprites. Pack videos are detected from common names (`dub_video.*`, `video.*`, `movie.*`, etc.), explicit `video_file` in `_pack_info.ini`, or a single video inside a timestamped pack. JSON/YAML sidecars and common metadata aliases are normalized to the keys the native runtime understands. GitHub Actions runs tests against non-OGV and nested source videos and reports the precise folder if a timed dub has no usable video.

For custom packs, commit the pack folder under repository-root `packs_voice/` and rebuild. Runtime on the Old 3DS only decodes the generated TCV/PCM/T CVR formats; FFmpeg is run during the GitHub build, not on the console. Correct line synchronization still requires timestamps in the sidecars or filename conventions; the build reports missing timing/video instead of silently guessing. No files need to be added to `SD:/3ds/The Choicer Voicer/`.


## v22 — Pack-agnostic build and validation

There are no required paths, titles, characters, or clip counts for a particular sample pack. Every eligible dub pack under repository-root `packs_voice/` (including packs nested under collection folders) is merged into the runtime staging tree and processed independently. The converter accepts common FFmpeg-readable video/audio formats, normalizes metadata to the fields the native player understands, creates `dub_video.tcv` plus native audio/artwork companions, and reports the exact directory when an eligible pack cannot be converted. The workflow validates every generated TCV header rather than checking a fixed sample path. Add all desired pack folders to repository-root `packs_voice/` before running GitHub Actions; rebuild after adding/changing packs. The on-device runtime cannot run FFmpeg and cannot automatically convert arbitrary source media added after the build.

## v23 — Startup and browsing load-time optimization

The native app now loads only the fonts and a few first-screen images at launch. Other UI art is lazy-loaded on its first use, with a per-asset attempted-load flag so missing images do not trigger repeated file opens. Pack category lists are cached for the app session, and the dub-pack list is scanned once then reused when reopening the selector. During the GitHub build, `prepare_3ds_assets.py` generates `packs_voice/.tcv_pack_index.tsv` after all packs are converted. The index lists each embedded pack's relative folder and dialogue-event count, letting the 3DS discover immutable RomFS packs without recursively walking every media directory at runtime. The workflow validates the catalog against all generated TCV videos; an empty catalog is valid when no embedded dub packs are supplied.

This does not require any migration or replacement of `SD:/3ds/The Choicer Voicer/`. Built-in data remains inside the `.3dsx`; saves, settings and takes continue under `SD:/3ds/TheChoicerVoicer3DS_User/`. Existing user/legacy pack roots remain optional fallbacks, and the old path is never written to. Expected benefit is shorter cold startup and much faster repeated visits to pack selection; absolute timings and sustained 30 FPS still require measurement on a physical Old 3DS.

## Export the completed dub as a full MP4

The Old 3DS saves your line recordings and timestamps, but should not encode the full video in real time. On Windows, run `EXPORT-DUB-VIDEO-WINDOWS.bat`, select the saved `session.ini` from the SD card, choose the original source pack folder from `packs_voice/`, and select an output MP4 path. Read `EXPORT-FULL-DUB.md` for details.


## v25 runtime staging fix

Default WAV music and SFX are preserved by the pruning pass unless a distinct `.3ds.wav` companion exists. The GitHub Actions staging step prints the exact failed command and line for easier diagnosis.
