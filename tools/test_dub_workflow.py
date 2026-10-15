#!/usr/bin/env python3
"""Source-level checks for the Old 3DS dub workflow that needs hardware APIs."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent.parent
SOURCE = (ROOT / "3ds_port/source/main.c").read_text(encoding="utf-8")


def function_body(name: str, next_name: str) -> str:
    match = re.search(r"static void " + re.escape(name) + r"\([^;]*?\)\s*\{", SOURCE)
    if not match:
        raise AssertionError(f"Missing function definition: {name}")
    next_match = re.search(r"static void " + re.escape(next_name) + r"\([^;]*?\)\s*\{", SOURCE[match.end():])
    if not next_match:
        raise AssertionError(f"Missing next function definition: {next_name}")
    return SOURCE[match.start():match.end() + next_match.start()]

# A dub list is built from video-bearing child folders under the configured data root.
assert 'snprintf(path, sizeof(path), "%s/packs_voice", ROOT)' in SOURCE
assert 'scan_dub_pack_root(path, dub_pack_items, MAX_ITEMS)' in SOURCE
assert 'static void page_dub_pack_list(void)' in SOURCE
assert 'CHOOSE A DUB PACK' in SOURCE
assert 'Tap a row' in SOURCE

# Voice recording must be a real microphone capture with the clip video/audio as a guide.
start_recording = function_body("start_recording", "finish_recording")
assert "MICU_StartSampling" in start_recording
assert "play_wav_file(voice_clips[game.clip_index].path)" in start_recording
assert "dub_video.playing = true" in start_recording
assert "recording_started_ms = osGetTime()" in start_recording

# Waveform uses actual signed microphone samples and draws connected trace segments.
waveform_start = SOURCE.index("static void draw_waveform(bool live) {")
waveform_end = SOURCE.index("static void page_game(void) {", waveform_start)
waveform = SOURCE[waveform_start:waveform_end]
assert "(const int16_t *)mic_buffer" in waveform
assert "const int points = 144" in waveform
assert "c_line(&bottom_canvas, px, py, x, y" in waveform

# Playback intentionally overlays saved takes only, and does not fall back to source cues.
replay_pump = function_body("dub_replay_pump", "start_dub_replay")
assert "play_dub_overlay_wav(path)" in replay_pump
assert "play_dub_overlay_wav(voice_clips[idx].path)" not in replay_pump
assert "video_duration" in replay_pump
assert "ignored line timestamps beyond the video duration" in replay_pump
replay_start = function_body("start_dub_replay", "play_current_clip")
assert "No voice takes saved yet" in replay_start
assert "take_count == 0" in replay_start

# Stop/save writes the microphone buffer; SAVE DUB writes a timeline manifest.
stop_recording = function_body("stop_recording", "start_recording")
assert "save_wav(path, mic_buffer, bytes, MIC_RATE, 1, 16)" in stop_recording
save_start = SOURCE.index("static void save_latest_dub(void) {")
save_end = SOURCE.index("static void watch_latest_dub(void) {", save_start)
assert "write_dub_session_manifest()" in SOURCE[save_start:save_end]

# The app caps drawing to every other VBlank and uses the optimized TCV 2x path.
assert "#define RENDER_VBLANK_DIVISOR 2u" in SOURCE
assert "if (render_divider >= RENDER_VBLANK_DIVISOR)" in SOURCE
assert "if (w == (int)v->width * 2 && h == (int)v->height * 2)" in SOURCE
print("PASS: dub browser, mic recording, live signed waveform, recorded-take-only Watch Dub, Save Dub manifest and 30 FPS render-cap source checks.")
