# Export the finished full-length dub on Windows

The Old 3DS saves each recorded line and its timestamp, but it does not have enough processing power to reliably re-encode a complete video in real time. Use the Windows exporter to create one smooth, complete MP4 after saving your session.

## Requirements

- Python 3 (the Windows launcher uses the standard library only; Tkinter is included with most standard Python installers)
- FFmpeg for Windows. The exporter searches `PATH`, common `C:\ffmpeg` locations, and common Gyan FFmpeg WinGet install folders automatically; adding its `bin` folder to `PATH` also works.
- The original source pack folder from the repository's `packs_voice/` folder
- The `session.ini` and recorded take WAV files saved by the 3DS

## Steps

1. Finish dubbing every line and press **SAVE DUB** on the 3DS.
2. Turn off the 3DS and put the SD card into the PC.
3. Extract the project source ZIP on the PC, or use the existing extracted source checkout. Do not copy or replace anything in `SD:/3ds/The Choicer Voicer/`.
4. Double-click `EXPORT-DUB-VIDEO-WINDOWS.bat`.
5. In the first dialog, select the `session.ini` from the SD card, usually under `3ds/TheChoicerVoicer3DS_User/recordings/dub_recordings/<Pack Name>/3DS Session/`.
6. Select the matching original pack folder under the extracted source tree's `packs_voice/` folder.
7. Choose where to save the final MP4 on the PC.

The tool reads the source video and backing track from the selected source pack, places every recorded WAV at its timestamp, mixes the audio, and encodes a complete H.264/AAC MP4 with `faststart`. It checks that every line in the session has a take by default and verifies the output duration against the source video. It does not overwrite takes, session metadata, or source pack files.

## Command line

```powershell
python tools/export_dub_video.py --session "E:\\3ds\\TheChoicerVoicer3DS_User\\recordings\\dub_recordings\\Example Pack\\3DS Session\\session.ini" --pack-dir "C:\\Projects\\The Choicer Voicer\\packs_voice\\Example Pack" --output "C:\\Users\\You\\Videos\\Example Pack - Dubbed.mp4"
```

Use `--allow-incomplete` only if you intentionally want missing takes to remain silent.

## Audio mix

If a backing track is present (for example `_backing_track.mp3`), it is looped to the full video length and mixed with the recorded lines. Otherwise the video's own audio is retained at a lower volume, or a silent bed is used if the source has no audio. The original video audio is not mixed when a named backing track is available, avoiding the original dialogue competing with the new dub.
