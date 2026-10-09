CUSTOM VOICE AND DUB PACKS FOR THE OLD 3DS BUILD

Put each complete The Choicer Voicer voice/dub pack in its own folder here:

  packs_voice/<Pack Name>/
    _pack_info.ini          optional
    _icon.png               optional
    01_LineName.wav/mp3/ogg
    01_LineName.ini/txt     optional clip metadata
    dub_video.ogv           required for Dub Mode
    _backing_track.ogg      optional

Keep the pack's folder name and internal file names intact. Dub clips should have
matching .ini/.cfg/.txt metadata containing e.g.:

  [data]
  caption="Wait, that was not the plan."
  dub_timestamps=[1.866]
  dub_characters=["Narrator"]

The GitHub Actions build copies these packs into the SD install artifact. It
preserves dub_video.ogv but also creates dub_video.tcv, a compact Old-3DS video
stream sampled at 160x90, 10 fps with RGB565 pixels, keyframes and zlib-compressed
deltas. WAV/MP3/OGG sources receive normalized `.3ds.wav` PCM16 companions (22.05 kHz mono for lines, stereo for `_backing_track`) for the native audio player. Original source media and metadata are preserved. PNG/JPG/JPEG/WebP/BMP clip art receives `.tcvr` RGBA companions for the 3DS renderer.

You can also prepare packs locally (Python 3 + ffmpeg required):
  python tools/prepare_3ds_dub_packs.py --tree packs_voice

The converter never edits the original OGV file. Keep an original backup anyway.
