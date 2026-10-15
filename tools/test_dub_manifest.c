/* Host regression test for saving recorded per-timestamp takes and session metadata. */
#define main tcv_native_program_entry
#include "../3ds_port/source/main.c"
#undef main

static int write_dummy_take(const char *path) {
    FILE *f = fopen(path, "wb");
    if (!f) return 0;
    const char bytes[] = "fake test take";
    int ok = fwrite(bytes, 1, sizeof(bytes), f) == sizeof(bytes);
    if (fclose(f) != 0) ok = 0;
    return ok;
}

int main(void) {
    if (!setup_storage()) { fprintf(stderr, "setup_storage failed\n"); return 1; }
    active_dub_pack = true;
    snprintf(active_pack_name, sizeof(active_pack_name), "Sample Pack");
    voice_clip_count = 2;
    for (int i = 0; i < voice_clip_count; ++i) {
        memset(&voice_clips[i], 0, sizeof(voice_clips[i]));
        snprintf(voice_clips[i].stem, sizeof(voice_clips[i].stem), "01_Line");
        snprintf(voice_clips[i].relative, sizeof(voice_clips[i].relative), "01_Line.wav");
        voice_clips[i].timestamp = i == 0 ? 0.5f : 2.25f;
        voice_clips[i].timestamp_count = 2;
        voice_clips[i].timestamp_ordinal = (uint8_t)i;
    }
    if (!ensure_dub_record_directories()) { fprintf(stderr, "record directories failed\n"); return 2; }
    for (int i = 0; i < voice_clip_count; ++i) {
        char take[600];
        if (!make_active_dub_record_path(i, take, sizeof(take), true) || !write_dummy_take(take)) {
            fprintf(stderr, "could not create take %d\n", i); return 3;
        }
    }
    if (!write_dub_session_manifest()) { fprintf(stderr, "manifest writer failed\n"); return 4; }
    char path[700];
    snprintf(path, sizeof(path), "%s/dub_recordings/Sample Pack/3DS Session/session.ini", REC_DIR);
    FILE *f = fopen(path, "rb");
    if (!f) return 5;
    char text[8192]; size_t n = fread(text, 1, sizeof(text)-1, f); text[n] = '\0'; fclose(f);
    if (!strstr(text, "recorded_count=2") || !strstr(text, "_dubrecord_01_Line_t00000500_01.wav") ||
        !strstr(text, "_dubrecord_01_Line_t00002250_02.wav") ||
        !strstr(text, "recorded=true")) {
        fprintf(stderr, "manifest contents incorrect:\n%s\n", text); return 6;
    }
    puts("PASS: SAVE DUB writes distinct per-timestamp WAV take names and a session.ini timeline manifest.");
    return 0;
}
