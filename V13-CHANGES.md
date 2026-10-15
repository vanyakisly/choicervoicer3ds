# The Choicer Voicer — Old 3DS Port v13

## GitHub Actions build reliability

- Removed the `dkp-pacman -Sy` / `pacman -Sy` step that was failing when `pkg.devkitpro.org` returned HTTP 403.
- The workflow now uses zlib already installed in the official `devkitpro/devkitarm` image when available.
- Added a fallback checkout of upstream zlib v1.3.1 from GitHub. If the image is missing the 3DS zlib header or static archive, the build script compiles and installs the pinned source into the container's devkitPro 3DS portlibs directory without using pacman.
- Added a zlib header/symbol preflight and an explicit error message if the toolchain or fallback dependencies are missing.
- The selected zlib include and library paths are passed directly into the recursive native Makefile.
- Added workflow checks for the build script's shell syntax and a guard against reintroducing the package database refresh.

## Validation performed in this environment

- GitHub Actions YAML parsed successfully.
- Container build script passed `sh -n` syntax validation.
- Video/audio preprocessing regression test passed.
- Native C pack loader regression test passed.
- Framebuffer layout/stride regression test passed.

The actual devkitARM cross-compilation still needs to run on GitHub Actions; this environment does not include the official devkitARM Docker image/toolchain, so a successful `.3dsx` build is not claimed here.
