#ifndef STUB_3DS_H
#define STUB_3DS_H
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
typedef uint8_t u8; typedef uint16_t u16; typedef uint32_t u32; typedef uint64_t u64; typedef int16_t s16; typedef int Result; typedef int gfxScreen_t; typedef int gfx3dSide_t;
typedef struct { int px, py; } touchPosition;
typedef struct { s16 *data_pcm16; u32 nsamples; bool looping; int status; } ndspWaveBuf;
void *linearAlloc(size_t size);
void linearFree(void *ptr);
#define GFX_BOTTOM 0
#define GFX_TOP 1
#define GFX_LEFT 0
#define KEY_A (1u<<0)
#define KEY_B (1u<<1)
#define KEY_DOWN (1u<<2)
#define KEY_LEFT (1u<<3)
#define KEY_RIGHT (1u<<4)
#define KEY_START (1u<<5)
#define KEY_TOUCH (1u<<6)
#define KEY_UP (1u<<7)
#define MICU_ENCODING_PCM16_SIGNED 0
#define MICU_SAMPLE_RATE_16360 0
#define NDSP_FORMAT_MONO_PCM16 0
#define NDSP_FORMAT_STEREO_PCM16 1
#define NDSP_WBUF_DONE 2
#define NDSP_WBUF_FREE 0
#define R_FAILED(x) ((x)<0)
#define R_SUCCEEDED(x) ((x)>=0)
#endif
