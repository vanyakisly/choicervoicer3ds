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


## Voice and dub pack compatibility (v21)

The build-time pack converter is intentionally more flexible than the 3DS runtime. It recursively searches `packs_voice/` and generates a standard `dub_video.tcv` plus native assets for each detected dub pack. Accepted common video containers include OGV/OGG video, MP4/M4V, MOV, MKV, WebM, AVI, WMV, FLV, MPEG/MPG, 3GP, TS/MTS/M2TS, VOB, ASF, MXF, GIF and other formats that FFmpeg can decode. It prefers `dub_video.*`, `dubvideo.*`, `source_video.*`, `video.*`, `movie.*`, or `clip.*`; it can also use a single detected video in a timestamped pack, a path set in `_pack_info.ini` (`video_file=...`), or one video nested under a `media/`-style folder.

Per-line audio is normalized from common WAV, MP3, OGG, FLAC, M4A, AAC, Opus, WMA, AIFF, CAF, AC3, AMR and other FFmpeg-readable audio sources into `stem.3ds.wav` mono PCM16. Matching `.ini`, `.cfg`, `.txt`, `.json`, `.yaml` and `.yml` sidecars are merged into native `.ini` metadata. Common aliases such as `text`/`subtitle`, `timestamp`/`start_time`, `speaker`, `thumbnail` and `image_path` are normalized to the native keys `caption`, `dub_timestamps`, `dub_characters` and `image`. Clip artwork from PNG/JPG/JPEG/WebP/BMP/TIFF/GIF gets bounded `.tcvr` companions. The original source repository files are not modified; only the generated ROMFS staging copy is pruned.

The 3DS runtime reads the standardized TCV (160×90 RGB565, 10 fps, zlib-compressed frames), normalized PCM16 WAV files and TCVR art. The GitHub workflow tests multiple containers and metadata forms, and fails with the exact pack path if timestamped lines have no discoverable/decodeable video rather than embedding a broken pack. Packs still need timing information for correct synchronization: if timestamps are absent from sidecar metadata and filenames, the build will report the pack instead of guessing inaccurate line timing. DRM-protected media or files that FFmpeg cannot decode are not supported. Dub recordings are saved under `recordings/dub_recordings/<Pack Name>/3DS Session/` and replayed against line timestamps.

On v19, the lower screen draws a live, scrolling waveform from actual completed microphone PCM samples. When recording stops (manually or by reaching the limit), the status strip reports whether the take was saved or why it failed. Watch Dub displays the actual selected TCV movie in Dub Cinema as well as in Dub Mode, and schedules saved line recordings against the video timestamps. The current line's recorded/unrecorded indicator is cached to avoid repeated SD-card file checks every frame.

To convert a pack locally before copying it to the SD card, install Python 3, Pillow and FFmpeg, then run `python tools/prepare_3ds_dub_packs.py --tree packs_voice`. The GitHub workflow runs a synthetic video/audio/image test and a host-side regression test of the actual C metadata scanner before attempting the devkitARM build.

This is a hardware-adapted native port, not an execution of Godot scenes on the 3DS. It targets the original pack structures, but the completed ARM build and physical-device behavior still need validation from the GitHub Actions build and on an Old 3DS.


## v18 — Pack selector crash fix

The dub browser no longer allocates its 64-item (~39.7 KiB) scratch array on the main stack. Pack/voice directory scanning now uses bounded iterative directory stacks and a 512-directory scan budget, and menu code reuses static item-list scratch buffers. The GitHub host regression test runs the actual multi-root scanner with a 64 KiB stack limit on Linux and checks compiler-measured frame sizes.


## v19 — Microphone, Repeat Line and Watch Dub requirement

MIC shared memory is allocated with a `0x1000`-aligned address and buffer size, matching libctru's MIC API and official microphone example. Failure messages retain the exact `micInit` result code. `REPEAT LINE` replays the selected cue and its matching video segment. `WATCH DUB` is locked until every timestamped line has a saved take; its completion scan is cached and invalidated after a successful take save.

The native app continues to use embedded RomFS assets and automatically created writable state under `SD:/3ds/TheChoicerVoicer3DS_User/`; it does not require files to be added to or replaced in `SD:/3ds/The Choicer Voicer/`.

## v20 — Pack conversion status fix

The pack browser treats names that differ only by capitalization, spaces, underscores, or hyphens as equivalent. If duplicate copies exist, it prefers the most-ready converted pack. The GitHub workflow validates every converted TCV video and reports pack-specific conversion failures. No manual changes to `SD:/3ds/The Choicer Voicer/` are required.


## v22 — Pack-agnostic build and validation

There are no required paths, titles, characters, or clip counts for a particular sample pack. Every eligible dub pack under repository-root `packs_voice/` (including packs nested under collection folders) is merged into the runtime staging tree and processed independently. The converter accepts common FFmpeg-readable video/audio formats, normalizes metadata to the fields the native player understands, creates `dub_video.tcv` plus native audio/artwork companions, and reports the exact directory when an eligible pack cannot be converted. The workflow validates every generated TCV header rather than checking a fixed sample path. Add all desired pack folders to repository-root `packs_voice/` before running GitHub Actions; rebuild after adding/changing packs. The on-device runtime cannot run FFmpeg and cannot automatically convert arbitrary source media added after the build.

## v23 — Startup and browsing load-time optimization

The native app now loads only the fonts and a few first-screen images at launch. Other UI art is lazy-loaded on its first use, with a per-asset attempted-load flag so missing images do not trigger repeated file opens. Pack category lists are cached for the app session, and the dub-pack list is scanned once then reused when reopening the selector. During the GitHub build, `prepare_3ds_assets.py` generates `packs_voice/.tcv_pack_index.tsv` after all packs are converted. The index lists each embedded pack's relative folder and dialogue-event count, letting the 3DS discover immutable RomFS packs without recursively walking every media directory at runtime. The workflow validates the catalog against all generated TCV videos; an empty catalog is valid when no embedded dub packs are supplied.

This does not require any migration or replacement of `SD:/3ds/The Choicer Voicer/`. Built-in data remains inside the `.3dsx`; saves, settings and takes continue under `SD:/3ds/TheChoicerVoicer3DS_User/`. Existing user/legacy pack roots remain optional fallbacks, and the old path is never written to. Expected benefit is shorter cold startup and much faster repeated visits to pack selection; absolute timings and sustained 30 FPS still require measurement on a physical Old 3DS.

## Export a finished full-length dub

The 3DS saves voice takes and their timestamps. To create one smooth MP4 with the full original video, export on Windows using `EXPORT-DUB-VIDEO-WINDOWS.bat` after copying the SD card to the PC. See `EXPORT-FULL-DUB.md`. This doesn't require adding or replacing files inside `SD:/3ds/The Choicer Voicer/`.


## v25 runtime staging fix

Default WAV music and SFX are preserved by the pruning pass unless a distinct `.3ds.wav` companion exists. The GitHub Actions staging step prints the exact failed command and line for easier diagnosis.
