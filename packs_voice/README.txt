CUSTOM VOICE AND DUB PACKS FOR THE OLD 3DS BUILD

Put complete The Choicer Voicer packs somewhere under this folder. Each dub pack
must be a DIRECTORY containing dub_video.ogv (the GitHub build creates
dub_video.tcv) plus timestamped line audio and metadata. The native browser now
searches recursively, so both layouts are supported:

  packs_voice/<Pack Name>/dub_video.ogv
  packs_voice/<Archive or Collection>/<Pack Name>/dub_video.ogv

The directory containing dub_video.ogv is the pack root. The pack's line files
can be at that level or inside subdirectories. Common files include:

  _pack_info.ini             pack title/icon metadata (optional)
  _icon.png                  pack icon (optional)
  001_Verity.wav             audio line
  001_Verity.jpg             line artwork (optional)
  001_Verity.txt             caption and timestamp metadata
  dub_video.ogv              source video, required for Dub Mode
  _backing_track.mp3/ogg     optional backing track

A line metadata file can look like this:

  [data]
  caption="Hey, it's me!"
  image="001_Verity.jpg"
  dub_timestamps=[1.695]
  dub_characters=["Verity"]

The example pack `verity song/` is included here to verify the real format: it
contains 46 timestamped line clips, clip artwork, `_pack_info.ini`, the original
OGV and a backing track. The pack browser excludes voice-only directories that
do not contain a dub video.

The GitHub Actions build keeps source media and metadata, then generates
`dub_video.tcv` (160x90, 10 fps), `.3ds.wav` PCM16 companions for supported line
and backing audio, and `.tcvr` artwork for the Old 3DS runtime. These generated
files are consumed by the native player.

HOW TO USE ON OLD 3DS

1. Copy the entire pack folder structure to
   SD:/3ds/The Choicer Voicer/packs_voice/ . Keep the directory names intact.
2. Re-run the GitHub Actions build whenever you add/change packs, then copy the
   SD install artifact to the SD card. This generates the `.tcv` video and media
   companions required by the native app.
3. Launch the homebrew, choose PLAY > DUB MODE, pick the pack from the list,
   then select USE. Packs without a video or without timestamped clip metadata
   are not usable in Dub Mode.
4. On the bottom screen press START + RECORD for each line; NEXT changes line.
   WATCH DUB plays the video and your recorded takes at the pack timestamps.
   SAVE DUB saves the per-line WAV takes and `session.ini` timeline manifest.

The Old 3DS app does not yet render a newly merged video file on-device; it
plays the compressed source video and overlays the saved voice takes.
