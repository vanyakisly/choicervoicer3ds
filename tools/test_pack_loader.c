/* Host regression harness for the native pack scanner. This is not a 3DS build. */
#define main tcv_native_program_entry
#include "../3ds_port/source/main.c"
#undef main

int main(int argc, char **argv) {
    if (argc != 2) return 90;
    int count = load_voice_clips(argv[1], true);
    if (count != 5) {
        fprintf(stderr, "expected 5 timestamped dub timeline events (including an array timestamp), got %d\n", count);
        return 1;
    }
    if (strcmp(voice_clips[0].stem, "01_A") || fabsf(voice_clips[0].timestamp - 1.25f) > 0.001f) return 2;
    if (strcmp(voice_clips[0].caption, "First line") || strcmp(voice_clips[0].characters, "Narrator")) return 3;
    if (!has_ext(voice_clips[0].path, ".3ds.wav")) return 4;
    if (strcmp(voice_clips[1].stem, "02_B") || fabsf(voice_clips[1].timestamp - 2.5f) > 0.001f) return 5;
    if (strcmp(voice_clips[3].stem, "04_Multi") || fabsf(voice_clips[3].timestamp - 4.0f) > 0.001f) return 6;
    if (strcmp(voice_clips[4].stem, "04_Multi") || fabsf(voice_clips[4].timestamp - 5.25f) > 0.001f) return 7;
    if (voice_clips[3].timestamp_ordinal == voice_clips[4].timestamp_ordinal) return 8;
    active_dub_pack = true;
    snprintf(active_pack_name, sizeof(active_pack_name), "Sample Dub Pack");
    char path1[512], path2[512];
    if (!make_active_dub_record_path(3, path1, sizeof(path1), false) ||
        !make_active_dub_record_path(4, path2, sizeof(path2), false) || strcmp(path1, path2) == 0) return 9;
    active_dub_pack = false;
    count = load_voice_clips(argv[1], false);
    if (count != 3) {
        fprintf(stderr, "expected dub_only to be filtered and timestamp arrays not duplicated in normal voice mode, got %d\n", count);
        return 10;
    }
    return 0;
}
