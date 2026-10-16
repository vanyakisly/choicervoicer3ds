#!/usr/bin/env python3
"""Static guardrails for microphone allocation, Repeat Line, full-dub gating and embedded-data policy."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
src = (ROOT / "3ds_port/source/main.c").read_text(encoding="utf-8")

mic = src[src.index("static bool init_mic(void) {"):src.index("static void update_live_waveform_snapshot(void) {")]
assert "memalign(0x1000u, MIC_BUFFER_SIZE)" in mic
assert "linearAlloc(MIC_BUFFER_SIZE)" not in mic
assert "free(mic_buffer)" in mic
assert "MIC init failed (0x%08lX)" in mic
caller = src[src.index("static void start_recording(void) {"):src.index("static void finish_recording(void) {")]
assert "set_message(\"Microphone unavailable\")" not in caller

ui = src[src.index("static void draw_game_touch_ui(void) {"):src.index("static void draw_waveform(bool live) {")]
assert '"REPEAT LINE", 4' in ui
assert '"RECORD ALL LINES"' in ui
assert 'all_dub_takes_recorded(NULL)' in ui
assert "case PAGE_GAME: case PAGE_DUB: count=5; break;" in src
menu = src[src.index("static void activate_menu(int id) {"):src.index("static void back_page(void) {")]
assert "else if (id == 4) repeat_current_line();" in menu
repeat = src[src.index("static void repeat_current_line(void) {"):src.index("static void open_pack_browser(int type, Page return_page) {")]
assert "tcv_seek(&dub_video, clip->timestamp)" in repeat
assert "play_wav_file(clip->path)" in repeat
watch = src[src.index("static void start_dub_replay(void) {"):src.index("static void play_current_clip(void) {")]
assert "if (!all_dub_takes_recorded(&first_missing))" in watch
assert "Record every line before Watch Dub" in watch
assert '#define ROOT "romfs:/tcv"' in src
assert '#define USER_ROOT "sdmc:/3ds/TheChoicerVoicer3DS_User"' in src
assert 'sdmc:/luma/3ds' not in src and 'SD:/luma/3ds' not in src
assert 'SD:/3ds/The Choicer Voicer/' not in src[src.index('static bool ensure_dub_record_directories(void) {'):src.index('static bool make_active_dub_record_path')]
print("PASS: aligned MIC initialization, visible error diagnostics, Repeat Line control, all-lines Watch Dub gate, and embedded/read-only data policy.")
