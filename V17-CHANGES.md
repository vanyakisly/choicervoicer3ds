# v17 — Live waveform, recording status, and Dub Cinema playback

## Live microphone waveform

- The 3DS microphone's completed PCM16 sample tail is copied into a fixed 2048-sample snapshot while recording.
- The lower-screen waveform draws a connected, continuously refreshed line from those real samples; it is not an animated decorative waveform.
- The last waveform freezes on the completed take after recording stops, so the user can immediately see the audio just captured.
- An Old 3DS host-side regression test checks that the snapshot follows the latest samples and clamps the MICU sample offset to the valid sample area.

## Recording-stopped feedback

- A dedicated status strip above the four touch buttons displays elapsed recording time while recording.
- After manual stop or microphone auto-stop, it clearly shows `RECORDING STOPPED - TAKE SAVED`, `RECORDING STOPPED - TOO SHORT TO SAVE`, or a specific save/microphone error.
- Gameplay status no longer shares the toast area that overlapped WATCH DUB and SAVE DUB.
- Error states for microphone start, video seek/decode, and saved-take playback are visible on the lower screen too.

## Watch Dub plays on Dub Cinema

- PAGE_DUB now draws the selected TCV movie on the top screen while the user is recording or Watch Dub is active; previously that page kept a static illustration while its playback engine could run in the background.
- Watch Dub seeks to the scene start, advances the video, plays the backing track where available, and queues the user's saved takes against their absolute timestamps. Missing takes remain silent; source voice cues are not substituted.
- The Watch Dub status and finish state are shown on the lower screen.

## Avoid unnecessary SD-card work

- The current line's recorded/unrecorded indicator is cached by active pack and clip index instead of opening a WAV file on every rendered frame.
- The actual PCM snapshot is only recopied when the MICU sample offset advances.

## Data folder requirement unchanged

All default assets and bundled packs are embedded in the executable RomFS during the GitHub build. The 3DS installation still requires only `SD:/3ds/TheChoicerVoicer3DS.3dsx` and its adjacent `.smdh`. Writable recordings and settings go to `SD:/3ds/TheChoicerVoicer3DS_User/`. You do not need to create, copy, update, or replace anything in `SD:/3ds/The Choicer Voicer/`.

## Validation

The live-waveform PCM-snapshot unit test, Watch/Save Dub source checks, nested pack scanner, Save Dub manifest, native pack loader, video/audio preprocessing, asset optimization, framebuffer mapping, video blit, and workflow YAML checks pass on the host. No ARM cross-build or physical Old 3DS test was performed here; real microphone capture, audio mixing, and smooth playback still need verification through GitHub Actions and on hardware.
