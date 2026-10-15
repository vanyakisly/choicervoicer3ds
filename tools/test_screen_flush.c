/* Host regression harness for the native framebuffer rotation logic. */
#define main tcv_native_program_entry
#include "../3ds_port/source/main.c"
#undef main

static u8 fb_test[400u * 240u * 3u];
static u16 fb_w = 240;
static u16 fb_h = 400;

u8 *gfxGetFramebuffer(gfxScreen_t screen, gfx3dSide_t side, u16 *width, u16 *height) {
    (void)screen; (void)side;
    if (width) *width = fb_w;
    if (height) *height = fb_h;
    return fb_test;
}

static int verify_sideways(void) {
    Canvas c = {4, 3, NULL};
    uint32_t pixels[12];
    c.pixels = pixels;
    for (int y = 0; y < c.h; ++y)
        for (int x = 0; x < c.w; ++x)
            c.pixels[y*c.w+x] = 0xFF000000u | ((uint32_t)(10+x) << 16) |
                                 ((uint32_t)(20+y) << 8) | (uint32_t)(30+x+y);
    memset(fb_test, 0xCC, sizeof(fb_test));
    fb_w = 3; fb_h = 4; /* libctru exposes 240x400 while the logical canvas is 400x240. */
    canvas_flush(&c, GFX_TOP, GFX_LEFT);
    for (int y=0; y<c.h; ++y) for (int x=0; x<c.w; ++x) {
        uint32_t col = c.pixels[y*c.w+x];
        size_t dst = ((size_t)x*fb_w+(fb_w-1-y))*3u;
        if (fb_test[dst+0] != color_b(col) || fb_test[dst+1] != color_g(col) || fb_test[dst+2] != color_r(col)) return 1;
    }
    /* Verify every byte outside the 4x3 logical canvas stays untouched. The
       old fh-stride formula wrote beyond the 12-pixel framebuffer in this test. */
    for (size_t i = (size_t)fb_w * fb_h * 3u; i < sizeof(fb_test); ++i)
        if (fb_test[i] != 0xCC) return 3;
    return 0;
}

static int verify_direct(void) {
    Canvas c = {4, 3, NULL};
    uint32_t pixels[12]; c.pixels = pixels;
    for (int i=0; i<12; ++i) c.pixels[i] = 0xFF010203u + (uint32_t)i;
    memset(fb_test, 0xCC, sizeof(fb_test));
    fb_w = 4; fb_h = 3;
    canvas_flush(&c, GFX_TOP, GFX_LEFT);
    for (int y=0; y<c.h; ++y) for (int x=0; x<c.w; ++x) {
        uint32_t col = c.pixels[y*c.w+x];
        size_t dst = ((size_t)y*fb_w+x)*3u;
        if (fb_test[dst+0] != color_b(col) || fb_test[dst+1] != color_g(col) || fb_test[dst+2] != color_r(col)) return 2;
    }
    return 0;
}

int main(void) {
    int rc = verify_sideways(); if (rc) return rc;
    rc = verify_direct(); if (rc) return rc;
    puts("PASS: framebuffer flush handles libctru's sideways framebuffer and direct-layout fallback.");
    return 0;
}
