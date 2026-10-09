/* Host regression harness for the native pack scanner. This is not a 3DS build. */
#define main tcv_native_program_entry
#include "../3ds_port/source/main.c"
#undef main

int main(int argc, char **argv) {
    if (argc != 2) return 90;
    int count = load_voice_clips(argv[1], true);
    if (count != 3) {
        fprintf(stderr, "expected 3 timestamped dub clips, got %d\n", count);
        return 1;
    }
    if (strcmp(voice_clips[0].stem, "01_A") || fabsf(voice_clips[0].timestamp - 1.25f) > 0.001f) return 2;
    if (strcmp(voice_clips[0].caption, "First line") || strcmp(voice_clips[0].characters, "Narrator")) return 3;
    if (!has_ext(voice_clips[0].path, ".3ds.wav")) return 4;
    if (strcmp(voice_clips[1].stem, "02_B") || fabsf(voice_clips[1].timestamp - 2.5f) > 0.001f) return 5;
    count = load_voice_clips(argv[1], false);
    if (count != 2) {
        fprintf(stderr, "expected dub_only to be filtered from normal voice mode, got %d\n", count);
        return 6;
    }
    return 0;
}
