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

HOW TO CHOOSE AND PLAY A DUB ON OLD 3DS

1. Put the entire extracted dub pack folder directly under:
     SD:/3ds/The Choicer Voicer/packs_voice/<Pack Name>/
   Do not put it under luma/3ds or an extra nested folder.
2. The pack must contain dub_video.tcv (created automatically by the GitHub
   install build from dub_video.ogv) and line audio with .ini/.txt metadata
   containing dub_timestamps. A normal voice-only pack will not appear in the
   Dub Mode list.
3. Launch the homebrew, choose PLAY > DUB MODE. Dub packs are shown in a list.
   Tap a row with the stylus and press USE, or navigate with D-pad and A.
4. On the bottom screen press START + RECORD for each line. The source line
   plays as a timing guide while the microphone records. Press STOP & SAVE or
   NEXT; the take is saved automatically for that timestamp. Move through the
   lines using NEXT.
5. WATCH DUB replays the compressed video and overlays only the takes you
   recorded, at their original dub_timestamps. Lines not recorded are silent
   rather than replaced by the original guide voice. SAVE DUB writes a session
   manifest alongside the individual WAV takes. This native SAVE DUB creates a
recording session package; it does not encode a new MP4/OGV video file on the
3DS itself.
6. Re-run the GitHub Actions build after adding/changing packs in the repository
   root's packs_voice/ folder, then extract the resulting SD install archive to
   the SD root. This converts video to 160x90 RGB565 at 10 FPS and normalizes
   line audio to PCM16 WAV for the Old 3DS runtime.

The native UI is capped to render at most 30 FPS (every other 60 Hz VBlank);
video is decoded at 10 FPS to limit CPU load. Actual sustained speed depends on
pack complexity and the Old 3DS hardware, so the cap is not a guarantee that
all scenes will maintain 30 FPS. Each take is limited by the recording-duration
setting (maximum 8 seconds in this build).
