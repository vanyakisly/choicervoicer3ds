# v15 — nested dub pack folder support

- Dub browser recursively searches below `SD:/3ds/The Choicer Voicer/packs_voice/`
  for directories that contain `dub_video.tcv` or `dub_video.ogv`, rather than
  assuming every pack is directly under `packs_voice/`.
- Each browser entry stores its exact discovered directory and passes that path
  into `begin_match`, so selecting a nested pack opens the correct video, line
  audio, artwork, backing track, and timestamp metadata.
- The actual `verity song` example pack from the supplied ZIP is included under
  repository `packs_voice/verity song/`. It contains `_pack_info.ini`, 46 line
  WAV/JPG/TXT triplets, `dub_video.ogv`, and `_backing_track.mp3`.
- Regression tests cover a nested `Collection/verity song/` structure and the
  real 46-line example pack.

To use other packs, copy the complete extracted pack directory under
`packs_voice/` (or inside a collection folder there), commit it, and rerun the
GitHub Actions build. The staging converter already processes nested files
recursively and writes `.tcv`, `.3ds.wav` and `.tcvr` companions beside their
source assets.

The build and tests do not replace a physical Old 3DS playback test.
