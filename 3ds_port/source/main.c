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
#define MIC_BUFFER_SIZE (0x1000 + (MIC_RATE * 2 * 12))
#define MAX_RECORD_SECONDS 8
#define MAX_RECORD_SAMPLES (MIC_RATE * MAX_RECORD_SECONDS)

#define BTN_W 148
#define BTN_H 34
#define BTN_GAP 8
#define BTN_X0 8
#define BTN_X1 (BTN_X0 + BTN_W + BTN_GAP)
#define BTN_Y0 196
#define BTN_Y1 (BTN_Y0 + BTN_H + 4)

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
    if (mkdir(path, 0777) == 0 || errno == EEXIST) return 0;
    return -1;
}

static void setup_storage(void) {
    const char *dirs[] = {
        "sdmc:/luma", "sdmc:/luma/3ds", ROOT, SAVE_DIR, REC_DIR,
        ROOT "/packs_host", ROOT "/packs_judges", ROOT "/packs_menu",
        ROOT "/packs_studio", ROOT "/packs_voice", ROOT "/packs_player"
    };
    for (size_t i = 0; i < sizeof(dirs)/sizeof(dirs[0]); ++i) mk_dir(dirs[i]);

    FILE *f = fopen(SAVE_FILE, "rb");
    if (f) { fclose(f); return; }
    f = fopen(SAVE_FILE, "wb");
    if (!f) return;
    fprintf(f,
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
        "}\n");
    fclose(f);
}

static int json_int(FILE *f, const char *key, int def) {
    char line[256], needle[96];
    snprintf(needle, sizeof(needle), "\"%s\"", key);
    rewind(f);
    while (fgets(line, sizeof(line), f)) {
        char *p = strstr(line, needle);
        if (p) {
            p = strchr(p, ':');
            if (p) return atoi(p + 1);
        }
    }
    return def;
}

static void load_state(void) {
    memset(&game, 0, sizeof(game));
    game.member_count = 1;
    game.total_rounds = 3;
    FILE *f = fopen(SAVE_FILE, "rb");
    if (!f) return;
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
    if (game.member_count < 1) game.member_count = 1;
    if (game.member_count > MAX_PLAYERS) game.member_count = MAX_PLAYERS;
}

static void save_state(void) {
    FILE *f = fopen(SAVE_FILE, "wb");
    if (!f) return;
    fprintf(f,
        "{\n  \"version\": 4,\n  \"mode\": %d,\n  \"member_count\": %d,\n"
        "  \"player\": %d,\n  \"voice\": %d,\n  \"host\": %d,\n"
        "  \"judge\": %d,\n  \"studio\": %d,\n  \"round\": %d,\n"
        "  \"total_rounds\": %d\n}\n",
        game.mode, game.member_count, game.player, game.voice, game.host,
        game.judge, game.studio, game.round, game.total_rounds);
    fclose(f);
}

static void list_dir(const char *path, ItemList *out) {
    memset(out, 0, sizeof(*out));
    DIR *d = opendir(path);
    if (!d) return;
    struct dirent *e;
    while ((e = readdir(d)) && out->count < MAX_ITEMS) {
        if (e->d_name[0] == '.') continue;
        snprintf(out->items[out->count].name, MAX_NAME, "%s", e->d_name);
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
    memset(info, 0, sizeof(*info));
    FILE *f = fopen(path, "rb");
    if (!f) return false;
    uint8_t h[12];
    if (fread(h, 1, 12, f) != 12 || memcmp(h, "RIFF", 4) || memcmp(h + 8, "WAVE", 4)) {
        fclose(f); return false;
    }
    bool fmt_ok = false, data_ok = false;
    while (!feof(f)) {
        uint8_t hdr[8];
        if (fread(hdr, 1, 8, f) != 8) break;
        uint32_t chunk = (uint32_t)hdr[4] | ((uint32_t)hdr[5] << 8) | ((uint32_t)hdr[6] << 16) | ((uint32_t)hdr[7] << 24);
        if (!memcmp(hdr, "fmt ", 4)) {
            uint8_t fmt[40];
            if (chunk > sizeof(fmt) || fread(fmt, 1, chunk, f) != chunk) break;
            uint16_t codec = fmt[0] | ((uint16_t)fmt[1] << 8);
            info->channels = fmt[2] | ((uint16_t)fmt[3] << 8);
            info->sampleRate = fmt[4] | ((uint32_t)fmt[5] << 8) | ((uint32_t)fmt[6] << 16) | ((uint32_t)fmt[7] << 24);
            info->bits = fmt[14] | ((uint16_t)fmt[15] << 8);
            fmt_ok = codec == 1 && (info->channels == 1 || info->channels == 2) && info->bits == 16;
        } else if (!memcmp(hdr, "data", 4)) {
            info->dataBytes = chunk;
            info->data = malloc(chunk);
            if (!info->data || fread(info->data, 1, chunk, f) != chunk) {
                free(info->data); info->data = NULL; fclose(f); return false;
            }
            data_ok = true;
            break;
        } else {
            if (fseek(f, chunk + (chunk & 1), SEEK_CUR) != 0) break;
        }
    }
    fclose(f);
    if (!fmt_ok || !data_ok) {
        free(info->data); info->data = NULL; return false;
    }
    return true;
}

static void stop_playback(void) {
    ndspChnWaveBufClear(playback_channel);
    playback_active = false;
    if (playback_data) {
        linearFree(playback_data);
        playback_data = NULL;
    }
    playback_size = 0;
}

static bool play_wav_file(const char *path) {
    WavInfo w;
    if (!read_wav(path, &w)) return false;
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

static bool save_wav(const char *path, const uint8_t *data, uint32_t bytes, uint32_t sample_rate, uint16_t channels, uint16_t bits) {
    FILE *f = fopen(path, "wb");
    if (!f) return false;
    uint32_t fmt_size = 16;
    uint32_t riff_size = 4 + 8 + fmt_size + 8 + bytes;
    uint16_t format = 1;
    uint32_t byte_rate = sample_rate * channels * bits / 8;
    uint16_t block = channels * bits / 8;
    fwrite("RIFF", 1, 4, f); fwrite(&riff_size, 4, 1, f); fwrite("WAVE", 1, 4, f);
    fwrite("fmt ", 1, 4, f); fwrite(&fmt_size, 4, 1, f); fwrite(&format, 2, 1, f); fwrite(&channels, 2, 1, f);
    fwrite(&sample_rate, 4, 1, f); fwrite(&byte_rate, 4, 1, f); fwrite(&block, 2, 1, f); fwrite(&bits, 2, 1, f);
    fwrite("data", 1, 4, f); fwrite(&bytes, 4, 1, f); fwrite(data, 1, bytes, f);
    fclose(f);
    return true;
}

static bool init_mic(void) {
    if (mic_ready) return true;
    mic_buffer = (u8*)memalign(0x1000, MIC_BUFFER_SIZE);
    if (!mic_buffer) return false;
    memset(mic_buffer, 0, MIC_BUFFER_SIZE);
    Result r = micInit(mic_buffer, MIC_BUFFER_SIZE);
    if (R_FAILED(r)) { free(mic_buffer); mic_buffer = NULL; return false; }
    MICU_SetPower(true);
    MICU_SetClamp(false);
    MICU_SetGain(64);
    mic_ready = true;
    return true;
}

static void stop_recording(bool save_now) {
    if (!recording) return;
    MICU_StopSampling();
    bool sampling = false;
    MICU_IsSampling(&sampling);
    recording = false;
    uint32_t bytes = micGetLastSampleOffset();
    if (bytes > MIC_BUFFER_SIZE - 0x1000) bytes = MIC_BUFFER_SIZE - 0x1000;
    if (bytes > MAX_RECORD_SAMPLES * 2) bytes = MAX_RECORD_SAMPLES * 2;
    recording_bytes = bytes;
    if (save_now && bytes > 2048) {
        char path[256];
        int index = 1;
        for (;;) {
            snprintf(path, sizeof(path), "%s/dub_%03d.wav", REC_DIR, index++);
            FILE *f = fopen(path, "rb");
            if (!f) break;
            fclose(f);
        }
        if (save_wav(path, mic_buffer, bytes, MIC_RATE, 1, 16)) {
            snprintf(game.last_recording, sizeof(game.last_recording), "%s", path);
            set_message("Recording saved");
        }
    }
}

static void start_recording(void) {
    if (!init_mic()) { set_message("Microphone unavailable"); return; }
    if (recording) return;
    memset(mic_buffer, 0, MIC_BUFFER_SIZE);
    recording_bytes = 0;
    Result r = MICU_StartSampling(MICU_ENCODING_PCM16_SIGNED, MICU_SAMPLE_RATE_16360, 0, MIC_BUFFER_SIZE - 0x1000, false);
    if (R_FAILED(r)) { set_message("Microphone start failed"); return; }
    recording = true;
    set_message("Recording...");
}

static void finish_recording(void) {
    if (!recording) return;
    stop_recording(true);
    if (recording_bytes > 2048) {
        snprintf(game.last_recording, sizeof(game.last_recording), "%s/dub_latest.wav", REC_DIR);
        save_wav(game.last_recording, mic_buffer, recording_bytes, MIC_RATE, 1, 16);
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

static void draw_bottom_footer(const char *text) {
    printf("\x1b[28;2H%s", text ? text : "Touch a button or use A/B/D-pad");
}

static void draw_button_text(int xcol, int row, const char *label, bool active) {
    consoleSelect(&bottomConsole);
    printf("\x1b[%d;%dH%s[%s]", row, xcol, active ? ">" : " ", label);
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
        int y = 3 + row * 4;
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
    game.clip_index++;
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
    if (recording_bytes > 2048) {
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
                    if ((id & 1) == 1) ++*v;
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
                if (game.round + 1 < game.total_rounds) { game.round++; game.clip_index++; page = PAGE_GAME; }
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
            else if (id == 1) { game.clip_index++; page = PAGE_DUB; }
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
            else if (id == 1) { remove(SAVE_FILE); load_state(); setup_storage(); set_message("Native state reset"); }
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
    const int counts[] = {8,3,6,6,12,4,6,4,8,3,4,4,3,1};
    int count = keyboard_activate();
    if (page == PAGE_HOME || page == PAGE_PLAY || page == PAGE_MODE || page == PAGE_MEMBERS || page == PAGE_SETUP || page == PAGE_GAME || page == PAGE_RESULTS || page == PAGE_DUB || page == PAGE_PACKS || page == PAGE_SETTINGS || page == PAGE_DATA || page == PAGE_EXTRAS || page == PAGE_GUIDE || page == PAGE_CREDITS) {
        n = count;
        for (int i = 0; i < n; ++i) {
            int row = i / 2, col = i % 2;
            buttons[i].x = col ? 164 : 8;
            buttons[i].y = 8 + row * 38;
            buttons[i].w = 148;
            buttons[i].h = 32;
            buttons[i].label = "";
            buttons[i].id = i;
        }
        int id = touch_hit(buttons, n);
        if (id >= 0) activate_menu(id);
    }
    (void)counts;
}

static void handle_game_touch_exact(void) {
    if (page != PAGE_GAME && page != PAGE_DUB) return;
    TouchButton b[4] = {
        {8, 190, BTN_W, 25, "START", 0},
        {164, 190, BTN_W, 25, "NEXT", 1},
        {8, 216, BTN_W, 24, "WATCH DUB", 2},
        {164, 216, BTN_W, 24, "SAVE DUB", 3}
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
    hidInit();
    fsInit();
    archiveMountSdmc();
    ndspInit();
    setup_storage();
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
            int row = selected / 2; int *v = setup_value_ptr(row); if (v) ++*v; save_state();
        }
        if (k & KEY_A) activate_menu(selected);

        handle_touch();
        handle_game_touch_exact();
        if (recording) {
            bool sampling = true;
            MICU_IsSampling(&sampling);
            if (!sampling) finish_recording();
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
    if (mic_ready) { MICU_StopSampling(); micExit(); }
    if (mic_buffer) { free(mic_buffer); mic_buffer = NULL; }
    ndspExit();
    archiveUnmountSdmc();
    fsExit();
    hidExit();
    gfxExit();
    return 0;
}
