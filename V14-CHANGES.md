# v14 — Dub browser, real voice waveform, recording playback and 30 FPS target

- Added a dedicated Dub Pack list which discovers video packs directly under `SD:/3ds/The Choicer Voicer/packs_voice/`.
- Shows only folders containing `dub_video.tcv` or `dub_video.ogv`; puts converted packs with timestamped line clips at the top and displays why other packs cannot start.
- Added screen instructions explaining row selection, USE, START + RECORD, NEXT, WATCH DUB and SAVE DUB.
- Fixed Watch Dub to overlay the player's saved voice takes only. Missing takes are now silent instead of falling back to the stock cue audio, which previously made dubbing seem not to work.
- Saved line recordings are retained as per-timestamp WAV takes. SAVE DUB writes a `session.ini` manifest describing which source clips have takes and their timestamps.
- Bottom screen waveform is drawn from actual signed PCM samples in the microphone buffer while recording, and from the latest recorded/playback buffer afterward.
- Added the alternate-VBlank (30 FPS maximum render cadence) and optimized the normal 160x90-to-320x180 RGB565 video blit by converting each source pixel once and writing a 2x2 block.
- Added `tools/test_dub_pack_browser.py` to GitHub Actions to verify discovery, sorting, timestamp occurrences, original voice-only exclusion, and conversion status.

Verification is host-side only. No ARM cross-compiled binary or physical Old 3DS performance measurement is claimed by this source update. The render cadence caps rendering at 30 FPS; it cannot guarantee a locked 30 FPS on the device until measured on real hardware.
