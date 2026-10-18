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

# Default packs are embedded; user/legacy custom packs are optional overlay roots.
assert '#define ROOT "romfs:/tcv"' in SOURCE
assert '#define USER_ROOT "sdmc:/3ds/TheChoicerVoicer3DS_User"' in SOURCE
assert 'static int scan_all_dub_pack_roots(' in SOURCE
assert 'USER_ROOT "/packs_voice"' in SOURCE
assert 'LEGACY_ROOT "/packs_voice"' in SOURCE
assert 'scan_dub_pack_root(external_roots[r], dub_pack_scan_scratch, MAX_ITEMS)' in SOURCE
assert 'scan_embedded_dub_pack_catalog(dub_pack_scan_scratch, MAX_ITEMS)' in SOURCE
assert 'if (embedded_count < 0)' in SOURCE
assert 'static bool dub_pack_cache_valid = false' in SOURCE
assert 'if (!dub_pack_cache_valid)' in SOURCE
assert 'static ItemList pack_category_cache[7]' in SOURCE
assert 'if (pack_category_cache_valid[cache_index])' in SOURCE
assert 'static DubPackItem dub_pack_scan_scratch[MAX_ITEMS]' in SOURCE
assert 'DubPackItem scratch[MAX_ITEMS]' not in SOURCE
assert 'static DubScanFrame dub_scan_frames[MAX_DUB_SCAN_DEPTH + 1]' in SOURCE
assert 'static VoiceScanFrame voice_scan_frames[MAX_VOICE_SCAN_DEPTH + 1]' in SOURCE
assert 'scan_voice_dir(pack_root, path, rel' not in SOURCE
assert 'scan_dub_pack_tree(voice_root, child, child_relative' not in SOURCE
assert 'MAX_DUB_SCAN_DIRS 512u' in SOURCE
assert 'dub_pack_scan_dirs_visited = 0' in SOURCE
assert 'MAX_VOICE_SCAN_DIRS 512u' in SOURCE
assert 'static void scan_dub_pack_tree(' in SOURCE
assert 'snprintf(pending_dub_pack_path, sizeof(pending_dub_pack_path), "%s", item->path)' in SOURCE
assert 'use_pending_dub_path' in SOURCE
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
assert "MIC_WAVE_SNAPSHOT_SAMPLES" in waveform
assert "const int points = 144" in waveform
assert "c_line(&bottom_canvas, px, py, x, y" in waveform
assert "static int16_t mic_wave_snapshot[MIC_WAVE_SNAPSHOT_SAMPLES]" in SOURCE
assert "static void update_live_waveform_snapshot(void)" in SOURCE
assert "update_live_waveform_snapshot();" in SOURCE[SOURCE.index("int main(int argc, char **argv)"):]
assert "RECORDING STOPPED - TAKE SAVED" in SOURCE
assert "RECORDING STOPPED - TOO SHORT TO SAVE" in SOURCE
assert "static void draw_game_status_line(void)" in SOURCE
# Dub Cinema has to render the actual TCV frames during recording/review,
# not just display a static tutorial illustration.
page_dub_start = SOURCE.index("static void page_dub(void) {")
page_dub_end = SOURCE.index("static void page_packs(void) {", page_dub_start)
assert "draw_tcv_video(&top_canvas, 40, 57, 320, 180)" in SOURCE[page_dub_start:page_dub_end]
assert "WATCH DUB - PLAYING FULL SCENE" in SOURCE

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
assert "uint32_t *argb_pixels" in SOURCE
assert "if (redraw_pending)" in SOURCE
assert 'R_SUCCEEDED(romfsInit())' in SOURCE
print("PASS: cached pack categories, embedded catalog and custom pack fallback, mic waveform, Watch/Save Dub, cached video colours, dirty redraw and 30 FPS render cap.")
