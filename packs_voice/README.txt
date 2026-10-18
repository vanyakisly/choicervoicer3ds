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
  001_Character.wav          audio line (name/number can be anything)
  001_Character.jpg          line artwork (optional)
  001_Character.txt/.ini     caption and timestamp metadata
  dub_video.ogv              source video; other supported filenames/formats work too
  _backing_track.mp3/ogg     optional backing track

A line metadata file can look like this:

  [data]
  caption="Hey, it's me!"
  image="001_Character.jpg"
  dub_timestamps=[1.695]
  dub_characters=["Character Name"]

This repository may include example packs, but no particular pack title, creator,
character, filename, or line count is required by the converter. The build scans
all eligible pack directories under `packs_voice/`. The pack browser excludes voice-only directories that
do not contain a dub video.

The GitHub Actions build converts every eligible dub pack under repository-root
`packs_voice/` (including nested collections) before embedding it. A playable
pack needs a video stream and timestamped line audio/metadata; no pack title is
special-cased. If one pack cannot be converted, the build reports its path.
The build keeps source media in your repository and generates
`dub_video.tcv` (160x90, 10 fps), `.3ds.wav` PCM16 companions for supported line
and backing audio, and `.tcvr` artwork for the Old 3DS runtime. These generated
files are consumed by the native player.

HOW TO USE ON OLD 3DS

1. Place each complete pack directory under the repository's root-level
   `packs_voice/` folder. You can use any pack name and keep extra collection
   folders; keep each pack's video, line audio, and metadata together.
2. Re-run GitHub Actions whenever you add/change packs, then copy the SD install
   artifact to the SD card. This converts every eligible repository pack into
   the `.tcv` video and native audio/artwork companions used by the app.
3. Launch the homebrew, choose PLAY > DUB MODE, pick the pack from the list,
   then select USE. Packs without a video or without timestamped clip metadata
   are not usable in Dub Mode.
4. On the bottom screen press START + RECORD for each line; NEXT changes line.
   WATCH DUB plays the video and your recorded takes at the pack timestamps.
   SAVE DUB saves the per-line WAV takes and `session.ini` timeline manifest.

The Old 3DS app does not yet render a newly merged video file on-device; it
plays the compressed source video and overlays the saved voice takes.
