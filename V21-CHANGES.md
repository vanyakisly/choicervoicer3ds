# v21 — generalized dub-pack import and conversion

- Expanded source-video detection and FFmpeg conversion beyond the one literal `dub_video.ogv` filename. Standard basenames, a single detected movie in a timed pack, nested `media/` video, and an explicit `video_file` in pack info are supported. Output is standardized to `dub_video.tcv`.
- Added common source containers including MP4/M4V, MOV, MKV, WebM, AVI, WMV, FLV, MPEG/MPG, 3GP, TS/MTS/M2TS, ASF, VOB, MXF, OGV/OGG video and GIF. Actual decodability is still determined by FFmpeg.
- Expanded line/backing audio conversion from WAV/MP3/OGG to FLAC, M4A, AAC, Opus, WMA, AIFF, CAF, AC3, AMR and additional FFmpeg-readable audio formats. Outputs are validated as mono PCM16 WAVs for native playback.
- Normalized matching `.ini`, `.cfg`, `.txt`, `.json`, `.yaml`, and `.yml` line metadata, merging sidecars and mapping common aliases for caption, timestamps, speaker/character, image and dub-only fields into the native parser's schema.
- Expanded image preprocessing to TIFF and GIF as well as PNG/JPEG/WebP/BMP.
- Source videos used for a successful TCV conversion are marked and removed from the generated embedded runtime staging tree to save ROMFS space; the original repository assets remain intact.
- The browser recognizes common raw-video filenames/containers and tells users when conversion is still required. The build now errors with the exact pack path if timestamped dialogue has no discoverable video or if a TCV file is invalid, rather than producing an artifact that cannot play the pack.
- Regression tests exercise uppercase MKV/video alternate names, nested media folders, FLAC audio, JSON/YAML timestamp aliases, TIFF artwork and missing-video diagnostics. Existing pack scanning, microphone, playback, session-manifest, framebuffer, and waveform tests remain part of the workflow.
- No manual data in `SD:/3ds/The Choicer Voicer/` is needed; stock/custom repository packs remain embedded in RomFS and writes go to `SD:/3ds/TheChoicerVoicer3DS_User/`.

Limitations: arbitrary encrypted/DRM media, unsupported codecs, malformed files, and packs without timing metadata cannot be made perfectly playable automatically. The workflow now reports these clearly. Physical Old 3DS playback and the ARM cross-build still require GitHub Actions/device validation.
