/* Host regression test for the optimized 2x RGB565 video blit path. */
#define main tcv_native_program_entry
#include "../3ds_port/source/main.c"
#undef main

int main(void) {
    Canvas c = {4, 4, NULL};
    uint32_t pixels[16];
    for (int i = 0; i < 16; ++i) pixels[i] = 0xFF000000u;
    c.pixels = pixels;
    uint8_t src[] = {
        0x00, 0xF8, /* red RGB565 */
        0xE0, 0x07, /* green */
        0x1F, 0x00, /* blue */
        0xFF, 0xFF  /* white */
    };
    memset(&dub_video, 0, sizeof(dub_video));
    dub_video.opened = true;
    dub_video.has_frame = true;
    dub_video.width = 2;
    dub_video.height = 2;
    dub_video.pixels = src;
    const uint32_t expected[4] = {0xFFFF0000u, 0xFF00FF00u, 0xFF0000FFu, 0xFFFFFFFFu};
    dub_video.argb_pixels = (uint32_t *)expected;
    draw_tcv_video(&c, 0, 0, 4, 4);
    for (int sy = 0; sy < 2; ++sy) for (int sx = 0; sx < 2; ++sx) {
        uint32_t want = expected[sy * 2 + sx];
        for (int yy = 0; yy < 2; ++yy) for (int xx = 0; xx < 2; ++xx) {
            if (pixels[(sy * 2 + yy) * 4 + sx * 2 + xx] != want) {
                fprintf(stderr, "2x RGB565 blit mismatch at %d,%d\n", sx * 2 + xx, sy * 2 + yy);
                return 1;
            }
        }
    }
    /* Also exercise the pre-decode RGB565 conversion fallback used by test fixtures. */
    dub_video.argb_pixels = NULL;
    for (int i = 0; i < 16; ++i) pixels[i] = 0xFF000000u;
    draw_tcv_video(&c, 0, 0, 4, 4);
    for (int sy = 0; sy < 2; ++sy) for (int sx = 0; sx < 2; ++sx) {
        uint32_t want = expected[sy * 2 + sx];
        for (int yy = 0; yy < 2; ++yy) for (int xx = 0; xx < 2; ++xx)
            if (pixels[(sy * 2 + yy) * 4 + sx * 2 + xx] != want) return 2;
    }
    puts("PASS: cached 2x video blit and RGB565 fallback both duplicate pixels correctly.");
    return 0;
}
