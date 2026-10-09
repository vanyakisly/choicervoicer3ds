# Build The Choicer Voicer for Old 3DS on GitHub

This repository includes a GitHub Actions workflow at `.github/workflows/build-3ds.yml`.
It uses the official `devkitpro/devkitarm` container so you do not need to install devkitPro on your own computer to produce the build.

## Set up the repository

1. Extract this ZIP into a folder.
2. Create a GitHub repository.
3. Upload/commit the **contents** of the extracted folder to the repository root. The `.github` folder must be at the repository root, alongside `project.godot` and `3ds_port/`—do not upload the outer folder as a nested directory.
4. Push/commit the files. The workflow starts automatically after a push. You can also open **Actions → Build The Choicer Voicer for Old 3DS → Run workflow**.
5. Open the finished workflow run and download the `TheChoicerVoicer-Old3DS` artifact.

For this source size, GitHub Desktop or Git is more reliable than the browser's multi-file uploader. Make sure hidden files/folders are included so `.github/workflows/build-3ds.yml` is uploaded.

## Install the artifact

Extract the downloaded artifact ZIP. Copy `TheChoicerVoicer3DS.3dsx` (and optionally its `.smdh` icon file) into `SD:/3ds/` for Homebrew Launcher. The runtime's user data directory remains `SD:/luma/3ds/The Choicer Voicer/` as requested by the project.

The workflow fails visibly if the 3DS source/Makefile is missing, if compilation fails, or if either expected output is absent. A successful job verifies both output files before publishing the artifact.
