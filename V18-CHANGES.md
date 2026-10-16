# v18 — Fix crash when opening or selecting a dub pack

## Root cause found

The pack browser placed `DubPackItem scratch[MAX_ITEMS]` on the main thread stack. Each record is 620 bytes, so this array consumed 39,680 bytes before scanner locals and call frames were counted. That is unsafe for an Old 3DS application stack and explains a crash as the dub-pack list opens. The scanner also used recursive tree walks with large local buffers, and some menu code reserved a full ~6 KiB `ItemList` on the stack.

## Fixes

- Moved the 64-entry dub scan scratch array, root directory list, common pack list, and recording list to static bounded storage. No ~40 KiB or ~6 KiB temporary list arrays remain in the menu call chain.
- Replaced recursive `packs_voice` directory traversal with an iterative DFS stack.
- Replaced recursive line/audio scanning with an iterative DFS stack. Both scanners have a maximum depth of six/five respectively, cap a scan at 512 opened directories, close every open `DIR*` handle, and cap discovered packs/clip events as before.
- Kept the original path behavior: scan optional writable packs, legacy `SD:/3ds/The Choicer Voicer/packs_voice/`, then embedded RomFS packs; retain exact nested paths and prefer the converted `.tcv` video.
- Moved `ItemList` locals out of `begin_match`, `get_pack_dir`, `pack_count_for_type`, and the recordings menu path to reduce stack use during selection.
- Extended the C regression harness to exercise the same multi-root scanner entry point under a 64 KiB process stack limit where supported. The test also checks GCC-reported frame sizes for key selection/scan functions.

## Validation

The multi-root pack browser test passes with a restricted 64 KiB host stack and recognizes the included `verity song` sample with 46 timestamped line events. The dub workflow, session manifest, media preprocessing, asset optimizer, native pack loader, framebuffer flush, cached video blit, live waveform, and GitHub Actions YAML tests all pass. No real devkitARM cross-build or physical Old 3DS test was performed in this environment; the next GitHub Actions run and console run are still needed to confirm the crash is resolved on device.
