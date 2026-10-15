/* Regression harness for the native Dub Pack list/discovery code. */
#define main tcv_native_program_entry
#include "../3ds_port/source/main.c"
#undef main

int main(int argc, char **argv) {
    if (argc != 2) return 90;
    DubPackItem items[MAX_ITEMS];
    int count = scan_dub_pack_root(argv[1], items, MAX_ITEMS);
    if (count != 3) {
        fprintf(stderr, "expected 3 video packs, got %d\n", count);
        return 1;
    }
    if (strcmp(items[0].name, "Ready Dub") || !items[0].has_tcv || items[0].clip_count != 2 || items[0].voice_index != 2) return 2;
    if (strcmp(items[1].name, "Needs Convert") || items[1].has_tcv || !items[1].has_ogv || items[1].clip_count != 1 || items[1].voice_index != 0) return 3;
    if (strcmp(items[2].name, "No Timestamps") || !items[2].has_tcv || items[2].clip_count != 0 || items[2].voice_index != 1) return 4;
    return 0;
}
