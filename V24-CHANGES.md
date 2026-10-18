# v24 — Full dubbed-video export on Windows

- Added `tools/export_dub_video.py` to render a complete H.264/AAC MP4 from the source pack video, saved `session.ini`, and per-line WAV takes at their absolute timestamps.
- Mixes `_backing_track` when available; otherwise retains source audio at lower volume or adds a full-length silent bed. The mix is limited to the original full video duration and encoded offline to avoid real-time playback/render lag.
- Added `EXPORT-DUB-VIDEO-WINDOWS.bat` for a double-click GUI workflow on Windows and `EXPORT-FULL-DUB.md` instructions.
- The exporter locates FFmpeg in PATH or common Windows/WinGet installation locations, checks all lines have recordings, verifies the final MP4 duration, and protects input files from being overwritten.
- Updated the 3DS SAVE DUB confirmation message with the PC export step. No assets or files need to be placed in `SD:/3ds/The Choicer Voicer/`; the tool reads the session and takes already saved by the app.
- Added an FFmpeg integration regression test for nested MKV source video, timestamped take mixing, backing track, full output duration, silent-bed fallback, and incomplete-session rejection.
- Validated the exporter with synthetic test packs and ran the existing host-side pack/audio/video/microphone/framebuffer regression tests. ARM cross-compilation and physical console testing remain to be done on GitHub Actions/device.
