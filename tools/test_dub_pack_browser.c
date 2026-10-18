/* Regression harness for the native Dub Pack list/discovery code. */
#define main tcv_native_program_entry
#include "../3ds_port/source/main.c"
#undef main

/* Keep the harness from introducing the very large local DubPackItem array
   that previously overflowed the application's small Old 3DS stack. */
static DubPackItem test_items[MAX_ITEMS];

static const DubPackItem *find_item(const DubPackItem *items, int count, const char *name) {
    for (int i = 0; i < count; ++i) if (strcmp(items[i].name, name) == 0) return &items[i];
    return NULL;
}

int main(int argc, char **argv) {
    if (argc < 2) return 90;
    if (strcmp(argv[1], "--scan-catalog") == 0) {
        int catalog_count = scan_embedded_dub_pack_catalog(test_items, MAX_ITEMS);
        const DubPackItem *embedded = find_item(test_items, catalog_count, "Embedded Pack");
        const DubPackItem *shared = find_item(test_items, catalog_count, "Shared Pack");
        if (catalog_count != 2 || !embedded || !shared || embedded->clip_count != 7 || shared->clip_count != 3 ||
            !embedded->has_tcv || !shared->has_tcv || !strstr(embedded->path, "romfs:/tcv/packs_voice")) {
            fprintf(stderr, "embedded catalog incorrect: count=%d\n", catalog_count);
            return 30;
        }
        return 0;
    }
    if (strcmp(argv[1], "--scan-all") == 0) {
        int all_count = scan_all_dub_pack_roots(test_items, MAX_ITEMS);
        const DubPackItem *user = find_item(test_items, all_count, "Collection/Nested Pack");
        const DubPackItem *legacy = find_item(test_items, all_count, "Legacy Pack");
        const DubPackItem *embedded = find_item(test_items, all_count, "Embedded Pack");
        const DubPackItem *shared = find_item(test_items, all_count, "Shared Pack");
        if (all_count != 4 || !user || !legacy || !embedded || !shared) {
            fprintf(stderr, "scan-all should find four unique packs across user/legacy/embedded roots; got %d\n", all_count);
            for (int i = 0; i < all_count; ++i) fprintf(stderr, "  %s (%s)\n", test_items[i].name, test_items[i].path);
            return 20;
        }
        /* A raw OGV on legacy SD must not hide the converted embedded duplicate. */
        if (!shared->has_tcv || !strstr(shared->path, "romfs:/tcv")) {
            fprintf(stderr, "ready embedded Shared Pack should outrank raw legacy copy; got tcv=%d path=%s\n",
                    shared->has_tcv, shared->path);
            return 21;
        }
        return 0;
    }
    int count = scan_dub_pack_root(argv[1], test_items, MAX_ITEMS);
    if (argc >= 3 && strcmp(argv[2], "--repo-packs") == 0) {
        /* The repository may contain any number of differently named packs.
           Never assert a particular title, filename, or fixed line count. */
        for (int i = 0; i < count; ++i) {
            if (!test_items[i].has_source_video && !test_items[i].has_tcv) {
                fprintf(stderr, "pack %s has no recognized video\n", test_items[i].name);
                return 10;
            }
            if (test_items[i].clip_count <= 0) {
                fprintf(stderr, "video folder %s has no timestamped line clips; it is not a playable dub pack\n", test_items[i].name);
                return 11;
            }
        }
        printf("PASS: scanned %d repository dub pack(s) with arbitrary names and line counts.\n", count);
        return 0;
    }
    if (count != 5) {
        fprintf(stderr, "expected 5 video packs including nested and alternate-container packs, got %d\n", count);
        return 1;
    }
    const DubPackItem *nested = find_item(test_items, count, "Collection/Alternate Voice Dub");
    const DubPackItem *ready = find_item(test_items, count, "Ready Dub");
    const DubPackItem *needs = find_item(test_items, count, "Needs Convert");
    const DubPackItem *alternate = find_item(test_items, count, "Alternate Video");
    const DubPackItem *no_stamps = find_item(test_items, count, "No Timestamps");
    if (!nested || !nested->has_tcv || nested->clip_count != 2 || !strstr(nested->path, "/Collection/Alternate Voice Dub")) return 2;
    if (!ready || !ready->has_tcv || ready->clip_count != 2) return 3;
    if (!needs || needs->has_tcv || !needs->has_source_video || needs->clip_count != 1) return 4;
    if (!no_stamps || !no_stamps->has_tcv || no_stamps->clip_count != 0) return 5;
    if (!alternate || alternate->has_tcv || !alternate->has_source_video || alternate->clip_count != 1) return 6;
    return 0;
}
