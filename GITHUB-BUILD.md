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

For the easiest install, extract `TheChoicerVoicer-Old3DS-SD-Install.zip` directly to the root of the 3DS SD card, preserving the folders. It contains `/3ds/TheChoicerVoicer3DS.3dsx`, the SMDH, and `/luma/3ds/The Choicer Voicer/` with generated native sprites/fonts, the original graphic/assets/model trees, all original music/SFX, PCM WAV companions for MP3/OGG files, and the seven default pack categories. The raw `.3dsx` and `.smdh` are also available separately in the Actions artifact.

The workflow fails visibly if the native source/Makefile, required UI sprite/font outputs, audio tracks, starter packs, or compiled outputs are missing. It verifies the `.3dsx` header before publishing the artifact. The actual ARM cross-compilation happens in GitHub Actions; it has not been tested on a physical Old 3DS by this source-editing environment.
