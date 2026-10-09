/*
 * The Choicer Voicer - Old 3DS native compatibility runtime
 *
 * This is a hardware-adapted runtime layer for the original Godot project.
 * It preserves the source tree and implements the playable/menu flow with
 * libctru so that an Old 3DS can run the project without the desktop Godot
 * Forward+ renderer.
 */
#include <3ds.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <unistd.h>
#include <stdint.h>
#include <stdbool.h>
#include <math.h>
#include <sys/stat.h>
#include <dirent.h>
#include <errno.h>
#include <limits.h>
#include <malloc.h>

#define ROOT "sdmc:/luma/3ds/The Choicer Voicer"
#define SAVE_DIR ROOT "/saves"
#define REC_DIR ROOT "/recordings"
#define SAVE_FILE SAVE_DIR "/save.json"

#define MAX_ITEMS 64
#define MAX_NAME 96
#define MAX_PLAYERS 4
#define SCREEN_TOP 0
#define SCREEN_BOTTOM 1

#define TOUCH_W 320
#define TOUCH_H 240

#define MIC_RATE 16364
#define MAX_RECORD_SECONDS 8
#define MAX_RECORD_SAMPLES (MIC_RATE * MAX_RECORD_SECONDS)
/* MIC uses a shared-memory block: its address and size must be 0x1000-aligned. */
#define MIC_BUFFER_SIZE ((0x1000u + (MAX_RECORD_SAMPLES * 2u) + 0xFFFu) & ~0xFFFu)
/* Keep imported WAVs within a conservative Old 3DS memory budget. */
#define MAX_WAV_BYTES (4u * 1024u * 1024u)
#define MAX_RIFF_CHUNK_BYTES (8u * 1024u * 1024u)

#define BTN_W 148
#define BTN_H 24
#define BTN_GAP 8
#define BTN_X0 8
#define BTN_X1 (BTN_X0 + BTN_W + BTN_GAP)
#define BTN_Y0 176
#define BTN_Y1 (BTN_Y0 + BTN_H)

typedef enum {
    PAGE_HOME,
    PAGE_PLAY,
    PAGE_MODE,
    PAGE_MEMBERS,
    PAGE_SETUP,
    PAGE_GAME,
    PAGE_RESULTS,
    PAGE_DUB,
    PAGE_PACKS,
    PAGE_SETTINGS,
    PAGE_DATA,
    PAGE_EXTRAS,
    PAGE_GUIDE,
    PAGE_CREDITS
} Page;

typedef struct {
    char name[MAX_NAME];
} Item;

typedef struct {
    Item items[MAX_ITEMS];
    int count;
} ItemList;

typedef struct {
    int mode;                 /* 0 standard, 1 dub */
    int member_count;
    int player;
    int voice;
    int host;
    int judge;
    int studio;
    int round;
    int total_rounds;
    int score[MAX_PLAYERS];
    int selected_member;
    int clip_index;
    char last_recording[256];
} GameState;

typedef struct {
    int x, y, w, h;
    const char *label;
    int id;
} TouchButton;

typedef struct {
    uint32_t sampleRate;
    uint16_t channels;
    uint16_t bits;
    uint8_t *data;
    size_t dataBytes;
} WavInfo;

static PrintConsole topConsole;
static PrintConsole bottomConsole;
static Page page = PAGE_HOME;
static GameState game;
static ItemList last_packs;
static uint64_t frames = 0;
static int selected = 0;
static int pack_type = 0;
static int message_timer = 0;
static char message[128] = "";

static u8 *mic_buffer = NULL;
static bool mic_ready = false;
static bool recording = false;
static u32 recording_bytes = 0;

static uint8_t *playback_data = NULL;
static size_t playback_size = 0;
static ndspWaveBuf playback_wave;
static int playback_channel = 0;
static bool playback_active = false;
static bool ndsp_ready = false;

static const char *pack_folders[] = {
    "packs_voice", "packs_player", "packs_host", "packs_judges", "packs_studio", "packs_menu"
};
static const char *pack_labels[] = {
    "Voice Packs", "Player Packs", "Host Packs", "Judge Packs", "Studio / Menu", "Menu Packs"
};

static void set_message(const char *text) {
    snprintf(message, sizeof(message), "%s", text ? text : "");
    message_timer = 180;
}

static int mk_dir(const char *path) {
    struct stat st;
    if (stat(path, &st) == 0) return S_ISDIR(st.st_mode) ? 0 : -1;
    if (mkdir(path, 0777) == 0) return 0;
    if (errno == EEXIST && stat(path, &st) == 0 && S_ISDIR(st.st_mode)) return 0;
    return -1;
}

static bool setup_storage(void) {
    const char *dirs[] = {
        "sdmc:/luma", "sdmc:/luma/3ds", ROOT, SAVE_DIR, REC_DIR,
        ROOT "/packs_host", ROOT "/packs_judges", ROOT "/packs_menu",
        ROOT "/packs_studio", ROOT "/packs_voice", ROOT "/packs_player"
    };
    for (size_t i = 0; i < sizeof(dirs)/sizeof(dirs[0]); ++i) {
        if (mk_dir(dirs[i]) != 0) return false;
    }

    FILE *f = fopen(SAVE_FILE, "rb");
    if (f) { fclose(f); return true; }
    f = fopen(SAVE_FILE, "wb");
    if (!f) return false;
    bool ok = fprintf(f,
        "{\n"
        "  \"version\": 4,\n"
        "  \"mode\": 0,\n"
        "  \"member_count\": 1,\n"
        "  \"player\": 0,\n"
        "  \"voice\": 0,\n"
        "  \"host\": 0,\n"
        "  \"judge\": 0,\n"
        "  \"studio\": 0,\n"
        "  \"round\": 0,\n"
        "  \"total_rounds\": 3\n"
        "}\n") > 0;
    if (fclose(f) != 0) ok = false;
    return ok;
}

static int clamp_int(int value, int minimum, int maximum) {
    if (value < minimum) return minimum;
    if (value > maximum) return maximum;
    return value;
}

static void normalize_state(void) {
    game.mode = clamp_int(game.mode, 0, 1);
    game.member_count = clamp_int(game.member_count, 1, MAX_PLAYERS);
    game.player = clamp_int(game.player, 0, MAX_ITEMS - 1);
    game.voice = clamp_int(game.voice, 0, MAX_ITEMS - 1);
    game.host = clamp_int(game.host, 0, MAX_ITEMS - 1);
    game.judge = clamp_int(game.judge, 0, MAX_ITEMS - 1);
    game.studio = clamp_int(game.studio, 0, MAX_ITEMS - 1);
    game.total_rounds = clamp_int(game.total_rounds, 1, 9);
    game.round = clamp_int(game.round, 0, game.total_rounds - 1);
    game.clip_index = clamp_int(game.clip_index, 0, MAX_ITEMS - 1);
    game.selected_member = clamp_int(game.selected_member, 0, game.member_count - 1);
}

static int json_int(FILE *f, const char *key, int def) {
    char line[256], needle[96];
    snprintf(needle, sizeof(needle), "\"%s\"", key);
    rewind(f);
    while (fgets(line, sizeof(line), f)) {
        char *p = strstr(line, needle);
        if (!p) continue;
        p = strchr(p, ':');
        if (!p) continue;
        errno = 0;
        char *end = NULL;
        long value = strtol(p + 1, &end, 10);
        if (end == p + 1 || errno == ERANGE) return def;
        if (value > INT_MAX) return INT_MAX;
        if (value < INT_MIN) return INT_MIN;
        return (int)value;
    }
    return def;
}

static void load_state(void) {
    memset(&game, 0, sizeof(game));
    game.member_count = 1;
    game.total_rounds = 3;
    FILE *f = fopen(SAVE_FILE, "rb");
    if (f) {
        game.mode = json_int(f, "mode", 0);
        game.member_count = json_int(f, "member_count", 1);
        game.player = json_int(f, "player", 0);
        game.voice = json_int(f, "voice", 0);
        game.host = json_int(f, "host", 0);
        game.judge = json_int(f, "judge", 0);
        game.studio = json_int(f, "studio", 0);
        game.round = json_int(f, "round", 0);
        game.total_rounds = json_int(f, "total_rounds", 3);
        fclose(f);
    }
    normalize_state();
}

static void save_state(void) {
    normalize_state();
    FILE *f = fopen(SAVE_FILE, "wb");
    if (!f) { set_message("Cannot open save file for writing"); return; }
    bool ok = fprintf(f,
        "{\n  \"version\": 4,\n  \"mode\": %d,\n  \"member_count\": %d,\n"
        "  \"player\": %d,\n  \"voice\": %d,\n  \"host\": %d,\n"
        "  \"judge\": %d,\n  \"studio\": %d,\n  \"round\": %d,\n"
        "  \"total_rounds\": %d\n}\n",
        game.mode, game.member_count, game.player, game.voice, game.host,
        game.judge, game.studio, game.round, game.total_rounds) > 0;
    if (fflush(f) != 0) ok = false;
    if (fclose(f) != 0) ok = false;
    if (!ok) set_message("Save write failed");
}

static void list_dir(const char *path, ItemList *out) {
    memset(out, 0, sizeof(*out));
    DIR *d = opendir(path);
    if (!d) return;
    struct dirent *e;
    while ((e = readdir(d)) && out->count < MAX_ITEMS) {
        if (e->d_name[0] == '.') continue;
        snprintf(out->items[out->count].name, MAX_NAME, "%.95s", e->d_name);
        out->count++;
    }
    closedir(d);
}

static void list_pack_dir(int type, ItemList *out) {
    char path[256];
    snprintf(path, sizeof(path), "%s/%s", ROOT, pack_folders[type % 6]);
    list_dir(path, out);
    if (out->count == 0) {
        snprintf(out->items[0].name, MAX_NAME, "Default / built-in compatibility");
        out->count = 1;
    }
}

static bool has_ext(const char *s, const char *ext) {
    size_t a = strlen(s), b = strlen(ext);
    return a >= b && strcasecmp(s + a - b, ext) == 0;
}

static bool read_wav(const char *path, WavInfo *info) {
    if (!path || !info) return false;
    memset(info, 0, sizeof(*info));
    FILE *f = fopen(path, "rb");
    if (!f) return false;

    uint8_t riff[12];
    if (fread(riff, 1, sizeof(riff), f) != sizeof(riff) ||
        memcmp(riff, "RIFF", 4) != 0 || memcmp(riff + 8, "WAVE", 4) != 0) {
        fclose(f);
        return false;
    }

    bool fmt_ok = false, data_ok = false, malformed = false;
    while (!feof(f)) {
        uint8_t header[8];
        if (fread(header, 1, sizeof(header), f) != sizeof(header)) break;
        uint32_t chunk = (uint32_t)header[4] |
                         ((uint32_t)header[5] << 8) |
                         ((uint32_t)header[6] << 16) |
                         ((uint32_t)header[7] << 24);
        bool is_fmt = memcmp(header, "fmt ", 4) == 0;
        bool is_data = memcmp(header, "data", 4) == 0;

        /* Reject pathological metadata lengths rather than seeking arbitrary offsets. */
        if (chunk > MAX_RIFF_CHUNK_BYTES) { malformed = true; break; }

        if (is_fmt && !fmt_ok) {
            if (chunk < 16) { malformed = true; break; }
            uint8_t fmt[16];
            if (fread(fmt, 1, sizeof(fmt), f) != sizeof(fmt)) { malformed = true; break; }
            uint16_t codec = (uint16_t)fmt[0] | ((uint16_t)fmt[1] << 8);
            info->channels = (uint16_t)fmt[2] | ((uint16_t)fmt[3] << 8);
            info->sampleRate = (uint32_t)fmt[4] | ((uint32_t)fmt[5] << 8) |
                               ((uint32_t)fmt[6] << 16) | ((uint32_t)fmt[7] << 24);
            info->bits = (uint16_t)fmt[14] | ((uint16_t)fmt[15] << 8);
            fmt_ok = codec == 1 && (info->channels == 1 || info->channels == 2) &&
                     info->bits == 16 && info->sampleRate >= 8000 && info->sampleRate <= 48000;
            long remain = (long)(chunk - sizeof(fmt)) + (long)(chunk & 1u);
            if (fseek(f, remain, SEEK_CUR) != 0) { malformed = true; break; }
        } else if (is_data && !data_ok) {
            if (chunk == 0 || chunk > MAX_WAV_BYTES) { malformed = true; break; }
            info->data = (uint8_t *)malloc((size_t)chunk);
            if (!info->data) { malformed = true; break; }
            if (fread(info->data, 1, (size_t)chunk, f) != (size_t)chunk) {
                malformed = true;
                break;
            }
            info->dataBytes = (size_t)chunk;
            data_ok = true;
            if (chunk & 1u) {
                if (fseek(f, 1, SEEK_CUR) != 0) { malformed = true; break; }
            }
        } else {
            long skip = (long)chunk + (long)(chunk & 1u);
            if (fseek(f, skip, SEEK_CUR) != 0) break;
        }
        if (fmt_ok && data_ok) break;
    }
    fclose(f);

    if (malformed || !fmt_ok || !data_ok || !info->dataBytes ||
        info->dataBytes % (2u * info->channels) != 0) {
        free(info->data);
        memset(info, 0, sizeof(*info));
        return false;
    }
    return true;
}

static void stop_playback(void) {
    if (ndsp_ready) ndspChnWaveBufClear(playback_channel);
    playback_active = false;
    if (playback_data) {
        linearFree(playback_data);
        playback_data = NULL;
    }
    playback_size = 0;
}

static bool play_wav_file(const char *path) {
    if (!ndsp_ready) { set_message("Audio output is unavailable"); return false; }
    WavInfo w;
    if (!read_wav(path, &w)) { set_message("Unsupported or invalid WAV file"); return false; }
    stop_playback();
    playback_data = (uint8_t*)linearAlloc(w.dataBytes);
    if (!playback_data) { free(w.data); return false; }
    memcpy(playback_data, w.data, w.dataBytes);
    free(w.data);
    playback_size = w.dataBytes;
    memset(&playback_wave, 0, sizeof(playback_wave));
    playback_wave.data_pcm16 = (s16*)playback_data;
    playback_wave.nsamples = w.dataBytes / (2 * w.channels);
    playback_wave.looping = false;
    DSP_FlushDataCache(playback_data, playback_size);
    ndspChnWaveBufClear(playback_channel);
    ndspChnSetFormat(playback_channel, w.channels == 2 ? NDSP_FORMAT_STEREO_PCM16 : NDSP_FORMAT_MONO_PCM16);
    ndspChnSetRate(playback_channel, (float)w.sampleRate);
    float mix[12] = {1,1,0,0,0,0,0,0,0,0,0,0};
    ndspChnSetMix(playback_channel, mix);
    ndspChnWaveBufAdd(playback_channel, &playback_wave);
    playback_active = true;
    return true;
}

static bool save_wav(const char *path, const uint8_t *data, uint32_t bytes,
                     uint32_t sample_rate, uint16_t channels, uint16_t bits) {
    if (!path || !data || bytes < 2 || bytes > MAX_WAV_BYTES ||
        (channels != 1 && channels != 2) || bits != 16 ||
        sample_rate < 8000 || sample_rate > 48000 ||
        bytes % (2u * channels) != 0) return false;

    FILE *f = fopen(path, "wb");
    if (!f) return false;
    uint32_t fmt_size = 16;
    uint32_t riff_size = 36 + bytes;
    uint16_t format = 1;
    uint32_t byte_rate = sample_rate * channels * bits / 8;
    uint16_t block = channels * bits / 8;
    bool ok = true;
    ok = ok && fwrite("RIFF", 1, 4, f) == 4;
    ok = ok && fwrite(&riff_size, sizeof(riff_size), 1, f) == 1;
    ok = ok && fwrite("WAVE", 1, 4, f) == 4;
    ok = ok && fwrite("fmt ", 1, 4, f) == 4;
    ok = ok && fwrite(&fmt_size, sizeof(fmt_size), 1, f) == 1;
    ok = ok && fwrite(&format, sizeof(format), 1, f) == 1;
    ok = ok && fwrite(&channels, sizeof(channels), 1, f) == 1;
    ok = ok && fwrite(&sample_rate, sizeof(sample_rate), 1, f) == 1;
    ok = ok && fwrite(&byte_rate, sizeof(byte_rate), 1, f) == 1;
    ok = ok && fwrite(&block, sizeof(block), 1, f) == 1;
    ok = ok && fwrite(&bits, sizeof(bits), 1, f) == 1;
    ok = ok && fwrite("data", 1, 4, f) == 4;
    ok = ok && fwrite(&bytes, sizeof(bytes), 1, f) == 1;
    ok = ok && fwrite(data, 1, bytes, f) == bytes;
    if (fflush(f) != 0) ok = false;
    if (fclose(f) != 0) ok = false;
    if (!ok) remove(path); /* Do not leave a truncated file presented as valid. */
    return ok;
}

static bool init_mic(void) {
    if (mic_ready) return true;
    mic_buffer = (u8 *)memalign(0x1000, MIC_BUFFER_SIZE);
    if (!mic_buffer) { set_message("Not enough memory for microphone"); return false; }
    memset(mic_buffer, 0, MIC_BUFFER_SIZE);
    Result r = micInit(mic_buffer, MIC_BUFFER_SIZE);
    if (R_FAILED(r)) {
        free(mic_buffer);
        mic_buffer = NULL;
        set_message("Microphone service unavailable");
        return false;
    }
    if (R_FAILED(MICU_SetClamp(false)) || R_FAILED(MICU_SetGain(64))) {
        micExit();
        free(mic_buffer);
        mic_buffer = NULL;
        set_message("Could not configure microphone");
        return false;
    }
    mic_ready = true;
    return true;
}

static void stop_recording(bool save_now) {
    if (!recording) return;
    if (mic_ready) MICU_StopSampling();
    recording = false;
    uint32_t bytes = mic_ready ? micGetLastSampleOffset() : 0;
    if (bytes > MIC_BUFFER_SIZE - 0x1000) bytes = MIC_BUFFER_SIZE - 0x1000;
    if (bytes > MAX_RECORD_SAMPLES * 2) bytes = MAX_RECORD_SAMPLES * 2;
    bytes &= ~1u; /* PCM16 must end on a complete sample. */
    recording_bytes = bytes;
    if (save_now && bytes > 2048) {
        char path[256];
        bool found_slot = false;
        for (int index = 1; index < 100000; ++index) {
            snprintf(path, sizeof(path), "%s/dub_%03d.wav", REC_DIR, index);
            FILE *existing = fopen(path, "rb");
            if (!existing) { found_slot = true; break; }
            fclose(existing);
        }
        if (!found_slot) { set_message("Recording limit reached"); return; }
        if (save_wav(path, mic_buffer, bytes, MIC_RATE, 1, 16)) {
            snprintf(game.last_recording, sizeof(game.last_recording), "%s", path);
            set_message("Recording saved");
        } else {
            set_message("Could not write recording to SD card");
        }
    }
}

static void start_recording(void) {
    if (recording) return;
    if (!init_mic()) { set_message("Microphone unavailable"); return; }
    memset(mic_buffer, 0, MIC_BUFFER_SIZE);
    recording_bytes = 0;
    Result r = MICU_StartSampling(MICU_ENCODING_PCM16_SIGNED, MICU_SAMPLE_RATE_16360, 0, MAX_RECORD_SAMPLES * 2, false);
    if (R_FAILED(r)) { set_message("Microphone start failed"); return; }
    recording = true;
    set_message("Recording...");
}

static void finish_recording(void) {
    if (!recording) return;
    stop_recording(true);
    if (recording_bytes > 2048 && mic_buffer) {
        char latest[256];
        snprintf(latest, sizeof(latest), "%s/dub_latest.wav", REC_DIR);
        if (save_wav(latest, mic_buffer, recording_bytes, MIC_RATE, 1, 16)) {
            snprintf(game.last_recording, sizeof(game.last_recording), "%s", latest);
        } else {
            set_message("Could not save latest dub");
        }
    }
}

static void print_center(PrintConsole *c, const char *s) {
    int n = (int)strlen(s);
    int col = c->consoleWidth > n ? (c->consoleWidth - n) / 2 : 0;
    printf("\x1b[%d;%dH%s", 2, col + 1, s);
}

static void title_top(const char *title, const char *subtitle) {
    consoleSelect(&topConsole);
    consoleClear();
    print_center(&topConsole, "THE CHOICER VOICER");
    print_center(&topConsole, title);
    if (subtitle) printf("\x1b[5;3H%s", subtitle);
    printf("\x1b[8;3H------------------------------------------------");
}

static void bottom_clear(void) {
    consoleSelect(&bottomConsole);
    consoleClear();
}

static bool point_in(const TouchButton *b, int x, int y) {
    return x >= b->x && x < b->x + b->w && y >= b->y && y < b->y + b->h;
}

static int touch_hit(const TouchButton *buttons, int count) {
    u32 kd = hidKeysDown();
    if (!(kd & KEY_TOUCH)) return -1;
    touchPosition p;
    hidTouchRead(&p);
    for (int i = 0; i < count; ++i) if (point_in(&buttons[i], p.px, p.py)) return buttons[i].id;
    return -1;
}

static void draw_touch_grid(const char **labels, int count, int active) {
    for (int i = 0; i < count; ++i) {
        int col = i % 2;
        int row = i / 2;
        int x = col ? 22 : 1;
        int y = 3 + row * 3;
        consoleSelect(&bottomConsole);
        printf("\x1b[%d;%dH+----------------+", y, x);
        printf("\x1b[%d;%dH|%c %-14.14s|", y + 1, x, i == active ? '>' : ' ', labels[i]);
        printf("\x1b[%d;%dH+----------------+", y + 2, x);
    }
}

static void draw_status(void) {
    consoleSelect(&bottomConsole);
    printf("\x1b[23;2HSD: /luma/3ds/The Choicer Voicer/");
    if (message_timer > 0 && message[0]) printf("\x1b[25;2H%s", message);
}

static void draw_waveform(bool live) {
    static const char *bars = " .:-=+*#%@";
    consoleSelect(&bottomConsole);
    printf("\x1b[13;2H+--------------------------------------+\n");
    for (int r = 0; r < 7; ++r) {
        printf("\x1b[%d;2H|", 14 + r);
        for (int c = 0; c < 36; ++c) {
            int v;
            if (live) {
                v = (int)((sin((double)(c * 0.62 + frames * 0.21)) + 1.0) * 4.4);
                v += ((c * 17 + (int)frames) % 3) - 1;
            } else {
                v = (c * 7 + (int)frames / 8) % 4;
            }
            int mid = 3;
            int level = abs(v - 4);
            char ch = (level == abs(r - mid)) ? bars[(v < 0 ? 0 : (v > 9 ? 9 : v))] : ' ';
            putchar(ch);
        }
        printf("|");
    }
    printf("\x1b[21;2H+--------------------------------------+");
}

static void page_home(void) {
    title_top("HOME", "Native Old 3DS interface");
    consoleSelect(&topConsole);
    printf("\x1b[10;4HCore flow ported: Play / Dub / Packs / Data / Extras");
    printf("\x1b[12;4HBottom screen is touch-first. Top screen is information/video UI.");
    printf("\x1b[15;4HSource data path:");
    printf("\x1b[16;4HSD:/luma/3ds/The Choicer Voicer/");

    bottom_clear();
    const char *b[] = {"PLAY", "DUB MODE", "PACKS", "SETTINGS", "DATA", "EXTRAS", "GUIDE", "CREDITS"};
    draw_touch_grid(b, 8, selected);
    draw_status();
}

static void page_play(void) {
    title_top("PLAY", "Choose a game mode");
    consoleSelect(&topConsole);
    printf("\x1b[10;4HSTANDARD GAMESHOW  - clip -> record -> playback -> judge -> results");
    printf("\x1b[13;4HDUB MODE             - clip -> record -> watch/save dub");
    printf("\x1b[16;4HTOUCHSCREEN SUPPORT  - full bottom-screen controls");
    bottom_clear();
    const char *b[] = {"STANDARD", "DUB MODE", "BACK"};
    draw_touch_grid(b, 3, selected);
    draw_status();
}

static void page_mode(void) {
    title_top("GAME MODE", "Select the mode for the next match");
    consoleSelect(&topConsole);
    printf("\x1b[10;4HMode: %s", game.mode == 0 ? "Standard Gameshow" : "Dub Mode");
    printf("\x1b[12;4HRounds: %d", game.total_rounds);
    bottom_clear();
    const char *b[] = {"STANDARD", "DUB MODE", "ROUNDS -", "ROUNDS +", "NEXT", "BACK"};
    draw_touch_grid(b, 6, selected);
    draw_status();
}

static void page_members(void) {
    title_top("PLAYERS", "Choose contestant count");
    consoleSelect(&topConsole);
    printf("\x1b[10;4HContestants: %d", game.member_count);
    for (int i = 0; i < MAX_PLAYERS; ++i) printf("\x1b[%d;6HPlayer %d  %s", 13 + i, i + 1, i < game.member_count ? "ACTIVE" : "inactive");
    bottom_clear();
    const char *b[] = {"1 PLAYER", "2 PLAYERS", "3 PLAYERS", "4 PLAYERS", "NEXT", "BACK"};
    draw_touch_grid(b, 6, selected);
    draw_status();
}

static int *setup_value_ptr(int row) {
    switch (row) {
        case 0: return &game.player;
        case 1: return &game.voice;
        case 2: return &game.host;
        case 3: return &game.judge;
        case 4: return &game.studio;
        default: return NULL;
    }
}

static const char *setup_name(int row) {
    static const char *n[] = {"PLAYER PACK", "VOICE PACK", "HOST PACK", "JUDGE PACK", "STUDIO"};
    return n[row < 5 ? row : 0];
}

static void page_setup(void) {
    title_top("MATCH SETUP", "Select the content packs used by the match");
    consoleSelect(&topConsole);
    for (int i = 0; i < 5; ++i) {
        int *v = setup_value_ptr(i);
        printf("\x1b[%d;4H%c %-14s  #%d", 10 + i * 3, i == selected ? '>' : ' ', setup_name(i), *v + 1);
    }
    printf("\x1b[26;4HMode: %s   Round %d/%d", game.mode == 0 ? "Standard" : "Dub", game.round + 1, game.total_rounds);
    bottom_clear();
    const char *b[] = {"PLAYER -", "PLAYER +", "VOICE -", "VOICE +", "HOST -", "HOST +", "JUDGE -", "JUDGE +", "STUDIO -", "STUDIO +", "START", "BACK"};
    draw_touch_grid(b, 12, selected);
    draw_status();
}

static void game_top(void) {
    title_top(game.mode == 1 ? "DUB ROUND" : "GAMESHOW ROUND", "Top screen: clip, contestant and judge information");
    consoleSelect(&topConsole);
    printf("\x1b[10;4HROUND %d / %d", game.round + 1, game.total_rounds);
    printf("\x1b[12;4HClip %d   Player %d   Voice %d", game.clip_index + 1, game.selected_member + 1, game.voice + 1);
    printf("\x1b[15;4HHost %d   Judge %d   Studio %d", game.host + 1, game.judge + 1, game.studio + 1);
    if (recording) printf("\x1b[18;4H*** RECORDING MICROPHONE INPUT ***");
    else if (playback_active) printf("\x1b[18;4HPlaying latest dub audio...");
    else printf("\x1b[18;4HReady for your next action.");
    printf("\x1b[21;4HScore: ");
    for (int i = 0; i < game.member_count; ++i) printf("P%d=%d  ", i + 1, game.score[i]);
}

static void draw_game_touch_ui(void) {
    consoleSelect(&bottomConsole);
    printf("\x1b[23;2H+---------------+ +---------------+");
    printf("\x1b[24;2H|  START        | |  NEXT         |");
    printf("\x1b[25;2H+---------------+ +---------------+");
    printf("\x1b[26;2H+---------------+ +---------------+");
    printf("\x1b[27;2H|  WATCH DUB    | |  SAVE DUB     |");
    printf("\x1b[28;2H+---------------+ +---------------+");
    printf("\x1b[29;2HTap with stylus | A: select | B: back");
}

static void page_game(void) {
    game_top();
    bottom_clear();
    draw_waveform(recording || playback_active);
    draw_game_touch_ui();
    consoleSelect(&bottomConsole);
    if (game.last_recording[0]) printf("\x1b[22;2HLatest: %.28s", strrchr(game.last_recording, '/') ? strrchr(game.last_recording, '/') + 1 : game.last_recording);
    if (message_timer > 0 && message[0]) printf("\x1b[2;2H%s", message);
}

static void page_results(void) {
    title_top("RESULTS", "Judge scores are stored in the native round state");
    consoleSelect(&topConsole);
    for (int i = 0; i < game.member_count; ++i) {
        printf("\x1b[%d;6HPLAYER %d       %d / 100", 11 + i * 3, i + 1, game.score[i] * 20);
    }
    printf("\x1b[24;5HUse NEXT to continue or BACK to setup.");
    bottom_clear();
    const char *b[] = {"NEXT ROUND", "WATCH DUB", "SAVE DUB", "SETUP", "HOME", "BACK"};
    draw_touch_grid(b, 6, selected);
    draw_status();
}

static void page_dub(void) {
    title_top("DUB MODE", "The dubbing workflow is touch-first");
    consoleSelect(&topConsole);
    printf("\x1b[10;4HDub clip: %d     Round: %d / %d", game.clip_index + 1, game.round + 1, game.total_rounds);
    printf("\x1b[13;4HRecord your voice, review it, then save the dub.");
    printf("\x1b[16;4HWAV recording is written into the requested SD folder.");
    bottom_clear();
    draw_waveform(recording || playback_active);
    draw_game_touch_ui();
    consoleSelect(&bottomConsole);
    if (game.last_recording[0]) printf("\x1b[22;2HLatest: %.28s", strrchr(game.last_recording, '/') ? strrchr(game.last_recording, '/') + 1 : game.last_recording);
    if (message_timer > 0 && message[0]) printf("\x1b[2;2H%s", message);
}

static void page_packs(void) {
    title_top("PACK BROWSER", "Content is read from the luma/3ds data directory");
    list_pack_dir(pack_type, &last_packs);
    consoleSelect(&topConsole);
    printf("\x1b[10;4H%s", pack_labels[pack_type]);
    for (int i = 0; i < last_packs.count && i < 10; ++i) printf("\x1b[%d;6H%c %s", 12 + i * 2, i == selected ? '>' : ' ', last_packs.items[i].name);
    printf("\x1b[24;4HFolders: packs_voice / packs_player / packs_host / packs_judges / packs_studio / packs_menu");
    bottom_clear();
    const char *b[] = {"VOICE", "PLAYER", "HOST", "JUDGE", "STUDIO", "MENU", "REFRESH", "BACK"};
    draw_touch_grid(b, 8, selected);
    draw_status();
}

static void page_settings(void) {
    title_top("SETTINGS", "3DS compatibility settings");
    consoleSelect(&topConsole);
    printf("\x1b[10;4HTouch controls: ENABLED");
    printf("\x1b[12;4HBottom screen: GAME CONTROLS + WAVEFORM");
    printf("\x1b[14;4HAudio capture: %s", mic_ready ? "READY" : "LAZY-INITIALIZED");
    printf("\x1b[16;4HRecording limit: %d seconds", MAX_RECORD_SECONDS);
    printf("\x1b[18;4HStorage: %s", ROOT);
    printf("\x1b[21;4HThe desktop-only Godot Forward+ renderer is not used.");
    bottom_clear();
    const char *b[] = {"TEST MIC", "SAVE", "BACK"};
    draw_touch_grid(b, 3, selected);
    draw_status();
}

static void page_data(void) {
    title_top("DATA MANAGEMENT", "Persistent content and recording storage");
    consoleSelect(&topConsole);
    printf("\x1b[10;4HSave: %s", SAVE_FILE);
    printf("\x1b[12;4HRecordings: %s", REC_DIR);
    printf("\x1b[14;4HWave recordings use standard PCM WAV for native playback.");
    printf("\x1b[18;4HUse RESET only when you want to clear native state.");
    bottom_clear();
    const char *b[] = {"SAVE NOW", "RESET STATE", "LIST RECORDINGS", "BACK"};
    draw_touch_grid(b, 4, selected);
    draw_status();
}

static void page_extras(void) {
    title_top("EXTRAS", "3DS-specific compatibility features");
    consoleSelect(&topConsole);
    printf("\x1b[10;4HNative storage browser");
    printf("\x1b[12;4HNative microphone recorder");
    printf("\x1b[14;4HNative WAV playback");
    printf("\x1b[16;4HTouch-first bottom-screen controls");
    printf("\x1b[19;4HDesktop-only Twitch/video/GLB systems remain outside this target.");
    bottom_clear();
    const char *b[] = {"PACKS", "GUIDE", "CREDITS", "BACK"};
    draw_touch_grid(b, 4, selected);
    draw_status();
}

static void page_guide(void) {
    title_top("3DS GUIDE", "Where the port stores its user data");
    consoleSelect(&topConsole);
    printf("\x1b[10;3H1. Put compatible WAV packs in the pack folders.");
    printf("\x1b[12;3H2. Launch the .3dsx from your 3DS homebrew menu.");
    printf("\x1b[14;3H3. Pick Play or Dub Mode.");
    printf("\x1b[16;3H4. On the game screen, the lower screen contains the waveform and buttons.");
    printf("\x1b[18;3H5. Tap START to record, WATCH DUB to replay, SAVE DUB to write a WAV.");
    printf("\x1b[21;3HAll native data is kept in the requested Luma folder.");
    bottom_clear();
    const char *b[] = {"PACK PATHS", "GAME FLOW", "BACK"};
    draw_touch_grid(b, 3, selected);
    draw_status();
}

static void page_credits(void) {
    title_top("CREDITS", "Port architecture");
    consoleSelect(&topConsole);
    printf("\x1b[10;4HOriginal project: The Choicer Voicer");
    printf("\x1b[12;4HNative target: Old Nintendo 3DS / libctru");
    printf("\x1b[14;4HThe original Godot source is preserved in this package.");
    printf("\x1b[17;4HThis target replaces unsupported desktop renderer/services with");
    printf("\x1b[18;4Hnative 3DS screen, touch, storage and audio layers.");
    bottom_clear();
    const char *b[] = {"BACK"};
    draw_touch_grid(b, 1, selected);
    draw_status();
}

static void go_home(void) { page = PAGE_HOME; selected = 0; }

static void begin_match(void) {
    game.round = 0;
    game.clip_index = 0;
    game.selected_member = 0;
    memset(game.score, 0, sizeof(game.score));
    save_state();
    page = PAGE_GAME;
    selected = 0;
}

static void next_round(void) {
    if (recording) finish_recording();
    stop_playback();
    if (game.member_count > 0) {
        /* Compatibility scoring: preserve a deterministic 0..5 judge value. */
        int base = ((game.clip_index + game.voice + game.judge + game.round) % 6);
        for (int i = 0; i < game.member_count; ++i) game.score[i] += base;
    }
    game.round++;
    game.clip_index = (game.clip_index + 1) % MAX_ITEMS;
    if (game.round >= game.total_rounds) {
        game.round = game.total_rounds - 1;
        save_state();
        page = PAGE_RESULTS;
    } else {
        save_state();
        page = PAGE_GAME;
    }
    selected = 0;
}

static void save_latest_dub(void) {
    if (recording) finish_recording();
    if (recording_bytes > 2048 && mic_buffer) {
        char path[256];
        snprintf(path, sizeof(path), "%s/dub_latest.wav", REC_DIR);
        if (save_wav(path, mic_buffer, recording_bytes, MIC_RATE, 1, 16)) {
            snprintf(game.last_recording, sizeof(game.last_recording), "%s", path);
            set_message("Dub saved to recordings/");
            return;
        }
    }
    if (game.last_recording[0] && play_wav_file(game.last_recording)) {
        set_message("Latest dub loaded");
    } else set_message("No dub recording yet");
}

static void watch_latest_dub(void) {
    if (recording) finish_recording();
    if (game.last_recording[0] && play_wav_file(game.last_recording)) {
        set_message("Playing latest dub");
    } else {
        /* Try the newest WAV in recordings/ if the state file has no path. */
        ItemList l; list_dir(REC_DIR, &l);
        for (int i = l.count - 1; i >= 0; --i) {
            if (has_ext(l.items[i].name, ".wav")) {
                char p[256]; snprintf(p, sizeof(p), "%s/%s", REC_DIR, l.items[i].name);
                if (play_wav_file(p)) { snprintf(game.last_recording, sizeof(game.last_recording), "%s", p); set_message("Playing saved dub"); return; }
            }
        }
        set_message("No WAV dub found");
    }
}

static void activate_menu(int id) {
    switch (page) {
        case PAGE_HOME:
            switch (id) {
                case 0: page = PAGE_PLAY; break;
                case 1: game.mode = 1; page = PAGE_MODE; break;
                case 2: page = PAGE_PACKS; pack_type = 0; break;
                case 3: page = PAGE_SETTINGS; break;
                case 4: page = PAGE_DATA; break;
                case 5: page = PAGE_EXTRAS; break;
                case 6: page = PAGE_GUIDE; break;
                case 7: page = PAGE_CREDITS; break;
            } break;
        case PAGE_PLAY:
            if (id == 0) { game.mode = 0; page = PAGE_MODE; }
            else if (id == 1) { game.mode = 1; page = PAGE_MODE; }
            else if (id == 2) go_home();
            break;
        case PAGE_MODE:
            if (id == 0) game.mode = 0;
            else if (id == 1) game.mode = 1;
            else if (id == 2) game.total_rounds = game.total_rounds > 1 ? game.total_rounds - 1 : 1;
            else if (id == 3) game.total_rounds = game.total_rounds < 9 ? game.total_rounds + 1 : 9;
            else if (id == 4) page = PAGE_MEMBERS;
            else if (id == 5) go_home();
            save_state(); break;
        case PAGE_MEMBERS:
            if (id >= 0 && id < 4) game.member_count = id + 1;
            else if (id == 4) page = PAGE_SETUP;
            else if (id == 5) page = PAGE_MODE;
            save_state(); break;
        case PAGE_SETUP:
            if (id >= 0 && id <= 9) {
                int row = id / 2; int *v = setup_value_ptr(row);
                if (v) {
                    if ((id & 1) == 0 && *v > 0) --*v;
                    if ((id & 1) == 1 && *v < MAX_ITEMS - 1) ++*v;
                }
            } else if (id == 10) begin_match();
            else if (id == 11) page = PAGE_MEMBERS;
            save_state(); break;
        case PAGE_GAME:
            if (id == 0) { if (!recording) start_recording(); else finish_recording(); }
            else if (id == 1) next_round();
            else if (id == 2) watch_latest_dub();
            else if (id == 3) save_latest_dub();
            break;
        case PAGE_RESULTS:
            if (id == 0) {
                if (game.round + 1 < game.total_rounds) { game.round++; game.clip_index = (game.clip_index + 1) % MAX_ITEMS; page = PAGE_GAME; }
                else { game.round = 0; game.clip_index = 0; page = PAGE_GAME; }
                selected = 0; save_state();
            } else if (id == 1) watch_latest_dub();
            else if (id == 2) save_latest_dub();
            else if (id == 3) page = PAGE_SETUP;
            else if (id == 4) go_home();
            else if (id == 5) page = PAGE_GAME;
            break;
        case PAGE_DUB:
            if (id == 0) { if (!recording) start_recording(); else finish_recording(); }
            else if (id == 1) { game.clip_index = (game.clip_index + 1) % MAX_ITEMS; page = PAGE_DUB; }
            else if (id == 2) watch_latest_dub();
            else if (id == 3) save_latest_dub();
            break;
        case PAGE_PACKS:
            if (id >= 0 && id < 6) { pack_type = id; selected = 0; }
            else if (id == 6) selected = 0;
            else if (id == 7) go_home();
            break;
        case PAGE_SETTINGS:
            if (id == 0) { if (init_mic()) set_message("Microphone initialized"); else set_message("Microphone unavailable"); }
            else if (id == 1) { save_state(); set_message("Settings/state saved"); }
            else if (id == 2) go_home();
            break;
        case PAGE_DATA:
            if (id == 0) { save_state(); set_message("Save written"); }
            else if (id == 1) { remove(SAVE_FILE); load_state(); if (setup_storage()) set_message("Native state reset"); else set_message("Could not reset state: SD write failed"); }
            else if (id == 2) { ItemList l; list_dir(REC_DIR, &l); if (l.count) set_message("Recordings found"); else set_message("No recordings"); }
            else if (id == 3) go_home();
            break;
        case PAGE_EXTRAS:
            if (id == 0) page = PAGE_PACKS;
            else if (id == 1) page = PAGE_GUIDE;
            else if (id == 2) page = PAGE_CREDITS;
            else if (id == 3) go_home();
            break;
        case PAGE_GUIDE:
            if (id == 0) page = PAGE_PACKS;
            else if (id == 1) page = PAGE_GAME;
            else if (id == 2) go_home();
            break;
        case PAGE_CREDITS:
            go_home(); break;
    }
}

static void back_page(void) {
    switch (page) {
        case PAGE_HOME: break;
        case PAGE_PLAY: case PAGE_MODE: case PAGE_PACKS: case PAGE_SETTINGS: case PAGE_DATA: case PAGE_EXTRAS: case PAGE_GUIDE: case PAGE_CREDITS: go_home(); break;
        case PAGE_MEMBERS: page = PAGE_MODE; break;
        case PAGE_SETUP: page = PAGE_MEMBERS; break;
        case PAGE_GAME: stop_playback(); if (recording) finish_recording(); page = PAGE_SETUP; break;
        case PAGE_RESULTS: page = PAGE_GAME; break;
        case PAGE_DUB: go_home(); break;
    }
    selected = 0;
}

static int keyboard_activate(void) {
    int count = 0;
    switch (page) {
        case PAGE_HOME: count = 8; break;
        case PAGE_PLAY: count = 3; break;
        case PAGE_MODE: count = 6; break;
        case PAGE_MEMBERS: count = 6; break;
        case PAGE_SETUP: count = 12; break;
        case PAGE_GAME: case PAGE_DUB: count = 4; break;
        case PAGE_RESULTS: count = 6; break;
        case PAGE_PACKS: count = 8; break;
        case PAGE_SETTINGS: count = 3; break;
        case PAGE_DATA: count = 4; break;
        case PAGE_EXTRAS: count = 4; break;
        case PAGE_GUIDE: count = 3; break;
        case PAGE_CREDITS: count = 1; break;
    }
    if (selected >= count) selected = 0;
    return count;
}

static void handle_touch(void) {
    TouchButton buttons[16];
    int n = 0;
    int count = keyboard_activate();
    if (page == PAGE_HOME || page == PAGE_PLAY || page == PAGE_MODE || page == PAGE_MEMBERS || page == PAGE_SETUP || page == PAGE_GAME || page == PAGE_RESULTS || page == PAGE_DUB || page == PAGE_PACKS || page == PAGE_SETTINGS || page == PAGE_DATA || page == PAGE_EXTRAS || page == PAGE_GUIDE || page == PAGE_CREDITS) {
        n = count;
        for (int i = 0; i < n; ++i) {
            int row = i / 2, col = i % 2;
            int first_console_row = 3 + row * 3;
            buttons[i].x = col ? 164 : 4;
            /* Console cells are 8x8 pixels; align the hitbox to the drawn 3-row button. */
            buttons[i].y = (first_console_row - 1) * 8;
            buttons[i].w = 148;
            buttons[i].h = 24;
            buttons[i].label = "";
            buttons[i].id = i;
        }
        int id = touch_hit(buttons, n);
        if (id >= 0) activate_menu(id);
    }
}

static void handle_game_touch_exact(void) {
    if (page != PAGE_GAME && page != PAGE_DUB) return;
    TouchButton b[4] = {
        {BTN_X0, BTN_Y0, BTN_W, BTN_H, "START", 0},
        {BTN_X1, BTN_Y0, BTN_W, BTN_H, "NEXT", 1},
        {BTN_X0, BTN_Y1, BTN_W, BTN_H, "WATCH DUB", 2},
        {BTN_X1, BTN_Y1, BTN_W, BTN_H, "SAVE DUB", 3}
    };
    int id = touch_hit(b, 4);
    if (id >= 0) activate_menu(id);
}

static void render(void) {
    switch (page) {
        case PAGE_HOME: page_home(); break;
        case PAGE_PLAY: page_play(); break;
        case PAGE_MODE: page_mode(); break;
        case PAGE_MEMBERS: page_members(); break;
        case PAGE_SETUP: page_setup(); break;
        case PAGE_GAME: page_game(); break;
        case PAGE_RESULTS: page_results(); break;
        case PAGE_DUB: page_dub(); break;
        case PAGE_PACKS: page_packs(); break;
        case PAGE_SETTINGS: page_settings(); break;
        case PAGE_DATA: page_data(); break;
        case PAGE_EXTRAS: page_extras(); break;
        case PAGE_GUIDE: page_guide(); break;
        case PAGE_CREDITS: page_credits(); break;
    }
    if (message_timer > 0) --message_timer;
    frames++;
}

int main(int argc, char **argv) {
    (void)argc; (void)argv;
    gfxInitDefault();
    consoleInit(GFX_TOP, &topConsole);
    consoleInit(GFX_BOTTOM, &bottomConsole);
    /* libctru's startup code already initializes HID/FS and mounts sdmc:. */
    if (R_SUCCEEDED(ndspInit())) {
        ndsp_ready = true;
        ndspSetMasterVol(1.0f);
    } else {
        set_message("Audio output unavailable; menus still work");
    }
    if (!setup_storage()) set_message("SD storage unavailable or read-only");
    load_state();
    game.last_recording[0] = '\0';

    while (aptMainLoop()) {
        hidScanInput();
        u32 k = hidKeysDown();

        if (k & KEY_START) break;
        if (k & KEY_B) back_page();

        int count = keyboard_activate();
        if (k & KEY_UP) { selected = (selected + count - 1) % count; }
        if (k & KEY_DOWN) { selected = (selected + 1) % count; }
        if ((k & KEY_LEFT) && page == PAGE_SETUP) {
            int row = selected / 2; int *v = setup_value_ptr(row); if (v && *v > 0) --*v; save_state();
        }
        if ((k & KEY_RIGHT) && page == PAGE_SETUP) {
            int row = selected / 2; int *v = setup_value_ptr(row);
            if (v && *v < MAX_ITEMS - 1) ++*v;
            save_state();
        }
        if (k & KEY_A) activate_menu(selected);

        handle_touch();
        handle_game_touch_exact();
        if (recording) {
            bool sampling = true;
            if (R_SUCCEEDED(MICU_IsSampling(&sampling)) && !sampling) finish_recording();
        }
        if (playback_active && playback_wave.status == NDSP_WBUF_DONE) {
            stop_playback();
        }

        render();
        gfxFlushBuffers();
        gfxSwapBuffers();
        gspWaitForVBlank();
    }

    if (recording) finish_recording();
    stop_playback();
    save_state();
    if (mic_ready) {
        micExit();
        mic_ready = false;
    }
    if (mic_buffer) { free(mic_buffer); mic_buffer = NULL; }
    if (ndsp_ready) {
        ndspExit();
        ndsp_ready = false;
    }
    /* libctru's startup/exit hooks own HID, FS and the sdmc archive lifecycle. */
    gfxExit();
    return 0;
}
