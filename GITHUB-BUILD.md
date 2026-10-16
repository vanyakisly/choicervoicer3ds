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
