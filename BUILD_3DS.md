# Old 3DS native target

The native source is in `3ds_port/`. This is a hardware-compatible native runtime, separate from the original Godot desktop project; it is not a direct export of Godot Forward+.

## GitHub Actions (recommended)

See [`GITHUB-BUILD.md`](GITHUB-BUILD.md). The workflow is `.github/workflows/build-3ds.yml` at the repository root and builds with the official devkitPro ARM container. Download the `TheChoicerVoicer-Old3DS` artifact from the workflow run.

## Local build

Install the official devkitPro 3DS development tools, then run `make` in `3ds_port/`. On Windows, use `BUILD-3DS-WINDOWS.bat` from the project root.

Expected outputs in `3ds_port/`:

- `TheChoicerVoicer3DS.3dsx`
- `TheChoicerVoicer3DS.smdh`

User data is stored under `SD:/luma/3ds/The Choicer Voicer/`. The `.3dsx` homebrew executable itself should be placed in `SD:/3ds/`.
