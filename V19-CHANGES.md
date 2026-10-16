# v19 — Microphone initialization, Repeat Line, and full-dub gating

## Microphone fix

- Allocate MIC shared memory with `memalign(0x1000, MIC_BUFFER_SIZE)`, as required by libctru's `micInit` API. The official libctru microphone example uses the same aligned allocation pattern.
- Free the aligned heap buffer with `free()` on all failure paths and on shutdown; do not use `linearFree()` on this allocation.
- Verify the pointer and buffer size alignment before asking libctru to map the shared memory.
- Keep the actual `micInit` result visible on-screen rather than replacing it with a generic “Microphone unavailable” message.

## Dub controls

- Added a `REPEAT LINE` button to replay the selected source cue and matching video segment. In standard voice mode, it replays the selected prompt.
- `WATCH DUB` shows `RECORD ALL LINES` and refuses playback until every timestamped line has a saved take. The action is guarded as well as the UI.
- Cache full-session completion checks and invalidate after a successful take save to avoid repeated SD-card checks during rendering.

## SD-card policy

Default artwork, sounds, music, and built-in packs remain embedded in RomFS. The application automatically creates writable saves and recordings under `SD:/3ds/TheChoicerVoicer3DS_User/`. Users do not need to add, replace, or update anything under `SD:/3ds/The Choicer Voicer/`; the legacy location is only a read-only compatibility fallback if already present.

## Verification

- Added a MIC init regression test for 0x1000-aligned shared-memory allocation, service errors, and cleanup.
- Added workflow guardrails for `REPEAT LINE`, the all-lines-before-Watch-Dub requirement, and the embedded/read-only data policy.
- Dub pack discovery, manifest creation, video/audio preprocessing, waveform, framebuffer, and cached blit tests pass in the host environment.
- This source has not yet been cross-compiled with devkitARM or run on a physical 3DS. The GitHub Actions build and an on-console test remain necessary.
