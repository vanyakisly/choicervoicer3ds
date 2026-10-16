/* Regression harness for the native Dub Pack list/discovery code. */
#define main tcv_native_program_entry
#include "../3ds_port/source/main.c"
#undef main

static const DubPackItem *find_item(const DubPackItem *items, int count, const char *name) {
    for (int i = 0; i < count; ++i) if (strcmp(items[i].name, name) == 0) return &items[i];
    return NULL;
}

int main(int argc, char **argv) {
    if (argc < 2) return 90;
    DubPackItem items[MAX_ITEMS];
    int count = scan_dub_pack_root(argv[1], items, MAX_ITEMS);
    if (argc >= 3 && strcmp(argv[2], "--verity-fixture") == 0) {
        const DubPackItem *pack = find_item(items, count, "verity song");
        if (count != 1 || !pack || (!pack->has_ogv && !pack->has_tcv) || pack->clip_count != 46) {
            fprintf(stderr, "verity pack expected 1 OGV pack with 46 timestamped lines; got count=%d\n", count);
            for (int i = 0; i < count; ++i) fprintf(stderr, "  %s (%d lines)\n", items[i].name, items[i].clip_count);
            return 10;
        }
        if (!strstr(pack->path, "/packs_voice/verity song")) return 11;
        return 0;
    }
    if (count != 4) {
        fprintf(stderr, "expected 4 video packs including nested folder pack, got %d\n", count);
        return 1;
    }
    const DubPackItem *nested = find_item(items, count, "Collection/verity song");
    const DubPackItem *ready = find_item(items, count, "Ready Dub");
    const DubPackItem *needs = find_item(items, count, "Needs Convert");
    const DubPackItem *no_stamps = find_item(items, count, "No Timestamps");
    if (!nested || !nested->has_tcv || nested->clip_count != 2 || !strstr(nested->path, "/Collection/verity song")) return 2;
    if (!ready || !ready->has_tcv || ready->clip_count != 2) return 3;
    if (!needs || needs->has_tcv || !needs->has_ogv || needs->clip_count != 1) return 4;
    if (!no_stamps || !no_stamps->has_tcv || no_stamps->clip_count != 0) return 5;
    return 0;
}
