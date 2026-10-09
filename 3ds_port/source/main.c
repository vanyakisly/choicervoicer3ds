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
#include <zlib.h>

#define ROOT "sdmc:/luma/3ds/The Choicer Voicer"
#define SAVE_DIR ROOT "/saves"
#define REC_DIR ROOT "/recordings"
#define SAVE_FILE SAVE_DIR "/save.json"

#define MAX_ITEMS 64
#define MAX_NAME 96
#define MAX_VOICE_CLIPS 256
#define TCV_MAX_FRAMES 5400u
#define TCV_FRAME_BYTES (160u * 90u * 2u)
#define MAX_PLAYERS 4
#define SCREEN_TOP 0
#define SCREEN_BOTTOM 1

#define TOUCH_W 320
#define TOUCH_H 240

#define MIC_RATE 16360
#define MAX_RECORD_SECONDS 8
#define MAX_RECORD_SAMPLES (MIC_RATE * MAX_RECORD_SECONDS)
/* MIC uses a shared-memory block: its address and size must be 0x1000-aligned. */
#define MIC_BUFFER_SIZE ((MAX_RECORD_SAMPLES * 2u + 4u + 0xFFFu) & ~0xFFFu)
/* Keep imported WAVs within a conservative Old 3DS memory budget. */
#define MAX_WAV_BYTES (4u * 1024u * 1024u)
#define MAX_RIFF_CHUNK_BYTES (8u * 1024u * 1024u)
#define DUB_OVERLAY_SLOTS 4
#define DUB_OVERLAY_CHANNEL_BASE 4
#define DUB_OVERLAY_MAX_WAV_BYTES (1536u * 1024u)

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
    PAGE_CREDITS,
    PAGE_CUSTOMIZE,
    PAGE_PACK_LIST,
    PAGE_SETTING_DETAIL,
    PAGE_FOLDER,
    PAGE_CINEMA
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
    int menu;
    int twitch;
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

typedef struct { int w, h; uint32_t *pixels; } Canvas;
typedef struct { uint16_t w, h; uint8_t *rgba; } Sprite;

typedef struct {
    char path[384];
    char relative[192];
    char stem[128];
    char caption[160];
    char characters[80];
    char image_name[160];
    float timestamp;
    bool has_timestamp;
    bool dub_only;
} NativeVoiceClip;

typedef struct {
    FILE *file;
    uint16_t width, height, fps, key_interval;
    uint32_t frame_count, current_frame, index_offset;
    uint32_t *offsets;
    uint8_t *pixels;       /* decoded RGB565 bytes */
    uint8_t *decoded;      /* one decompressed frame/delta */
    uint8_t *payload;      /* compressed/raw frame packet */
    size_t frame_bytes;
    bool opened, has_frame, playing;
    uint64_t start_time_ms;
} TcvVideo;

enum {
    SPR_LOGO_BANNER, SPR_LOGO_ICON, SPR_DEV_LOGO, SPR_HOST, SPR_PLAYER,
    SPR_JUDGE1, SPR_JUDGE2, SPR_JUDGE3, SPR_JUDGE4, SPR_JUDGE5,
    SPR_WAVE_GOOD, SPR_WAVE_LOUD, SPR_WAVE_QUIET, SPR_WAVE_TIMING,
    SPR_GAMESHOW_SCENE, SPR_PANELIST_SCENE, SPR_DUB_STANDARD, SPR_DUB_FREESTYLE,
    SPR_HELP_PACKGUIDE, SPR_HELP_PACKFOLDERS, SPR_HELP_JUDGES, SPR_HELP_PERFORMANCE,
    SPR_HELP_SCORE, SPR_MIC, SPR_RECORD_BUTTON,
    SPR_CREDIT_PIERCE, SPR_CREDIT_VINNY, SPR_CREDIT_JIMMY, SPR_CREDIT_KIOPHEN,
    SPR_CREDIT_AZURE, SPR_CREDIT_MADCLOWN, SPR_CREDIT_ALIZARIN,
    SPR_CLIP1, SPR_CLIP2, SPR_CLIP3, SPR_CLIP4, SPR_CLIP5,
    SPR_FONT_SMALL, SPR_FONT_LARGE, SPR_COUNT
};

static const char *sprite_files[SPR_COUNT] = {
    "logo_banner.rgba", "logo_icon.rgba", "developer_logo.rgba", "host_default.rgba", "player_default.rgba",
    "judge_1.rgba", "judge_2.rgba", "judge_3.rgba", "judge_4.rgba", "judge_5.rgba",
    "wave_good.rgba", "wave_loud.rgba", "wave_quiet.rgba", "wave_timing.rgba",
    "gameshow_scene.rgba", "panelist_scene.rgba", "dub_standard_scene.rgba", "dub_freestyle_scene.rgba",
    "help_packguide.rgba", "help_pack_folders.rgba", "help_judges.rgba", "help_performance.rgba",
    "help_score.rgba", "mic.rgba", "record_button.rgba",
    "credit_pierce.rgba", "credit_vinny.rgba", "credit_jimmy.rgba", "credit_kiophen.rgba",
    "credit_azureotsu.rgba", "credit_madclown.rgba", "credit_alizarin.rgba",
    "clip_1.rgba", "clip_2.rgba", "clip_3.rgba", "clip_4.rgba", "clip_5.rgba",
    "font_small.rgba", "font_large.rgba"
};

static Page page = PAGE_HOME;
static GameState game;
static ItemList last_packs;
static uint64_t frames = 0;
static int selected = 0;
static int pack_type = 0;
static int pack_selected = 0;
static int pack_scroll_offset = 0;
static int settings_group = 0;
static int guide_page = 0;
static int credits_page = 0;
static int message_timer = 0;
static char message[128] = "";
static char game_subtitle[160] = "";
static Canvas top_canvas = {400, 240, NULL};
static Canvas bottom_canvas = {320, 240, NULL};
static Sprite sprites[SPR_COUNT];
static Sprite active_clip_art;
static TouchButton touch_buttons[24];
static int touch_button_count = 0;

static int music_volume = 6;
static int sfx_volume = 7;
static int mic_gain = 64;
static int configured_record_seconds = MAX_RECORD_SECONDS;
static int music_track = 0;
static int waveform_mode = 0;
static int show_subtitles = 1;
static int auto_save_dub = 1;
static int auto_next_round = 0;
static int show_help_overlays = 1;
static int game_speedups = 0;
static int tshirt_mode = 0;
static Page pack_return_page = PAGE_PACKS;
static uint64_t recording_started_frame = 0;

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

#define MUSIC_CH 1
#define STREAM_CHUNK_BYTES 16384u

typedef struct {
    uint8_t *data;
    size_t data_bytes;
    ndspWaveBuf wave;
    bool active;
} DubOverlaySlot;
static DubOverlaySlot dub_overlay[DUB_OVERLAY_SLOTS];
typedef struct {
    FILE *file;
    long data_start;
    uint32_t data_bytes;
    uint32_t data_left;
    uint32_t rate;
    uint16_t channels;
    bool loop;
    bool active;
    char path[384];
    uint8_t *buffers[2];
    ndspWaveBuf waves[2];
} AudioStream;
static AudioStream music_stream;
static NativeVoiceClip voice_clips[MAX_VOICE_CLIPS];
static int voice_clip_count = 0;
static bool sort_voice_by_timestamp = false;
static bool active_dub_pack = false;
static bool dub_replay_active = false;
static int dub_replay_next_clip = 0;
static uint64_t dub_replay_start_ms = 0;
static char active_pack_dir[384] = "";
static char active_pack_name[MAX_NAME] = "";
static TcvVideo dub_video;
static const char *pack_folders[] = {
    "packs_voice", "packs_player", "packs_host", "packs_judges", "packs_studio", "packs_menu", "packs_twitch"
};
static const char *pack_labels[] = {
    "Voice Packs", "Player Packs", "Host Packs", "Judge Packs", "Studio Packs", "Menu Packs", "Twitch Packs"
};

static bool get_pack_dir(int type, int index, char *out, size_t out_size);
static int pack_count_for_type(int type);
static void normalize_pack_indices(void);
static bool make_active_dub_record_path(int clip_index, char *out, size_t out_size, bool create_dirs);
static void tcv_close(TcvVideo *v);
static bool tcv_seek(TcvVideo *v, float seconds);
static void tcv_pump(void);
static void dub_replay_pump(void);
static void pump_dub_overlay_audio(void);
static void stop_dub_overlay_audio(void);
static bool play_dub_overlay_wav(const char *path);
static void draw_tcv_video(Canvas *c, int x, int y, int w, int h);

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
        ROOT "/packs_studio", ROOT "/packs_voice", ROOT "/packs_player", ROOT "/packs_twitch"
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
        "  \"version\": 9,\n"
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
    game.menu = clamp_int(game.menu, 0, MAX_ITEMS - 1);
    game.twitch = clamp_int(game.twitch, 0, MAX_ITEMS - 1);
    game.total_rounds = clamp_int(game.total_rounds, 1, 9);
    game.round = clamp_int(game.round, 0, game.total_rounds - 1);
    game.clip_index = clamp_int(game.clip_index, 0, MAX_VOICE_CLIPS - 1);
    music_volume = clamp_int(music_volume, 0, 10);
    sfx_volume = clamp_int(sfx_volume, 0, 10);
    mic_gain = clamp_int(mic_gain, 0, 127);
    configured_record_seconds = clamp_int(configured_record_seconds, 2, MAX_RECORD_SECONDS);
    music_track = clamp_int(music_track, 0, 4);
    waveform_mode = clamp_int(waveform_mode, 0, 2);
    show_subtitles = clamp_int(show_subtitles, 0, 1);
    auto_save_dub = clamp_int(auto_save_dub, 0, 1);
    auto_next_round = clamp_int(auto_next_round, 0, 1);
    show_help_overlays = clamp_int(show_help_overlays, 0, 1);
    game_speedups = clamp_int(game_speedups, 0, 1);
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
        game.menu = json_int(f, "menu", 0);
        game.twitch = json_int(f, "twitch", 0);
        game.round = json_int(f, "round", 0);
        game.total_rounds = json_int(f, "total_rounds", 3);
        music_volume = json_int(f, "music_volume", 6);
        sfx_volume = json_int(f, "sfx_volume", 7);
        mic_gain = json_int(f, "mic_gain", 64);
        configured_record_seconds = json_int(f, "record_seconds", MAX_RECORD_SECONDS);
        music_track = json_int(f, "music_track", 3);
        waveform_mode = json_int(f, "waveform_mode", 0);
        show_subtitles = json_int(f, "show_subtitles", 1);
        auto_save_dub = json_int(f, "auto_save_dub", 1);
        auto_next_round = json_int(f, "auto_next_round", 0);
        show_help_overlays = json_int(f, "show_help_overlays", 1);
        game_speedups = json_int(f, "game_speedups", 0);
        fclose(f);
    }
    normalize_state();
    normalize_pack_indices();
}

static void save_state(void) {
    normalize_state();
    normalize_pack_indices();
    char temp_path[320];
    snprintf(temp_path, sizeof(temp_path), "%s/save.json.tmp", SAVE_DIR);
    FILE *f = fopen(temp_path, "wb");
    if (!f) { set_message("Cannot open save file for writing"); return; }
    bool ok = fprintf(f,
        "{\n  \"version\": 9,\n  \"mode\": %d,\n  \"member_count\": %d,\n"
        "  \"player\": %d,\n  \"voice\": %d,\n  \"host\": %d,\n"
        "  \"judge\": %d,  \"studio\": %d,  \"menu\": %d,  \"twitch\": %d,  \"round\": %d,\n"
        "  \"total_rounds\": %d,\n  \"music_volume\": %d,\n  \"sfx_volume\": %d,\n"
        "  \"mic_gain\": %d,\n  \"record_seconds\": %d,\n  \"music_track\": %d,\n"
        "  \"waveform_mode\": %d,\n  \"show_subtitles\": %d,\n  \"auto_save_dub\": %d,\n"
        "  \"auto_next_round\": %d,\n  \"show_help_overlays\": %d,\n  \"game_speedups\": %d\n}\n",
        game.mode, game.member_count, game.player, game.voice, game.host,
        game.judge, game.studio, game.menu, game.twitch, game.round, game.total_rounds,
        music_volume, sfx_volume, mic_gain, configured_record_seconds, music_track,
        waveform_mode, show_subtitles, auto_save_dub, auto_next_round, show_help_overlays, game_speedups) > 0;
    if (fflush(f) != 0) ok = false;
    if (fclose(f) != 0) ok = false;
    if (!ok || rename(temp_path, SAVE_FILE) != 0) {
        remove(temp_path);
        set_message("Save write failed; previous save retained");
    }
}

static int compare_items(const void *a, const void *b) {
    const Item *ia = (const Item *)a; const Item *ib = (const Item *)b;
    return strcasecmp(ia->name, ib->name);
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
    qsort(out->items, (size_t)out->count, sizeof(out->items[0]), compare_items);
}

static void list_pack_dir(int type, ItemList *out) {
    memset(out, 0, sizeof(*out));
    char path[256];
    snprintf(path, sizeof(path), "%s/%s", ROOT, pack_folders[clamp_int(type, 0, 6)]);
    DIR *d = opendir(path);
    if (d) {
        struct dirent *e;
        while ((e = readdir(d)) && out->count < MAX_ITEMS) {
            if (e->d_name[0] == '.') continue;
            char child[384]; struct stat st;
            snprintf(child, sizeof(child), "%s/%s", path, e->d_name);
            if (stat(child, &st) != 0 || !S_ISDIR(st.st_mode)) continue;
            snprintf(out->items[out->count++].name, MAX_NAME, "%.95s", e->d_name);
        }
        closedir(d);
        qsort(out->items, (size_t)out->count, sizeof(out->items[0]), compare_items);
    }
    if (out->count == 0) {
        snprintf(out->items[0].name, MAX_NAME, "Default (no external packs)");
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
    float v = (float)clamp_int(sfx_volume, 0, 10) / 10.0f;
    float mix[12] = {v,v,0,0,0,0,0,0,0,0,0,0};
    ndspChnSetMix(playback_channel, mix);
    ndspChnWaveBufAdd(playback_channel, &playback_wave);
    playback_active = true;
    return true;
}

/* Dub playback uses independent NDSP channels so line timestamps remain aligned
   with the video even when neighbouring recorded takes overlap. Four bounded
   slots keep Old-3DS linear memory use predictable. */
static void release_dub_overlay_slot(int i) {
    if (i < 0 || i >= DUB_OVERLAY_SLOTS) return;
    DubOverlaySlot *slot = &dub_overlay[i];
    if (ndsp_ready) ndspChnWaveBufClear(DUB_OVERLAY_CHANNEL_BASE + i);
    if (slot->data) linearFree(slot->data);
    memset(slot, 0, sizeof(*slot));
}

static void stop_dub_overlay_audio(void) {
    for (int i = 0; i < DUB_OVERLAY_SLOTS; ++i) release_dub_overlay_slot(i);
}

static void pump_dub_overlay_audio(void) {
    if (!ndsp_ready) return;
    for (int i = 0; i < DUB_OVERLAY_SLOTS; ++i) {
        DubOverlaySlot *slot = &dub_overlay[i];
        if (slot->active && (slot->wave.status == NDSP_WBUF_DONE || slot->wave.status == NDSP_WBUF_FREE))
            release_dub_overlay_slot(i);
    }
}

static bool play_dub_overlay_wav(const char *path) {
    if (!ndsp_ready || !path || !*path) return false;
    pump_dub_overlay_audio();
    int index = -1;
    for (int i = 0; i < DUB_OVERLAY_SLOTS; ++i) if (!dub_overlay[i].active) { index = i; break; }
    if (index < 0) { set_message("Too many overlapping lines; skipping this audio line"); return false; }
    WavInfo w;
    if (!read_wav(path, &w)) return false;
    if (w.dataBytes > DUB_OVERLAY_MAX_WAV_BYTES) {
        free(w.data); set_message("This dub line is too large; reconvert the pack audio on PC"); return false;
    }
    uint8_t *buffer = (uint8_t *)linearAlloc(w.dataBytes);
    if (!buffer) { free(w.data); set_message("Not enough audio memory for this dub line"); return false; }
    memcpy(buffer, w.data, w.dataBytes); free(w.data);
    DubOverlaySlot *slot = &dub_overlay[index];
    memset(slot, 0, sizeof(*slot)); slot->data = buffer; slot->data_bytes = w.dataBytes;
    memset(&slot->wave, 0, sizeof(slot->wave));
    slot->wave.data_pcm16 = (s16 *)buffer;
    slot->wave.nsamples = (u32)(w.dataBytes / (2u * w.channels));
    slot->wave.looping = false;
    DSP_FlushDataCache(buffer, w.dataBytes);
    int channel = DUB_OVERLAY_CHANNEL_BASE + index;
    ndspChnWaveBufClear(channel);
    ndspChnSetFormat(channel, w.channels == 2 ? NDSP_FORMAT_STEREO_PCM16 : NDSP_FORMAT_MONO_PCM16);
    ndspChnSetRate(channel, (float)w.sampleRate);
    float v = (float)clamp_int(sfx_volume, 0, 10) / 10.0f;
    float mix[12] = {v,v,0,0,0,0,0,0,0,0,0,0};
    ndspChnSetMix(channel, mix);
    ndspChnWaveBufAdd(channel, &slot->wave);
    slot->active = true;
    return true;
}

static bool dub_overlay_audio_active(void) {
    for (int i = 0; i < DUB_OVERLAY_SLOTS; ++i) if (dub_overlay[i].active) return true;
    return false;
}

/* Streaming WAV music: only two small linear-memory buffers are resident. */
static uint32_t read_le32(const uint8_t *p) {
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}
static uint16_t read_le16(const uint8_t *p) { return (uint16_t)(p[0] | ((uint16_t)p[1] << 8)); }

static bool stream_open_wav(AudioStream *stream, const char *path, bool loop) {
    if (!stream || !path) return false;
    memset(stream, 0, sizeof(*stream));
    FILE *f = fopen(path, "rb");
    if (!f) return false;
    uint8_t riff[12];
    if (fread(riff, 1, sizeof(riff), f) != sizeof(riff) || memcmp(riff, "RIFF", 4) || memcmp(riff + 8, "WAVE", 4)) {
        fclose(f); return false;
    }
    if (fseek(f, 0, SEEK_END) != 0) { fclose(f); return false; }
    long file_size = ftell(f);
    if (file_size < (long)sizeof(riff) || fseek(f, (long)sizeof(riff), SEEK_SET) != 0) { fclose(f); return false; }
    bool fmt_ok = false, data_ok = false;
    long data_start = -1;
    uint32_t data_bytes = 0, rate = 0;
    uint16_t channels = 0, bits = 0, codec = 0;
    for (int chunks = 0; chunks < 128; ++chunks) {
        uint8_t ch[8];
        if (fread(ch, 1, sizeof(ch), f) != sizeof(ch)) break;
        uint32_t length = read_le32(ch + 4);
        long pos = ftell(f);
        if (pos < 0 || length > 0x7FFFFFF0u || (uint64_t)(unsigned long)pos + (uint64_t)length + (uint64_t)(length & 1u) > (uint64_t)(unsigned long)file_size) break;
        if (!memcmp(ch, "fmt ", 4)) {
            uint8_t fmt[16];
            if (length < 16 || fread(fmt, 1, 16, f) != 16) break;
            codec = read_le16(fmt);
            channels = read_le16(fmt + 2);
            rate = read_le32(fmt + 4);
            bits = read_le16(fmt + 14);
            fmt_ok = codec == 1 && (channels == 1 || channels == 2) && bits == 16 && rate >= 8000 && rate <= 48000;
        } else if (!memcmp(ch, "data", 4)) {
            data_start = pos;
            data_bytes = length;
            /* Validate frame alignment after the fmt chunk is known. */
            data_ok = length > 0;
        }
        if (fseek(f, pos + (long)length + (long)(length & 1u), SEEK_SET) != 0) break;
        if (fmt_ok && data_ok) break;
    }
    if (!fmt_ok || !data_ok || data_start < 0 || data_bytes < (uint32_t)channels * 2u || data_bytes % ((uint32_t)channels * 2u) != 0 || fseek(f, data_start, SEEK_SET) != 0) {
        fclose(f); return false;
    }
    stream->file = f;
    stream->data_start = data_start;
    stream->data_bytes = data_bytes;
    stream->data_left = data_bytes;
    stream->rate = rate;
    stream->channels = channels;
    stream->loop = loop;
    stream->active = true;
    snprintf(stream->path, sizeof(stream->path), "%s", path);
    for (int i = 0; i < 2; ++i) {
        stream->buffers[i] = (uint8_t *)linearAlloc(STREAM_CHUNK_BYTES);
        if (!stream->buffers[i]) {
            for (int j = 0; j < 2; ++j) { if (stream->buffers[j]) linearFree(stream->buffers[j]); stream->buffers[j] = NULL; }
            fclose(stream->file); stream->file = NULL; stream->active = false; return false;
        }
        memset(&stream->waves[i], 0, sizeof(stream->waves[i]));
    }
    ndspChnSetFormat(MUSIC_CH, channels == 2 ? NDSP_FORMAT_STEREO_PCM16 : NDSP_FORMAT_MONO_PCM16);
    ndspChnSetRate(MUSIC_CH, (float)rate);
    float v = (float)clamp_int(music_volume, 0, 10) / 10.0f;
    float mix[12] = {v,v,0,0,0,0,0,0,0,0,0,0};
    ndspChnSetMix(MUSIC_CH, mix);
    ndspChnWaveBufClear(MUSIC_CH);
    return true;
}

static bool stream_queue_next(AudioStream *stream, int slot) {
    if (!stream || !stream->active || !stream->file || slot < 0 || slot > 1) return false;
    uint32_t frame_bytes = (uint32_t)stream->channels * 2u;
    if (stream->data_left == 0) {
        if (!stream->loop || fseek(stream->file, stream->data_start, SEEK_SET) != 0) return false;
        stream->data_left = stream->data_bytes;
    }
    uint32_t amount = stream->data_left < STREAM_CHUNK_BYTES ? stream->data_left : STREAM_CHUNK_BYTES;
    amount -= amount % frame_bytes;
    if (amount < frame_bytes) return false;
    size_t got = fread(stream->buffers[slot], 1, amount, stream->file);
    got -= got % frame_bytes;
    if (got < frame_bytes) { stream->data_left = 0; return false; }
    stream->data_left -= (uint32_t)got;
    ndspWaveBuf *wave = &stream->waves[slot];
    memset(wave, 0, sizeof(*wave));
    wave->data_pcm16 = (s16 *)stream->buffers[slot];
    wave->nsamples = (u32)(got / frame_bytes);
    wave->looping = false;
    DSP_FlushDataCache(stream->buffers[slot], got);
    ndspChnWaveBufAdd(MUSIC_CH, wave);
    return true;
}

static void music_stream_stop(void) {
    if (ndsp_ready) ndspChnWaveBufClear(MUSIC_CH);
    if (music_stream.file) { fclose(music_stream.file); music_stream.file = NULL; }
    for (int i = 0; i < 2; ++i) {
        if (music_stream.buffers[i]) linearFree(music_stream.buffers[i]);
        music_stream.buffers[i] = NULL;
    }
    memset(&music_stream, 0, sizeof(music_stream));
}

static bool music_stream_start_path(const char *path) {
    music_stream_stop();
    if (!ndsp_ready || !stream_open_wav(&music_stream, path, true)) return false;
    if (!stream_queue_next(&music_stream, 0) || !stream_queue_next(&music_stream, 1)) {
        music_stream_stop(); return false;
    }
    return true;
}

static void music_stream_pump(void) {
    if (!music_stream.active) return;
    for (int i = 0; i < 2; ++i) {
        if (music_stream.waves[i].status == NDSP_WBUF_DONE || music_stream.waves[i].status == NDSP_WBUF_FREE)
            (void)stream_queue_next(&music_stream, i);
    }
}

static void start_selected_music(void) {
    static const char *tracks[] = {
        "audio/music/cartridge_loop.wav", "audio/music/studio_music_loop_final.wav",
        "audio/music/use_tutorial_loop.wav", "audio/music/maintheme.wav", "audio/music/tcv_polling.wav"
    };
    char path[384];
    snprintf(path, sizeof(path), "%s/%s", ROOT, tracks[clamp_int(music_track, 0, 4)]);
    if (music_stream_start_path(path)) set_message("Playing original TCV music");
    else set_message("Music file unavailable; check the SD assets folder");
}

static void set_music_volume(void) {
    if (!ndsp_ready) return;
    float v = (float)clamp_int(music_volume, 0, 10) / 10.0f;
    float mix[12] = {v,v,0,0,0,0,0,0,0,0,0,0};
    ndspChnSetMix(MUSIC_CH, mix);
}

static void play_menu_sfx(const char *kind) {
    if (!kind || !ndsp_ready || sfx_volume <= 0) return;
    char dir[384], path[512];
    if (!get_pack_dir(5, game.menu, dir, sizeof(dir))) return;
    snprintf(path, sizeof(path), "%s/button_sfx_%s.wav", dir, kind);
    if (!play_wav_file(path) && game.menu != 0 && get_pack_dir(5, 0, dir, sizeof(dir))) {
        snprintf(path, sizeof(path), "%s/button_sfx_%s.wav", dir, kind);
        (void)play_wav_file(path);
    }
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
    mic_buffer = (u8 *)linearAlloc(MIC_BUFFER_SIZE);
    if (!mic_buffer) { set_message("Not enough linear memory for microphone"); return false; }
    memset(mic_buffer, 0, MIC_BUFFER_SIZE);
    Result r = micInit(mic_buffer, MIC_BUFFER_SIZE);
    if (R_FAILED(r)) {
        linearFree(mic_buffer);
        mic_buffer = NULL;
        set_message("Microphone service unavailable");
        return false;
    }
    if (R_FAILED(MICU_SetClamp(false)) || R_FAILED(MICU_SetGain((u8)clamp_int(mic_gain, 0, 127)))) {
        micExit();
        linearFree(mic_buffer);
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
    /* micGetLastSampleOffset() is the byte offset in the sample area; samples start at buffer[0]. */
    uint32_t cap = (uint32_t)configured_record_seconds * MIC_RATE * 2u;
    if (bytes > cap) bytes = cap;
    if (bytes > micGetSampleDataSize()) bytes = micGetSampleDataSize();
    bytes &= ~1u; /* PCM16 must end on a complete sample. */
    recording_bytes = bytes;
    if (save_now && bytes > 2048) {
        char path[512];
        bool destination_ok = false;
        if (active_dub_pack) {
            destination_ok = make_active_dub_record_path(game.clip_index, path, sizeof(path), true);
        } else {
            bool found_slot = false;
            for (int index = 1; index < 100000; ++index) {
                snprintf(path, sizeof(path), "%s/dub_%03d.wav", REC_DIR, index);
                FILE *existing = fopen(path, "rb");
                if (!existing) { found_slot = true; break; }
                fclose(existing);
            }
            destination_ok = found_slot;
        }
        if (!destination_ok) { set_message("Could not create a recording destination"); return; }
        if (save_wav(path, mic_buffer, bytes, MIC_RATE, 1, 16)) {
            snprintf(game.last_recording, sizeof(game.last_recording), "%s", path);
            set_message(active_dub_pack ? "Dub line saved into this pack's session" : "Recording saved");
        } else {
            set_message("Could not write recording to SD card");
        }
    }
}

static void start_recording(void) {
    if (recording) return;
    if (active_dub_pack) {
        bool was_replaying = dub_replay_active;
        dub_replay_active = false;
        stop_dub_overlay_audio();
        if (was_replaying) { music_stream_stop(); start_selected_music(); }
        dub_video.playing = false;
        if (game.clip_index >= 0 && game.clip_index < voice_clip_count)
            (void)tcv_seek(&dub_video, voice_clips[game.clip_index].timestamp);
    }
    stop_playback();
    if (!init_mic()) { set_message("Microphone unavailable"); return; }
    memset(mic_buffer, 0, MIC_BUFFER_SIZE);
    recording_bytes = 0;
    u32 sample_bytes = (u32)configured_record_seconds * MIC_RATE * 2u;
    if (sample_bytes > micGetSampleDataSize()) sample_bytes = micGetSampleDataSize() & ~1u;
    Result r = MICU_StartSampling(MICU_ENCODING_PCM16_SIGNED, MICU_SAMPLE_RATE_16360, 0, sample_bytes, false);
    if (R_FAILED(r)) { set_message("Microphone start failed"); return; }
    recording = true;
    recording_started_frame = frames;
    set_message("Recording...");
}

static void finish_recording(void) {
    if (!recording) return;
    stop_recording(true);
    if (!active_dub_pack && recording_bytes > 2048 && mic_buffer && auto_save_dub) {
        char latest[320];
        snprintf(latest, sizeof(latest), "%s/dub_latest.wav", REC_DIR);
        if (save_wav(latest, mic_buffer, recording_bytes, MIC_RATE, 1, 16)) {
            snprintf(game.last_recording, sizeof(game.last_recording), "%s", latest);
            set_message("Dub saved as latest");
        } else set_message("Could not save latest dub");
    }
}

/* -------------------------------------------------------------------------
 * Graphical Old 3DS UI.  It uses the original project's artwork and Waukegan
 * font rasterized on the build runner, so no desktop Godot renderer is needed.
 * Framebuffer conversion below handles the 3DS rotated-column BGR8 layout.
 * ------------------------------------------------------------------------- */
#define UI_BG_TOP       0xFF13272FULL
#define UI_BG_BOTTOM    0xFF5F9EAB
#define UI_CYAN         0xFF7BE0EE
#define UI_TEXT         0xFF17313A
#define UI_TEXT_LIGHT   0xFFF4FBFC
#define UI_DARK_PANEL   0xE6162D38
#define UI_BUTTON_TOP   0xFFD6EDF0
#define UI_BUTTON_BOT   0xFF91C3CD
#define UI_BUTTON_SEL   0xFFA8F1F6
#define UI_BORDER       0xFFF6FFFF
#define UI_ACCENT       0xFF3D9CAC
#define FONT_SMALL_W 12
#define FONT_SMALL_H 18
#define FONT_LARGE_W 16
#define FONT_LARGE_H 22

static uint8_t color_r(uint32_t c) { return (uint8_t)(c >> 16); }
static uint8_t color_g(uint32_t c) { return (uint8_t)(c >> 8); }
static uint8_t color_b(uint32_t c) { return (uint8_t)c; }

static uint32_t blend_color(uint32_t dst, uint32_t src, uint8_t a) {
    if (a == 255) return 0xFF000000u | (src & 0x00FFFFFFu);
    if (a == 0) return dst;
    unsigned inv = 255u - a;
    unsigned r = (color_r(src) * a + color_r(dst) * inv) / 255u;
    unsigned g = (color_g(src) * a + color_g(dst) * inv) / 255u;
    unsigned b = (color_b(src) * a + color_b(dst) * inv) / 255u;
    return 0xFF000000u | (r << 16) | (g << 8) | b;
}

static void c_pixel(Canvas *c, int x, int y, uint32_t color) {
    if (!c || !c->pixels || x < 0 || y < 0 || x >= c->w || y >= c->h) return;
    c->pixels[(size_t)y * (size_t)c->w + (size_t)x] = 0xFF000000u | (color & 0x00FFFFFFu);
}

static void c_blend_pixel(Canvas *c, int x, int y, uint32_t color, uint8_t alpha) {
    if (!c || !c->pixels || x < 0 || y < 0 || x >= c->w || y >= c->h || alpha == 0) return;
    size_t i = (size_t)y * (size_t)c->w + (size_t)x;
    c->pixels[i] = blend_color(c->pixels[i], color, alpha);
}

static void c_clear(Canvas *c, uint32_t color) {
    if (!c || !c->pixels) return;
    size_t n = (size_t)c->w * (size_t)c->h;
    uint32_t opaque = 0xFF000000u | (color & 0x00FFFFFFu);
    for (size_t i = 0; i < n; ++i) c->pixels[i] = opaque;
}

static void c_rect(Canvas *c, int x, int y, int w, int h, uint32_t color) {
    if (!c || !c->pixels || w <= 0 || h <= 0) return;
    int x0 = x < 0 ? 0 : x, y0 = y < 0 ? 0 : y;
    int x1 = x + w > c->w ? c->w : x + w;
    int y1 = y + h > c->h ? c->h : y + h;
    if (x1 <= x0 || y1 <= y0) return;
    uint32_t cc = 0xFF000000u | (color & 0x00FFFFFFu);
    for (int yy = y0; yy < y1; ++yy) {
        uint32_t *row = c->pixels + (size_t)yy * (size_t)c->w + (size_t)x0;
        for (int xx = x0; xx < x1; ++xx) *row++ = cc;
    }
}

static void c_rect_alpha(Canvas *c, int x, int y, int w, int h, uint32_t color, uint8_t a) {
    if (a == 255) { c_rect(c, x, y, w, h, color); return; }
    if (!c || !c->pixels || w <= 0 || h <= 0 || a == 0) return;
    int x0 = x < 0 ? 0 : x, y0 = y < 0 ? 0 : y;
    int x1 = x + w > c->w ? c->w : x + w;
    int y1 = y + h > c->h ? c->h : y + h;
    for (int yy = y0; yy < y1; ++yy) {
        size_t row = (size_t)yy * (size_t)c->w;
        for (int xx = x0; xx < x1; ++xx) {
            size_t i = row + (size_t)xx;
            c->pixels[i] = blend_color(c->pixels[i], color, a);
        }
    }
}

static void c_gradient(Canvas *c, int x, int y, int w, int h, uint32_t a, uint32_t b) {
    if (!c || !c->pixels || h <= 0 || w <= 0) return;
    int x0 = x < 0 ? 0 : x, y0 = y < 0 ? 0 : y;
    int x1 = x + w > c->w ? c->w : x + w;
    int y1 = y + h > c->h ? c->h : y + h;
    int denom = h > 1 ? h - 1 : 1;
    for (int yy = y0; yy < y1; ++yy) {
        int t = (yy - y) * 255 / denom;
        unsigned r = (color_r(a) * (255 - t) + color_r(b) * t) / 255u;
        unsigned g = (color_g(a) * (255 - t) + color_g(b) * t) / 255u;
        unsigned bl = (color_b(a) * (255 - t) + color_b(b) * t) / 255u;
        uint32_t cc = 0xFF000000u | (r << 16) | (g << 8) | bl;
        uint32_t *row = c->pixels + (size_t)yy * (size_t)c->w + (size_t)x0;
        for (int xx = x0; xx < x1; ++xx) *row++ = cc;
    }
}

static void c_line(Canvas *c, int x0, int y0, int x1, int y1, uint32_t color) {
    int dx = abs(x1 - x0), sx = x0 < x1 ? 1 : -1;
    int dy = -abs(y1 - y0), sy = y0 < y1 ? 1 : -1;
    int err = dx + dy;
    for (;;) {
        c_pixel(c, x0, y0, color);
        if (x0 == x1 && y0 == y1) break;
        int e2 = 2 * err;
        if (e2 >= dy) { err += dy; x0 += sx; }
        if (e2 <= dx) { err += dx; y0 += sy; }
    }
}

static void c_circle(Canvas *c, int cx, int cy, int radius, uint32_t color) {
    int x = radius, y = 0, err = 1 - x;
    while (x >= y) {
        c_pixel(c, cx+x, cy+y, color); c_pixel(c, cx+y, cy+x, color);
        c_pixel(c, cx-y, cy+x, color); c_pixel(c, cx-x, cy+y, color);
        c_pixel(c, cx-x, cy-y, color); c_pixel(c, cx-y, cy-x, color);
        c_pixel(c, cx+y, cy-x, color); c_pixel(c, cx+x, cy-y, color);
        ++y;
        if (err < 0) err += 2*y + 1;
        else { --x; err += 2*(y-x) + 1; }
    }
}

static bool load_sprite(Sprite *sp, const char *filename) {
    if (!sp || !filename) return false;
    memset(sp, 0, sizeof(*sp));
    char path[384];
    snprintf(path, sizeof(path), "%s/assets_native/%s", ROOT, filename);
    FILE *f = fopen(path, "rb");
    if (!f) return false;
    uint8_t header[8];
    if (fread(header, 1, sizeof(header), f) != sizeof(header) || memcmp(header, "TCVR", 4) != 0) {
        fclose(f); return false;
    }
    uint16_t w = (uint16_t)(header[4] | (header[5] << 8));
    uint16_t h = (uint16_t)(header[6] | (header[7] << 8));
    size_t bytes = (size_t)w * (size_t)h * 4u;
    if (!w || !h || w > 512 || h > 512 || bytes > 1024u * 1024u) { fclose(f); return false; }
    uint8_t *pixels = (uint8_t *)malloc(bytes);
    if (!pixels) { fclose(f); return false; }
    if (fread(pixels, 1, bytes, f) != bytes) { free(pixels); fclose(f); return false; }
    fclose(f);
    sp->w = w; sp->h = h; sp->rgba = pixels;
    return true;
}

static bool load_pack_sprite_path(Sprite *sp, const char *path) {
    if (!sp || !path) return false;
    memset(sp, 0, sizeof(*sp));
    FILE *f = fopen(path, "rb"); if (!f) return false;
    uint8_t header[8];
    if (fread(header, 1, sizeof(header), f) != sizeof(header) || memcmp(header, "TCVR", 4) != 0) {
        fclose(f); return false;
    }
    uint16_t w = (uint16_t)(header[4] | (header[5] << 8));
    uint16_t h = (uint16_t)(header[6] | (header[7] << 8));
    size_t bytes = (size_t)w * (size_t)h * 4u;
    if (!w || !h || w > 256 || h > 256 || bytes > 262144u) { fclose(f); return false; }
    uint8_t *pixels = (uint8_t *)malloc(bytes);
    if (!pixels) { fclose(f); return false; }
    if (fread(pixels, 1, bytes, f) != bytes) { free(pixels); fclose(f); return false; }
    fclose(f); sp->w = w; sp->h = h; sp->rgba = pixels; return true;
}

static void load_ui_assets(void) {
    for (int i = 0; i < SPR_COUNT; ++i) (void)load_sprite(&sprites[i], sprite_files[i]);
}

static void free_ui_assets(void) {
    for (int i = 0; i < SPR_COUNT; ++i) {
        free(sprites[i].rgba); sprites[i].rgba = NULL; sprites[i].w = sprites[i].h = 0;
    }
}

static void c_sprite_alpha(Canvas *c, const Sprite *sp, int x, int y, int w, int h, uint8_t opacity) {
    if (!c || !c->pixels || !sp || !sp->rgba || w <= 0 || h <= 0) return;
    int x0 = x < 0 ? 0 : x, y0 = y < 0 ? 0 : y;
    int x1 = x + w > c->w ? c->w : x + w;
    int y1 = y + h > c->h ? c->h : y + h;
    for (int dy = y0; dy < y1; ++dy) {
        int sy = (int)(((int64_t)(dy-y) * sp->h) / h);
        if (sy < 0) sy = 0;
        if (sy >= sp->h) sy = sp->h - 1;
        for (int dx = x0; dx < x1; ++dx) {
            int sx = (int)(((int64_t)(dx-x) * sp->w) / w);
            if (sx < 0) sx = 0;
            if (sx >= sp->w) sx = sp->w - 1;
            const uint8_t *src = sp->rgba + ((size_t)sy * sp->w + (size_t)sx) * 4u;
            uint8_t a = (uint8_t)(((unsigned)src[3] * opacity) / 255u);
            if (!a) continue;
            size_t idx = (size_t)dy * c->w + (size_t)dx;
            uint32_t cc = ((uint32_t)src[0] << 16) | ((uint32_t)src[1] << 8) | src[2];
            c->pixels[idx] = blend_color(c->pixels[idx], cc, a);
        }
    }
}

static void c_sprite(Canvas *c, int id, int x, int y, int w, int h) {
    if (id < 0 || id >= SPR_COUNT) return;
    c_sprite_alpha(c, &sprites[id], x, y, w, h, 255);
}

static int c_text_width(const char *text, bool large) {
    int adv = large ? 14 : 10;
    return text ? (int)strlen(text) * adv : 0;
}

static void c_text(Canvas *c, int x, int y, const char *text, uint32_t color, bool large, int max_width) {
    if (!c || !text) return;
    const Sprite *font = &sprites[large ? SPR_FONT_LARGE : SPR_FONT_SMALL];
    int cw = large ? FONT_LARGE_W : FONT_SMALL_W;
    int ch = large ? FONT_LARGE_H : FONT_SMALL_H;
    int adv = large ? 14 : 10;
    if (!font->rgba) {
        /* An asset bundle is required for the rasterized original font. */
        return;
    }
    int n = (int)strlen(text);
    if (max_width > 0 && adv * n > max_width) n = max_width / adv;
    for (int ci = 0; ci < n; ++ci) {
        unsigned char code = (unsigned char)text[ci];
        if (code < 32 || code > 127) code = '?';
        int k = (int)code - 32;
        int sx0 = (k % 16) * cw, sy0 = (k / 16) * ch;
        for (int gy = 0; gy < ch; ++gy) {
            int dy = y + gy;
            if (dy < 0 || dy >= c->h) continue;
            for (int gx = 0; gx < cw; ++gx) {
                int dx = x + ci * adv + gx;
                if (dx < 0 || dx >= c->w || (max_width > 0 && dx >= x + max_width)) continue;
                const uint8_t *sp = font->rgba + ((size_t)(sy0 + gy) * font->w + (size_t)(sx0 + gx)) * 4u;
                if (sp[3]) c_blend_pixel(c, dx, dy, color, sp[3]);
            }
        }
    }
}

static void c_text_center(Canvas *c, int x, int y, int width, const char *text, uint32_t color, bool large) {
    int tw = c_text_width(text, large);
    int tx = x + (width - tw) / 2;
    if (tx < x) tx = x;
    c_text(c, tx, y, text, color, large, width);
}

static void ui_background(Canvas *c, int variant) {
    c_gradient(c, 0, 0, c->w, c->h, UI_BG_TOP, UI_BG_BOTTOM);
    /* The original menu uses soft cyan circles and a gray/cyan letterbox accent. */
    for (int i = 0; i < 9; ++i) {
        int x = c->w - 24 - i * 13;
        int y = 32 + (i % 3) * 61;
        c_circle(c, x, y, 20 + (i % 4) * 7, (i % 2) ? 0xFF6AB8C5 : 0xFF488D9A);
    }
    for (int y = 0; y < c->h; y += 12) c_line(c, 0, y, c->w, y, 0xFF366D79);
    c_rect_alpha(c, 0, 0, c->w, c->h, 0xFF07141A, 36);
    if (variant == 1) {
        c_sprite_alpha(c, &sprites[SPR_GAMESHOW_SCENE], 0, 4, c->w, c->h - 8, 218);
        c_rect_alpha(c, 0, 0, c->w, c->h, 0xFF081A24, 72);
    } else if (variant == 2) {
        c_sprite_alpha(c, &sprites[SPR_PANELIST_SCENE], 0, 4, c->w, c->h - 8, 220);
        c_rect_alpha(c, 0, 0, c->w, c->h, 0xFF081A24, 70);
    } else if (variant == 3) {
        c_sprite_alpha(c, &sprites[SPR_DUB_STANDARD], 0, 4, c->w, c->h - 8, 222);
        c_rect_alpha(c, 0, 0, c->w, c->h, 0xFF081A24, 72);
    }
    (void)variant;
}

static void top_title(const char *title, const char *subtitle) {
    c_rect_alpha(&top_canvas, 9, 8, 281, 48, UI_DARK_PANEL, 225);
    c_rect(&top_canvas, 9, 8, 4, 48, UI_CYAN);
    c_text(&top_canvas, 21, 12, title, UI_TEXT_LIGHT, true, 262);
    if (subtitle) c_text(&top_canvas, 21, 37, subtitle, 0xFFE0F7FB, false, 255);
}

static void bottom_header(const char *title, const char *hint) {
    ui_background(&bottom_canvas, 0);
    c_rect_alpha(&bottom_canvas, 0, 0, 320, 32, 0xFF102732, 242);
    c_rect(&bottom_canvas, 0, 30, 320, 2, UI_CYAN);
    c_text(&bottom_canvas, 9, 5, title, UI_TEXT_LIGHT, true, 294);
    if (hint && *hint) c_text(&bottom_canvas, 8, 198, hint, UI_TEXT_LIGHT, false, 302);
    c_rect_alpha(&bottom_canvas, 0, 220, 320, 20, 0xFF0D2029, 240);
    c_text(&bottom_canvas, 6, 222, "A SELECT   B BACK   TOUCH TO CHOOSE", 0xFFCDEDF1, false, 308);
    if (message_timer > 0 && message[0]) {
        c_rect_alpha(&bottom_canvas, 5, 179, 310, 18, 0xFF07141A, 205);
        c_text(&bottom_canvas, 10, 181, message, 0xFFFFF1A6, false, 300);
    }
}

static void ui_reset_buttons(void) { touch_button_count = 0; }

static void ui_button(Canvas *c, int x, int y, int w, int h, const char *label, int id, bool active) {
    if (touch_button_count < (int)(sizeof(touch_buttons)/sizeof(touch_buttons[0]))) {
        touch_buttons[touch_button_count++] = (TouchButton){x, y, w, h, label, id};
    }
    c_rect(c, x + 2, y + 3, w, h, 0xFF24414A);
    c_gradient(c, x, y, w, h, active ? UI_BUTTON_SEL : UI_BUTTON_TOP, active ? 0xFF65BCCB : UI_BUTTON_BOT);
    c_rect(c, x, y, w, 2, UI_BORDER);
    c_rect(c, x, y, 2, h, UI_BORDER);
    c_rect(c, x + w - 2, y, 2, h, active ? UI_CYAN : 0xFF678F98);
    c_rect(c, x, y + h - 2, w, 2, active ? UI_ACCENT : 0xFF4C8792);
    c_line(c, x + 5, y + 4, x + w - 6, y + 4, 0xFFEDFDFE);
    int adv = 10;
    int textw = c_text_width(label, false);
    int tx = x + (w - textw) / 2;
    bool large = false;
    if (tx < x + 4) { adv = 8; textw = (int)strlen(label) * adv; tx = x + (w-textw)/2; }
    (void)adv;
    c_text_center(c, x + 3, y + (h - FONT_SMALL_H) / 2, w - 6, label, UI_TEXT, large);
    if (active) {
        c_rect(c, x + 5, y + h - 4, 20, 2, UI_CYAN);
    }
}

static void ui_grid(const char **labels, int count, int active, int cols) {
    int rows = (count + cols - 1) / cols;
    int margin = cols == 2 ? 8 : 5;
    int gap = cols == 2 ? 8 : 5;
    int w = (320 - 2*margin - (cols-1)*gap) / cols;
    int h = rows >= 4 ? 27 : 30;
    int gap_y = rows >= 4 ? 31 : 35;
    int start_y = rows >= 4 ? 39 : 40;
    for (int i = 0; i < count; ++i) {
        int col = i % cols, row = i / cols;
        ui_button(&bottom_canvas, margin + col*(w+gap), start_y + row*gap_y, w, h,
                  labels[i], i, i == active);
    }
}

static void ui_common_top(const char *title, const char *subtitle, int scene) {
    ui_background(&top_canvas, scene);
    top_title(title, subtitle);
    c_rect(&top_canvas, 10, 227, 380, 2, UI_CYAN);
    c_text(&top_canvas, 12, 229, "THE CHOICER VOICER  /  OLD 3DS EDITION", 0xFFDFF8FB, false, 374);
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
    static const char *n[] = {"PLAYER PACK", "VOICE PACK", "HOST PACK", "JUDGE PACK", "STUDIO PACK"};
    return n[row < 5 ? row : 0];
}

static void draw_selected_character(void) {
    int hero = SPR_HOST;
    if (page == PAGE_SETUP || page == PAGE_MEMBERS) hero = SPR_PLAYER;
    else if (page == PAGE_CREDITS) hero = SPR_DEV_LOGO;
    else if (page == PAGE_CUSTOMIZE && pack_type == 1) hero = SPR_PLAYER;
    else if (page == PAGE_CUSTOMIZE && pack_type == 3) hero = SPR_JUDGE1;
    c_sprite(&top_canvas, hero, 292, 54, 98, 166);
}

static void page_home(void) {
    ui_background(&top_canvas, 0);
    c_sprite(&top_canvas, SPR_LOGO_BANNER, 15, 20, 250, 94);
    c_text(&top_canvas, 22, 124, "VOICE ACTING PARTY GAME", UI_TEXT_LIGHT, true, 248);
    c_text(&top_canvas, 22, 151, "Choose a clip. Record your take.", 0xFFD9F5F8, false, 250);
    c_text(&top_canvas, 22, 169, "Watch it back. Save your dub.", 0xFFD9F5F8, false, 250);
    c_sprite(&top_canvas, SPR_HOST, 275, 15, 118, 211);
    c_sprite(&top_canvas, SPR_DEV_LOGO, 18, 190, 93, 43);
    c_rect_alpha(&top_canvas, 9, 8, 256, 9, 0xFF11252D, 110);
    c_text(&top_canvas, 15, 9, "VERSION 0.5.x  -  NATIVE CONVERSION", 0xFFE3F9FC, false, 244);

    static const char *b[] = {"PLAY", "CUSTOMIZE", "OPEN GAME FOLDER", "SETTINGS", "DATA MANAGEMENT", "EXTRAS", "MODPACK GUIDES", "CREDITS"};
    bottom_header("MAIN MENU", "Original TCV art, packs and audio are loaded from SD.");
    ui_grid(b, 8, selected, 2);
}

static void page_play(void) {
    ui_common_top("PLAY", "Select the way you want to play", 0);
    c_sprite(&top_canvas, SPR_GAMESHOW_SCENE, 20, 67, 250, 141);
    c_text(&top_canvas, 25, 190, "A GAMESHOW / DUBBING STUDIO", UI_TEXT_LIGHT, false, 255);
    static const char *b[] = {"GAMESHOW MODE", "DUB MODE", "DUB CINEMA", "BACK"};
    bottom_header("PLAY", "Choose a mode to configure your session."); ui_grid(b, 4, selected, 2);
}

static void page_mode(void) {
    ui_common_top("GAME OPTIONS", game.mode == 0 ? "Gameshow configuration" : "Dubbing mode configuration", 0);
    c_rect_alpha(&top_canvas, 18, 74, 258, 124, UI_DARK_PANEL, 220);
    c_text(&top_canvas, 28, 85, "CURRENT MODE", UI_CYAN, false, 230);
    c_text(&top_canvas, 28, 108, game.mode == 0 ? "GAMESHOW" : "DUB MODE", UI_TEXT_LIGHT, true, 230);
    char buf[64]; snprintf(buf, sizeof(buf), "ROUNDS: %d", game.total_rounds);
    c_text(&top_canvas, 28, 143, buf, UI_TEXT_LIGHT, false, 220);
    c_text(&top_canvas, 28, 169, "Next: select contestant count", 0xFFD7EEF1, false, 236);
    static const char *b[] = {"GAMESHOW", "DUB MODE", "ROUNDS -", "ROUNDS +", "NEXT", "BACK"};
    bottom_header("PLAY OPTIONS", "Select mode and number of rounds."); ui_grid(b, 6, selected, 2);
}

static void page_members(void) {
    ui_common_top("CONTESTANTS", "Choose how many player slots are active", 2);
    c_rect_alpha(&top_canvas, 18, 76, 255, 116, UI_DARK_PANEL, 220);
    char buf[64]; snprintf(buf, sizeof(buf), "%d ACTIVE PLAYER%s", game.member_count, game.member_count == 1 ? "" : "S");
    c_text(&top_canvas, 28, 86, buf, UI_TEXT_LIGHT, true, 232);
    for (int i=0;i<MAX_PLAYERS;i++) {
        int x=29+i*53;
        c_circle(&top_canvas,x+13,135,13,i<game.member_count?UI_CYAN:0xFF45616A);
        c_text_center(&top_canvas,x,128,26,i<game.member_count?"ON":"-",UI_TEXT,true);
        c_text_center(&top_canvas,x-3,154,34,(i==0?"P1":i==1?"P2":i==2?"P3":"P4"),UI_TEXT_LIGHT,false);
    }
    c_sprite(&top_canvas, SPR_PLAYER, 300, 77, 81, 143);
    static const char *b[] = {"1 PLAYER", "2 PLAYERS", "3 PLAYERS", "4 PLAYERS", "NEXT", "BACK"};
    bottom_header("CONTESTANTS", "Choose one to four players."); ui_grid(b, 6, selected, 2);
}

static void page_setup(void) {
    ui_common_top("MATCH SETUP", "Pick the packs used by this session", 0);
    c_rect_alpha(&top_canvas, 16, 66, 266, 142, UI_DARK_PANEL, 220);
    for (int i=0;i<5;i++) {
        int *v=setup_value_ptr(i);
        char buf[64]; snprintf(buf,sizeof(buf),"%s: #%d",setup_name(i),v?*v+1:1);
        c_text(&top_canvas,26,76+i*25,buf,(i==selected/2)?UI_CYAN:UI_TEXT_LIGHT,false,240);
    }
    char info[64]; snprintf(info,sizeof(info),"ROUND %d / %d",game.round+1,game.total_rounds);
    c_text(&top_canvas,28,190,info,0xFFD7EEF1,false,230);
    c_sprite(&top_canvas, SPR_HOST, 301, 63, 82, 155);
    static const char *b[] = {"PLAYER -", "PLAYER +", "VOICE -", "VOICE +", "HOST -", "HOST +", "JUDGE -", "JUDGE +", "STUDIO -", "STUDIO +", "START", "BACK"};
    bottom_header("MATCH SETUP", "Tap minus/plus to change packs."); ui_grid(b, 12, selected, 3);
}

static int current_clip_sprite(void) {
    switch ((game.clip_index % 5 + 5) % 5) {
        case 0: return SPR_CLIP1;
        case 1: return SPR_CLIP2;
        case 2: return SPR_CLIP3;
        case 3: return SPR_CLIP4;
        default: return SPR_CLIP5;
    }
}

static void game_top(void) {
    if (active_dub_pack && dub_video.opened && game.clip_index >= 0 && game.clip_index < voice_clip_count) {
        ui_common_top("DUB MODE", active_pack_name, 3);
        draw_tcv_video(&top_canvas, 40, 57, 320, 180);
        if (active_clip_art.rgba) {
            c_rect_alpha(&top_canvas, 6, 174, 58, 62, 0xFF081A24, 230);
            c_sprite_alpha(&top_canvas, &active_clip_art, 9, 177, 52, 56, 255);
        }
        c_rect_alpha(&top_canvas, 40, 207, 320, 30, 0xFF081A24, 225);
        char line[64]; snprintf(line, sizeof(line), "LINE %d / %d", game.clip_index + 1, voice_clip_count);
        c_text(&top_canvas, 46, 210, line, UI_CYAN, true, 90);
        if (recording) c_text(&top_canvas, 257, 211, "REC", 0xFFFF6E8A, true, 90);
        else if (dub_replay_active) c_text(&top_canvas, 257, 211, "PLAYING", UI_CYAN, true, 90);
        if (show_subtitles && game_subtitle[0]) c_text(&top_canvas, 46, 226, game_subtitle, UI_TEXT_LIGHT, false, 306);
        return;
    }
    ui_common_top(game.mode == 1 ? "DUB STUDIO" : "GAMESHOW ROUND", "The original tutorial clips and contestant art", 1);
    c_rect_alpha(&top_canvas, 12, 63, 154, 148, 0xFF0C1C24, 212);
    if (active_clip_art.rgba) c_sprite_alpha(&top_canvas, &active_clip_art, 20, 72, 102, 102, 255);
    else c_sprite(&top_canvas, current_clip_sprite(), 20, 72, 102, 102);
    char buf[64]; snprintf(buf,sizeof(buf),"CLIP %d",game.clip_index+1);
    c_text(&top_canvas,23,181,buf,UI_CYAN,true,132);
    snprintf(buf,sizeof(buf),"ROUND %d/%d",game.round+1,game.total_rounds);
    c_text(&top_canvas,23,204,buf,UI_TEXT_LIGHT,false,130);
    c_sprite(&top_canvas, SPR_HOST, 286, 52, 105, 170);
    if (show_subtitles && game_subtitle[0]) {
        c_rect_alpha(&top_canvas, 16, 57, 260, 17, 0xFF081A24, 220);
        c_text(&top_canvas, 21, 57, game_subtitle, UI_TEXT_LIGHT, false, 250);
    }
    if (game_speedups) c_text(&top_canvas, 180, 190, "FAST SCORE DISPLAY", UI_CYAN, false, 100);
    c_rect_alpha(&top_canvas, 174, 76, 106, 86, UI_DARK_PANEL, 228);
    c_text(&top_canvas, 183, 85, "CONTESTANTS", UI_CYAN, false, 88);
    for (int i=0;i<game.member_count;i++) {
        char p[24]; snprintf(p,sizeof(p),"P%d  %d",i+1,game.score[i]);
        c_text(&top_canvas,184,106+i*19,p,UI_TEXT_LIGHT,false,88);
    }
    if (recording) c_text(&top_canvas, 180, 172, "REC", 0xFFFF6E8A, true, 80);
    else if (playback_active) c_text(&top_canvas, 180, 172, "PLAYING", UI_CYAN, false, 95);
}

static void draw_game_touch_ui(void) {
    const char *a = recording ? "STOP & SAVE" : (active_dub_pack ? "RECORD LINE" : "START");
    ui_button(&bottom_canvas, 8, 145, 148, 30, a, 0, selected==0);
    ui_button(&bottom_canvas, 164, 145, 148, 30, "NEXT", 1, selected==1);
    ui_button(&bottom_canvas, 8, 181, 148, 30, "WATCH DUB", 2, selected==2);
    ui_button(&bottom_canvas, 164, 181, 148, 30, "SAVE DUB", 3, selected==3);
}

static void draw_waveform(bool live) {
    int sprite = waveform_mode == 1 ? SPR_WAVE_TIMING : waveform_mode == 2 ? SPR_WAVE_LOUD : live ? SPR_WAVE_GOOD : SPR_WAVE_QUIET;
    c_rect_alpha(&bottom_canvas, 6, 36, 308, 104, 0xFF101D24, 220);
    c_sprite(&bottom_canvas, sprite, 9, 38, 302, 99);
    if (live) {
        c_sprite(&bottom_canvas, SPR_MIC, 13, 44, 25, 45);
        c_rect_alpha(&bottom_canvas, 43, 43, 86, 17, 0xFF0B202A, 215);
        c_text(&bottom_canvas, 48, 43, recording ? "RECORDING" : "PLAYING DUB", 0xFFFFD6DE, false, 78);
    }
    /* During recording overlay a real low-cost level trace on the original waveform art. */
    if (recording && mic_ready && mic_buffer) {
        uint32_t byte_count = micGetLastSampleOffset();
        uint32_t byte_cap = micGetSampleDataSize();
        if (byte_count > byte_cap) byte_count = byte_cap;
        size_t samples = (size_t)(byte_count / 2u);
        if (samples > 0) {
            size_t window = samples < 4096u ? samples : 4096u;
            size_t base = samples - window;
            for (int i = 0; i < 34; ++i) {
                size_t begin = base + (window * (size_t)i) / 34u;
                size_t end = base + (window * (size_t)(i+1)) / 34u;
                if (end <= begin) end = begin + 1;
                if (end > samples) end = samples;
                uint64_t sum = 0; size_t n = 0;
                for (size_t j = begin; j < end; ++j) {
                    int32_t v = ((const int16_t *)mic_buffer)[j];
                    sum += (uint32_t)(v < 0 ? -v : v); ++n;
                }
                int h = n ? (int)((sum / n) / 600u) : 1;
                h = clamp_int(h, 2, 28);
                int x = 25 + i * 8;
                c_rect_alpha(&bottom_canvas, x, 111 - h, 4, h, UI_CYAN, 230);
            }
        }
    }
}

static void page_game(void) {
    game_top(); bottom_header(game.mode==1?"DUB CONTROLS":"GAMESHOW CONTROLS", "Stylus controls: start, next, review or save.");
    draw_waveform(recording || playback_active); draw_game_touch_ui();
    if (game.last_recording[0]) c_text(&bottom_canvas, 9, 126, "DUB READY", UI_TEXT_LIGHT, false, 100);
}

static void page_results(void) {
    ui_common_top("RESULTS", "Round scores and judges", 2);
    c_rect_alpha(&top_canvas, 17, 68, 258, 137, UI_DARK_PANEL, 225);
    c_text(&top_canvas, 28, 78, "PANEL SCOREBOARD", UI_CYAN, true, 234);
    for (int i=0;i<game.member_count;i++) {
        char buf[64]; snprintf(buf,sizeof(buf),"PLAYER %d",i+1);
        int score=game.score[i]*20; if(score>100) score=100;
        c_text(&top_canvas,28,110+i*24,buf,UI_TEXT_LIGHT,false,120);
        c_rect(&top_canvas,139,111+i*24,110,12,0xFF29444D);
        c_rect(&top_canvas,139,111+i*24,score,12,UI_CYAN);
        snprintf(buf,sizeof(buf),"%d",score); c_text(&top_canvas,253,108+i*24,buf,UI_TEXT_LIGHT,false,20);
    }
    for (int i=0;i<3;i++) c_sprite(&top_canvas, SPR_JUDGE1+i, 286+i*34, 98, 34, 76);
    static const char *b[]={"NEXT ROUND","WATCH DUB","SAVE DUB","SETUP","HOME","REPLAY"};
    bottom_header("RESULTS", "Your score summary is native and saved."); ui_grid(b,6,selected,2);
}

static void page_dub(void) {
    ui_common_top("DUB CINEMA", "The actual tutorial art and dubbing controls", 3);
    c_sprite(&top_canvas, current_clip_sprite(), 25, 68, 118, 118);
    c_sprite(&top_canvas, SPR_HOST, 286, 50, 106, 174);
    c_rect_alpha(&top_canvas, 153, 79, 122, 106, UI_DARK_PANEL, 220);
    c_text(&top_canvas,161,90,"YOUR TAKE",UI_CYAN,false,105);
    c_text(&top_canvas,161,115,recording?"RECORDING":"READY",UI_TEXT_LIGHT,true,106);
    c_text(&top_canvas,161,146,"Review the",UI_TEXT_LIGHT,false,106);
    c_text(&top_canvas,161,163,"dub below.",UI_TEXT_LIGHT,false,106);
    bottom_header("DUB CONTROLS", "Waveform and actions stay on the lower screen.");
    draw_waveform(recording || playback_active); draw_game_touch_ui();
}

static void page_packs(void) {
    ui_common_top("CONTENT BROWSER", "Original pack categories and defaults", 0);
    c_rect_alpha(&top_canvas,18,72,257,132,UI_DARK_PANEL,225);
    c_text(&top_canvas,28,82,"CONTENT PACKS",UI_CYAN,true,232);
    for(int i=0;i<7;i++) {
        char buf[60]; int current_index = i==0?game.voice:i==1?game.player:i==2?game.host:i==3?game.judge:i==4?game.studio:i==5?game.menu:game.twitch; snprintf(buf,sizeof(buf),"%s  (%d)",pack_labels[i],current_index+1);
        c_text(&top_canvas,29,109+i*16,buf,i==pack_type?UI_CYAN:UI_TEXT_LIGHT,false,231);
    }
    c_sprite(&top_canvas, pack_type==2?SPR_HOST:pack_type==3?SPR_JUDGE1:pack_type==0?SPR_CLIP1:SPR_PLAYER, 307, 76, 76, 148);
    static const char *b[]={"VOICE", "PLAYER", "HOST", "JUDGES", "STUDIO", "MENU", "TWITCH", "BACK"};
    bottom_header("PACK CATEGORIES", "Browse original and user-installed packs."); ui_grid(b,8,selected,2);
}

static void page_customize(void) {
    ui_common_top("CUSTOMIZE", "Choose the voice, contestant, host, judges or studio", 0);
    c_rect_alpha(&top_canvas,14,70,266,137,UI_DARK_PANEL,220);
    c_text(&top_canvas,25,80,"ACTIVE PACK INDICES",UI_CYAN,false,238);
    const char *names[]={"PLAYER","VOICE","HOST","JUDGE","STUDIO"};
    int vals[]={game.player,game.voice,game.host,game.judge,game.studio};
    for(int i=0;i<5;i++){char b[48];snprintf(b,sizeof(b),"%s  #%d",names[i],vals[i]+1);c_text(&top_canvas,27,105+i*19,b,UI_TEXT_LIGHT,false,235);}
    draw_selected_character();
    static const char *b[]={"VOICE PACKS","PLAYER PACKS","HOST PACKS","JUDGE PACKS","STUDIO PACKS","MENU PACKS","OPEN PACK BROWSER","BACK"};
    bottom_header("CUSTOMIZE", "Uses the real default packs supplied with the game."); ui_grid(b,8,selected,2);
}

static void page_pack_list(void) {
    list_pack_dir(pack_type, &last_packs);
    ui_common_top("PACK SELECTION", pack_labels[pack_type], 0);
    c_rect_alpha(&top_canvas,18,72,258,132,UI_DARK_PANEL,225);
    c_text(&top_canvas,28,82,pack_labels[pack_type],UI_CYAN,true,230);
    int visible=last_packs.count<4?last_packs.count:4;
    if (visible <= 0) visible = 1;
    int max_offset = last_packs.count > visible ? last_packs.count - visible : 0;
    pack_scroll_offset = clamp_int(pack_scroll_offset, 0, max_offset);
    if (pack_selected < pack_scroll_offset) pack_scroll_offset = pack_selected;
    if (pack_selected >= pack_scroll_offset + visible) pack_scroll_offset = pack_selected - visible + 1;
    pack_scroll_offset = clamp_int(pack_scroll_offset, 0, max_offset);
    for(int i=0;i<visible;i++) {
        int item_index = pack_scroll_offset + i;
        if (item_index >= last_packs.count) break;
        const char *name = last_packs.count ? last_packs.items[item_index].name : "No packs found";
        char label[100]; snprintf(label,sizeof(label),"%c %.82s",item_index==pack_selected?'>':' ',name);
        c_text(&top_canvas,29,111+i*20,label,item_index==pack_selected?UI_CYAN:UI_TEXT_LIGHT,false,231);
    }
    c_text(&top_canvas,28,201,"TAP PACK OR PRESS A TO USE",0xFFD7EEF1,false,240);
    c_sprite(&top_canvas, pack_type==2?SPR_HOST:pack_type==3?SPR_JUDGE1:SPR_PLAYER, 306,76,76,146);
    bottom_header("PACK SELECTION", "Tap a pack row; use PREV/NEXT or A/B.");
    for (int i=0; i<visible && touch_button_count<24; ++i) {
        int y=38+i*27;
        int item_index = pack_scroll_offset + i;
        if (item_index >= last_packs.count) break;
        const char *name = last_packs.items[item_index].name;
        bool active_row = item_index==pack_selected || selected==4+i;
        c_rect_alpha(&bottom_canvas,7,y,306,23,active_row?0xFF79D7E5:0xFFDBEFF1,active_row?235:195);
        c_rect(&bottom_canvas,7,y,3,23,active_row?UI_ACCENT:UI_BORDER);
        c_text(&bottom_canvas,15,y+3,name,UI_TEXT,false,290);
        touch_buttons[touch_button_count++]=(TouchButton){7,y,306,23,name,10+item_index};
    }
    static const char *controls[] = {"PREV", "NEXT", "USE", "BACK"};
    for(int i=0;i<4;i++) ui_button(&bottom_canvas,5+i*78,150,74,27,controls[i],i,selected==i);
}

static void page_settings(void) {
    ui_common_top("SETTINGS", "Native versions of the game's settings panels", 0);
    c_rect_alpha(&top_canvas,18,72,258,132,UI_DARK_PANEL,225);
    c_text(&top_canvas,28,82,"GAME CONFIGURATION",UI_CYAN,true,230);
    const char *lines[]={"Audio / music / sound effects","Microphone / recording duration","Display / waveform / interface","Dub behavior / subtitles","Gameshow / rounds / scoring","Twitch options (disabled on 3DS)"};
    for(int i=0;i<6;i++) c_text(&top_canvas,29,109+i*16,lines[i],UI_TEXT_LIGHT,false,230);
    static const char *b[]={"AUDIO","MICROPHONE","DISPLAY","DUB OPTIONS","GAMESHOW","TWITCH / ONLINE","SAVE SETTINGS","BACK"};
    bottom_header("SETTINGS", "Settings persist in saves/save.json."); ui_grid(b,8,selected,2);
}

static void page_setting_detail(void) {
    ui_common_top(settings_group==0?"AUDIO SETTINGS":settings_group==1?"MICROPHONE":settings_group==2?"DISPLAY":settings_group==3?"DUB OPTIONS":settings_group==4?"GAMESHOW": "TWITCH / ONLINE",
                  "Use the touch buttons to change options", 0);
    c_rect_alpha(&top_canvas,18,70,258,137,UI_DARK_PANEL,225);
    const char *lines[6]; int n=0; char vals[6][64];
    if(settings_group==0){
        snprintf(vals[0],64,"Music volume: %d/10",music_volume); snprintf(vals[1],64,"SFX volume: %d/10",sfx_volume);
        static const char *tracks[]={"Cartridge loop","Studio music","Tutorial loop","Main theme","TCV polling"};
        snprintf(vals[2],64,"Track: %s",tracks[music_track%5]);
        lines[0]=vals[0];lines[1]=vals[1];lines[2]=vals[2];lines[3]="Original button SFX enabled";lines[4]="PCM streaming keeps RAM use low";n=5;
    } else if(settings_group==1){
        snprintf(vals[0],64,"Microphone gain: %d",mic_gain);snprintf(vals[1],64,"Record limit: %d seconds",configured_record_seconds);
        lines[0]=mic_ready?"Microphone: INITIALIZED":"Microphone: not initialized";lines[1]=vals[0];lines[2]=vals[1];lines[3]="PCM 16-bit mono recording";lines[4]="Latest dub writes to recordings/";n=5;
    } else if(settings_group==2){
        lines[0]="Waukegan LDO font is used";lines[1]="Original color palette: cyan/gray";
        lines[2]=waveform_mode==0?"Waveform: original / good":waveform_mode==1?"Waveform: timing": "Waveform: loud";
        lines[3]=show_help_overlays?"Help overlays: ON":"Help overlays: OFF";lines[4]="Screen effects are hardware-light";n=5;
    } else if(settings_group==3){
        lines[0]=auto_save_dub?"Auto-save dub: ON":"Auto-save dub: OFF";
        lines[1]=auto_next_round?"Auto-next round: ON":"Auto-next round: OFF";
        lines[2]=show_subtitles?"Subtitles: ON":"Subtitles: OFF";
        lines[3]="Waveform and controls remain below";n=4;
    } else if(settings_group==4){
        snprintf(vals[0],64,"Rounds: %d",game.total_rounds);snprintf(vals[1],64,"Players: %d",game.member_count);
        lines[0]=vals[0];lines[1]=vals[1];lines[2]=game_speedups?"Show speedups: ON":"Show speedups: OFF";
        lines[3]="Scores and rounds are saved";n=4;
    } else {
        lines[0]="Desktop Twitch addon is not available";lines[1]="The 3DS port has no Twitch login";
        lines[2]="Offline play, packs and recording work";lines[3]="Network settings are not changed";n=4;
    }
    for(int i=0;i<n;i++) c_text(&top_canvas,28,85+i*21,lines[i],i==selected?UI_CYAN:UI_TEXT_LIGHT,false,237);
    const char *b_audio[]={"MUSIC -","MUSIC +","SFX -","SFX +","NEXT TRACK","TEST SOUND","SAVE","BACK"};
    const char *b_mic[]={"INIT MIC","GAIN -","GAIN +","TIME -","TIME +","TEST RECORD","SAVE","BACK"};
    const char *b_disp[]={"WAVE -","WAVE +","HELP TOGGLE","FONT INFO","RESET UI","SAVE","BACK","HOME"};
    const char *b_dub[]={"AUTO SAVE","AUTO NEXT","SUBTITLES","SHOW HELP","SAVE","BACK"};
    const char *b_game[]={"ROUNDS -","ROUNDS +","PLAYERS -","PLAYERS +","SPEEDUPS","SAVE","BACK"};
    const char *b_net[]={"INFO","BACK"};
    bottom_header("SETTINGS OPTIONS", "Changes are stored on SD when saved.");
    const char **b=settings_group==0?b_audio:settings_group==1?b_mic:settings_group==2?b_disp:settings_group==3?b_dub:settings_group==4?b_game:b_net;
    int count=settings_group==0?8:settings_group==1?8:settings_group==2?8:settings_group==3?6:settings_group==4?7:2;
    ui_grid(b,count,selected,count>6?2:2);
}

static void page_data(void) {
    ui_common_top("DATA MANAGEMENT", "Save files, recordings and imported packs", 0);
    c_rect_alpha(&top_canvas,18,72,260,132,UI_DARK_PANEL,220);
    c_text(&top_canvas,27,82,"SD CARD DATA",UI_CYAN,true,232);
    c_text(&top_canvas,27,109,"/luma/3ds/The Choicer Voicer/",UI_TEXT_LIGHT,false,242);
    c_text(&top_canvas,27,132,"saves/save.json",UI_TEXT_LIGHT,false,232);
    c_text(&top_canvas,27,152,"recordings/*.wav",UI_TEXT_LIGHT,false,232);
    c_text(&top_canvas,27,179,"Reset only clears this native save.",0xFFFFDDA8,false,242);
    static const char *b[]={"SAVE NOW","RESET STATE","LIST RECORDINGS","PACKS","BACK"};
    bottom_header("DATA MANAGEMENT", "Original voice packs are kept separate from saves."); ui_grid(b,5,selected,2);
}

static void page_extras(void) {
    ui_common_top("EXTRAS", "Help, tutorial, dubbing cinema and credits", 0);
    c_sprite(&top_canvas, SPR_HELP_PACKGUIDE, 22, 73, 260, 120);
    c_sprite(&top_canvas, SPR_HOST, 305, 66, 80, 145);
    static const char *b[]={"SHAE'S HELP","EDIT VOICE PACKS","DUB CINEMA","CREDITS","BACK"};
    bottom_header("EXTRAS", "Extra utilities from the original game flow."); ui_grid(b,5,selected,2);
}

static void page_guide(void) {
    ui_common_top("SHAE'S HELP", "Original help illustrations from the PC project", 0);
    int sid=guide_page%4==0?SPR_HELP_PACKGUIDE:guide_page%4==1?SPR_HELP_JUDGES:guide_page%4==2?SPR_HELP_SCORE:SPR_HELP_PERFORMANCE;
    c_sprite(&top_canvas,sid,14,64,292,158);
    c_sprite(&top_canvas,SPR_HOST,317,76,70,145);
    static const char *b[]={"PREVIOUS GUIDE","NEXT GUIDE","PACK PATHS","BACK"};
    bottom_header("GUIDE", guide_page%4==0?"Custom packs and folders":guide_page%4==1?"Judge configuration":guide_page%4==2?"Scoring and results":"Voice performance"); ui_grid(b,4,selected,2);
}

static void page_credits(void) {
    ui_common_top("CREDITS", "The Choicer Voicer's original contributors", 0);
    c_rect_alpha(&top_canvas,18,67,260,144,UI_DARK_PANEL,220);
    c_sprite(&top_canvas, SPR_DEV_LOGO, 28, 78, 100, 57);
    if(credits_page==0){
        c_sprite(&top_canvas,SPR_CREDIT_VINNY,29,146,42,42);c_text(&top_canvas,76,151,"VINNY VINESAUCE",UI_TEXT_LIGHT,false,180);
        c_sprite(&top_canvas,SPR_CREDIT_PIERCE,157,146,42,42);c_text(&top_canvas,204,151,"PIERCE",UI_TEXT_LIGHT,false,65);
    } else {
        c_sprite(&top_canvas,SPR_CREDIT_JIMMY,28,83,45,45);c_text(&top_canvas,77,96,"JIMMY",UI_TEXT_LIGHT,false,86);
        c_sprite(&top_canvas,SPR_CREDIT_KIOPHEN,164,83,45,45);c_text(&top_canvas,213,96,"KIOPHEN",UI_TEXT_LIGHT,false,64);
        c_sprite(&top_canvas,SPR_CREDIT_AZURE,28,143,45,45);c_text(&top_canvas,77,156,"AZUREOTSU",UI_TEXT_LIGHT,false,86);
        c_sprite(&top_canvas,SPR_CREDIT_MADCLOWN,164,143,45,45);c_text(&top_canvas,213,156,"MADCLOWN",UI_TEXT_LIGHT,false,64);
    }
    static const char *b[]={"MORE CREDITS","BACK"}; bottom_header("CREDITS", "Art, audio and names are retained from the supplied source."); ui_grid(b,2,selected,2);
}

static void page_folder(void) {
    ui_common_top("GAME DATA FOLDER", "This is the SD-card equivalent of Open Game Folder", 0);
    c_rect_alpha(&top_canvas,18,73,260,130,UI_DARK_PANEL,220);
    c_text(&top_canvas,28,84,"SD:/luma/3ds/",UI_CYAN,false,236);
    c_text(&top_canvas,28,108,"The Choicer Voicer/",UI_TEXT_LIGHT,true,236);
    c_text(&top_canvas,28,139,"packs_voice/  packs_player/",UI_TEXT_LIGHT,false,236);
    c_text(&top_canvas,28,158,"packs_host/  packs_judges/",UI_TEXT_LIGHT,false,236);
    c_text(&top_canvas,28,177,"saves/  recordings/  audio/",UI_TEXT_LIGHT,false,236);
    static const char *b[]={"BROWSE PACKS","VIEW RECORDINGS","SAVE STATE","BACK"};
    bottom_header("DATA FOLDER", "Select a section to open its native browser."); ui_grid(b,4,selected,2);
}

static void page_cinema(void) {
    ui_common_top("DUB CINEMA", "Original Dub Cinema preview screen", 3);
    c_sprite(&top_canvas, SPR_DUB_FREESTYLE, 15, 65, 270, 153);
    c_sprite(&top_canvas, SPR_HOST, 315, 66, 72, 146);
    static const char *b[]={"START DUB MODE","WATCH LAST DUB","SAVE LAST DUB","BACK"};
    bottom_header("DUB CINEMA", "Choose, record, review and save your dub."); ui_grid(b,4,selected,2);
}

static void page_empty(void) {
    ui_common_top("THE CHOICER VOICER", "This panel is not available in the native build", 0);
    bottom_header("UNAVAILABLE", "Use the PC build for unsupported desktop-only tools.");
    static const char *b[]={"BACK"}; ui_grid(b,1,selected,2);
}

static void render(void) {
    ui_reset_buttons();
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
        case PAGE_CUSTOMIZE: page_customize(); break;
        case PAGE_PACK_LIST: page_pack_list(); break;
        case PAGE_SETTING_DETAIL: page_setting_detail(); break;
        case PAGE_FOLDER: page_folder(); break;
        case PAGE_CINEMA: page_cinema(); break;
        default: page_empty(); break;
    }
    if (message_timer > 0) --message_timer;
    frames++;
}

static void canvas_flush(Canvas *c, gfxScreen_t screen, gfx3dSide_t side) {
    if (!c || !c->pixels) return;
    u16 fw=0, fh=0;
    u8 *fb = gfxGetFramebuffer(screen, side, &fw, &fh);
    if (!fb || fw != c->w || fh != c->h) return;
    for (int x=0; x<c->w; ++x) {
        for (int y=0; y<c->h; ++y) {
            uint32_t col = c->pixels[(size_t)y*(size_t)c->w+(size_t)x];
            size_t dst = ((size_t)x*(size_t)fh + (size_t)(fh-1-y))*3u;
            fb[dst+0]=color_b(col); fb[dst+1]=color_g(col); fb[dst+2]=color_r(col);
        }
    }
}

static void go_home(void) { page = PAGE_HOME; selected = 0; }

static int pack_count_for_type(int type) {
    ItemList items; list_pack_dir(type, &items); return items.count > 0 ? items.count : 1;
}

static void normalize_pack_indices(void) {
    game.voice = clamp_int(game.voice, 0, pack_count_for_type(0) - 1);
    game.player = clamp_int(game.player, 0, pack_count_for_type(1) - 1);
    game.host = clamp_int(game.host, 0, pack_count_for_type(2) - 1);
    game.judge = clamp_int(game.judge, 0, pack_count_for_type(3) - 1);
    game.studio = clamp_int(game.studio, 0, pack_count_for_type(4) - 1);
    game.menu = clamp_int(game.menu, 0, pack_count_for_type(5) - 1);
    game.twitch = clamp_int(game.twitch, 0, pack_count_for_type(6) - 1);
}

static void assign_selected_pack(void) {
    int count = pack_count_for_type(pack_type);
    pack_selected = clamp_int(pack_selected, 0, count - 1);
    int *target = NULL;
    switch (pack_type) {
        case 0: target = &game.voice; break;
        case 1: target = &game.player; break;
        case 2: target = &game.host; break;
        case 3: target = &game.judge; break;
        case 4: target = &game.studio; break;
        case 5: target = &game.menu; break;
        case 6: target = &game.twitch; break;
        default: target = NULL; break;
    }
    if (target) *target = pack_selected;
    save_state();
    page = pack_return_page;
    selected = 0;
    set_message("Pack selection saved");
}

static bool get_pack_dir(int type, int index, char *out, size_t out_size) {
    ItemList items;
    if (!out || out_size == 0) return false;
    list_pack_dir(type, &items);
    if (index < 0 || index >= items.count) return false;
    int n = snprintf(out, out_size, "%s/%s/%s", ROOT, pack_folders[clamp_int(type, 0, 6)], items.items[index].name);
    return n > 0 && (size_t)n < out_size;
}

static char *trim_inplace(char *s) {
    if (!s) return s;
    while (*s && (unsigned char)*s <= 32) ++s;
    size_t n = strlen(s);
    while (n && (unsigned char)s[n - 1] <= 32) s[--n] = '\0';
    return s;
}

static bool parse_timestamp_value(const char *raw, float *seconds) {
    if (!raw || !seconds) return false;
    char value[128]; snprintf(value, sizeof(value), "%s", raw);
    char *s = trim_inplace(value);
    if (*s == '[') ++s;
    while (*s && (*s == '\'' || *s == '"' || (unsigned char)*s <= 32)) ++s;
    char *end = s + strlen(s);
    while (end > s && (end[-1] == ']' || end[-1] == ')' || end[-1] == ',' || end[-1] == '\'' || end[-1] == '"' || (unsigned char)end[-1] <= 32)) *--end = '\0';
    char *comma = strchr(s, ','); if (comma) *comma = '\0';
    char *colon = strchr(s, ':');
    if (colon) {
        *colon++ = '\0';
        char *colon2 = strchr(colon, ':');
        char *ep = NULL; double v = 0.0;
        if (colon2) {
            *colon2++ = '\0';
            double hh = strtod(s, &ep); if (ep == s || *ep) return false;
            double mm = strtod(colon, &ep); if (ep == colon || *ep) return false;
            double ss = strtod(colon2, &ep); if (ep == colon2 || *ep) return false;
            v = hh * 3600.0 + mm * 60.0 + ss;
        } else {
            double mm = strtod(s, &ep); if (ep == s || *ep) return false;
            double ss = strtod(colon, &ep); if (ep == colon || *ep) return false;
            v = mm * 60.0 + ss;
        }
        if (v < 0.0 || v > 86400.0) return false;
        *seconds = (float)v; return true;
    }
    char *ep = NULL; double n = strtod(s, &ep);
    if (ep == s || n < 0.0 || n > 86400.0) return false;
    *seconds = (float)n; return true;
}

static void parse_timestamp_from_filename(NativeVoiceClip *clip) {
    if (!clip || clip->has_timestamp) return;
    char tmp[192]; snprintf(tmp, sizeof(tmp), "%s", clip->stem);
    char *leaf = strrchr(tmp, '/'); if (leaf) leaf++; else leaf = tmp;
    char *last = strrchr(leaf, '_');
    if (!last || !strchr(last + 1, '-')) return;
    char stamp[64]; snprintf(stamp, sizeof(stamp), "%s", last + 1);
    for (size_t i = 0; stamp[i]; ++i) if (stamp[i] == '-') stamp[i] = '.';
    if (parse_timestamp_value(stamp, &clip->timestamp)) clip->has_timestamp = true;
}

static void parse_clip_metadata(const char *stem_path, NativeVoiceClip *clip) {
    if (!stem_path || !clip) return;
    char meta_path[512];
    const char *exts[] = {".ini", ".cfg", ".txt"};
    char contents[8192]; bool read_any = false;
    for (int ei = 0; ei < 3 && !read_any; ++ei) {
        int n = snprintf(meta_path, sizeof(meta_path), "%s%s", stem_path, exts[ei]);
        if (n <= 0 || (size_t)n >= sizeof(meta_path)) continue;
        FILE *f = fopen(meta_path, "rb"); if (!f) continue;
        size_t got = fread(contents, 1, sizeof(contents) - 1, f); fclose(f);
        contents[got] = '\0'; read_any = true;
        bool saw_config = strchr(contents, '=') != NULL;
        if (!saw_config && exts[ei][1] == 't') {
            char *line = contents;
            while (*line && (unsigned char)*line <= 32) ++line;
            char *eol = strpbrk(line, "\r\n"); if (eol) *eol = '\0';
            if (*line) snprintf(clip->caption, sizeof(clip->caption), "%.159s", line);
        }
        char *save = NULL;
        for (char *line = strtok_r(contents, "\r\n", &save); line; line = strtok_r(NULL, "\r\n", &save)) {
            char *s = trim_inplace(line);
            if (!*s || *s == ';' || *s == '#' || *s == '[') continue;
            char *eq = strchr(s, '='); if (!eq) eq = strchr(s, ':'); if (!eq) continue;
            *eq++ = '\0'; char *key = trim_inplace(s); char *value = trim_inplace(eq);
            if (!strcasecmp(key, "caption") || !strcasecmp(key, "subtitle")) {
                if (*value == '"' || *value == '\'') ++value;
                size_t vl = strlen(value);
                while (vl && (value[vl-1] == '"' || value[vl-1] == '\'')) value[--vl] = '\0';
                size_t w = 0;
                for (size_t i = 0; value[i] && w + 1 < sizeof(clip->caption); ++i) {
                    if (value[i] == '\\' && (value[i+1] == '"' || value[i+1] == '\\')) ++i;
                    char ch = value[i]; if ((unsigned char)ch < 32) ch = ' ';
                    clip->caption[w++] = ch;
                }
                clip->caption[w] = '\0';
            } else if (!strcasecmp(key, "dub_timestamps") || !strcasecmp(key, "dub_timestamp")) {
                if (!clip->has_timestamp && parse_timestamp_value(value, &clip->timestamp)) clip->has_timestamp = true;
            } else if (!strcasecmp(key, "dub_characters") || !strcasecmp(key, "dub_character")) {
                char *v = value;
                while (*v && (*v == '[' || *v == ']' || *v == '"' || *v == '\'' || (unsigned char)*v <= 32)) ++v;
                size_t n = strcspn(v, "\",]'\r\n"); if (n >= sizeof(clip->characters)) n = sizeof(clip->characters)-1;
                memcpy(clip->characters, v, n); clip->characters[n] = '\0';
            } else if (!strcasecmp(key, "image")) {
                char *v = value;
                while (*v && (*v == '"' || *v == '\'' || (unsigned char)*v <= 32)) ++v;
                size_t n = strcspn(v, "\"'\r\n"); if (n >= sizeof(clip->image_name)) n = sizeof(clip->image_name)-1;
                memcpy(clip->image_name, v, n); clip->image_name[n] = '\0';
            } else if (!strcasecmp(key, "dub_only")) {
                while (*value == '\"' || *value == '\'' || (unsigned char)*value <= 32) ++value;
                clip->dub_only = (!strncasecmp(value, "true", 4) || *value == '1');
            }
        }
    }
    parse_timestamp_from_filename(clip);
}

static int compare_voice_clips(const void *a, const void *b) {
    const NativeVoiceClip *ca = (const NativeVoiceClip *)a;
    const NativeVoiceClip *cb = (const NativeVoiceClip *)b;
    if (sort_voice_by_timestamp && ca->timestamp != cb->timestamp)
        return ca->timestamp < cb->timestamp ? -1 : 1;
    return strcasecmp(ca->relative, cb->relative);
}

static void scan_voice_dir(const char *pack_root, const char *dir, const char *relative, int depth, bool require_timestamp) {
    if (depth > 5 || voice_clip_count >= MAX_VOICE_CLIPS) return;
    DIR *d = opendir(dir); if (!d) return;
    struct dirent *entry;
    while ((entry = readdir(d)) && voice_clip_count < MAX_VOICE_CLIPS) {
        if (entry->d_name[0] == '.' || entry->d_name[0] == '_') continue;
        char path[512], rel[192];
        int pn = snprintf(path, sizeof(path), "%s/%s", dir, entry->d_name);
        int rn = relative && *relative ? snprintf(rel, sizeof(rel), "%s/%s", relative, entry->d_name) : snprintf(rel, sizeof(rel), "%s", entry->d_name);
        if (pn <= 0 || (size_t)pn >= sizeof(path) || rn <= 0 || (size_t)rn >= sizeof(rel)) continue;
        struct stat st; if (stat(path, &st) != 0) continue;
        if (S_ISDIR(st.st_mode)) { scan_voice_dir(pack_root, path, rel, depth + 1, require_timestamp); continue; }
        if (!S_ISREG(st.st_mode) || !has_ext(entry->d_name, ".wav")) continue;
        bool native_companion = has_ext(entry->d_name, ".3ds.wav");
        char canonical_leaf[256];
        if (native_companion) {
            size_t leaf_len = strlen(entry->d_name) - strlen(".3ds.wav");
            if (leaf_len + 5 >= sizeof(canonical_leaf)) continue;
            memcpy(canonical_leaf, entry->d_name, leaf_len);
            memcpy(canonical_leaf + leaf_len, ".wav", 5);
        } else {
            /* Prefer the normalized companion, avoiding duplicates and RAM spikes. */
            char companion[512];
            int cn = snprintf(companion, sizeof(companion), "%.*s.3ds.wav",
                              (int)(strlen(path) - strlen(".wav")), path);
            if (cn > 0 && (size_t)cn < sizeof(companion)) {
                FILE *cf = fopen(companion, "rb");
                if (cf) { fclose(cf); continue; }
            }
            snprintf(canonical_leaf, sizeof(canonical_leaf), "%.251s", entry->d_name);
        }
        char canonical_rel[192];
        int cr = relative && *relative ? snprintf(canonical_rel, sizeof(canonical_rel), "%s/%s", relative, canonical_leaf)
                                       : snprintf(canonical_rel, sizeof(canonical_rel), "%s", canonical_leaf);
        if (cr <= 0 || (size_t)cr >= sizeof(canonical_rel)) continue;
        NativeVoiceClip clip; memset(&clip, 0, sizeof(clip));
        snprintf(clip.path, sizeof(clip.path), "%s", path);
        snprintf(clip.relative, sizeof(clip.relative), "%s", canonical_rel);
        snprintf(clip.stem, sizeof(clip.stem), "%s", canonical_rel);
        char *dot = strrchr(clip.stem, '.'); if (dot) *dot = '\0';
        char stem_path[512]; int sn = snprintf(stem_path, sizeof(stem_path), "%s/%s", pack_root, clip.stem);
        if (sn <= 0 || (size_t)sn >= sizeof(stem_path)) continue;
        parse_clip_metadata(stem_path, &clip);
        if (require_timestamp && !clip.has_timestamp) continue;
        if (!require_timestamp && clip.dub_only) continue;
        if (!clip.caption[0]) {
            const char *leaf = strrchr(clip.relative, '/'); leaf = leaf ? leaf + 1 : clip.relative;
            snprintf(clip.caption, sizeof(clip.caption), "%.159s", leaf);
        }
        voice_clips[voice_clip_count++] = clip;
    }
    closedir(d);
}

static int load_voice_clips(const char *pack_dir, bool require_timestamps) {
    voice_clip_count = 0; sort_voice_by_timestamp = require_timestamps;
    if (!pack_dir || !*pack_dir) return 0;
    scan_voice_dir(pack_dir, pack_dir, "", 0, require_timestamps);
    qsort(voice_clips, (size_t)voice_clip_count, sizeof(voice_clips[0]), compare_voice_clips);
    return voice_clip_count;
}

static bool ensure_dub_record_directories(void) {
    char path[512];
    if (mk_dir(REC_DIR) != 0) return false;
    snprintf(path, sizeof(path), "%s/dub_recordings", REC_DIR); if (mk_dir(path) != 0) return false;
    char safe_pack[80]; snprintf(safe_pack, sizeof(safe_pack), "%s", active_pack_name[0] ? active_pack_name : "Dub Pack");
    for (size_t i = 0; safe_pack[i]; ++i) if (safe_pack[i] == '/' || safe_pack[i] == '\\' || safe_pack[i] == ':') safe_pack[i] = '_';
    int n = snprintf(path, sizeof(path), "%s/dub_recordings/%s", REC_DIR, safe_pack);
    if (n <= 0 || (size_t)n >= sizeof(path) || mk_dir(path) != 0) return false;
    n = snprintf(path, sizeof(path), "%s/dub_recordings/%s/3DS Session", REC_DIR, safe_pack);
    if (n <= 0 || (size_t)n >= sizeof(path) || mk_dir(path) != 0) return false;
    return true;
}

static bool make_active_dub_record_path(int clip_index, char *out, size_t out_size, bool create_dirs) {
    if (!out || out_size == 0 || !active_dub_pack || clip_index < 0 || clip_index >= voice_clip_count) return false;
    char safe_pack[80]; snprintf(safe_pack, sizeof(safe_pack), "%s", active_pack_name[0] ? active_pack_name : "Dub Pack");
    for (size_t i = 0; safe_pack[i]; ++i) if (safe_pack[i] == '/' || safe_pack[i] == '\\' || safe_pack[i] == ':') safe_pack[i] = '_';
    char safe_stem[72];
    const char *leaf = strrchr(voice_clips[clip_index].stem, '/'); leaf = leaf ? leaf + 1 : voice_clips[clip_index].stem;
    snprintf(safe_stem, sizeof(safe_stem), "%.68s", leaf);
    for (size_t i = 0; safe_stem[i]; ++i) if (safe_stem[i] == '/' || safe_stem[i] == '\\' || safe_stem[i] == ':') safe_stem[i] = '_';
    if (create_dirs && !ensure_dub_record_directories()) return false;
    int n = snprintf(out, out_size, "%s/dub_recordings/%s/3DS Session/_dubrecord_%s.wav", REC_DIR, safe_pack, safe_stem);
    return n > 0 && (size_t)n < out_size;
}

static void load_current_pack_art(const NativeVoiceClip *clip) {
    free(active_clip_art.rgba);
    memset(&active_clip_art, 0, sizeof(active_clip_art));
    if (!clip || !active_pack_dir[0]) return;
    char relative[192] = "";
    if (clip->image_name[0]) {
        snprintf(relative, sizeof(relative), "%.191s", clip->image_name);
        if (relative[0] == '/' || strstr(relative, "..")) relative[0] = '\0';
        char *ext = strrchr(relative, '.');
        if (ext) snprintf(ext, sizeof(relative) - (size_t)(ext - relative), ".tcvr");
        else strncat(relative, ".tcvr", sizeof(relative) - strlen(relative) - 1);
    }
    char path[512];
    if (relative[0]) {
        snprintf(path, sizeof(path), "%s/%s", active_pack_dir, relative);
        if (load_pack_sprite_path(&active_clip_art, path)) return;
    }
    snprintf(relative, sizeof(relative), "%.187s", clip->stem);
    strncat(relative, ".tcvr", sizeof(relative) - strlen(relative) - 1);
    snprintf(path, sizeof(path), "%s/%s", active_pack_dir, relative);
    if (load_pack_sprite_path(&active_clip_art, path)) return;
    const char *fallbacks[] = {"_pack_filler_image.tcvr", "_icon.tcvr"};
    for (int i = 0; i < 2; ++i) {
        snprintf(path, sizeof(path), "%s/%s", active_pack_dir, fallbacks[i]);
        if (load_pack_sprite_path(&active_clip_art, path)) return;
    }
}

static bool tcv_frame_flags(TcvVideo *v, uint32_t index, uint8_t *flags) {
    if (!v || !v->opened || index >= v->frame_count || !flags) return false;
    if (v->offsets[index] > LONG_MAX || fseek(v->file, (long)v->offsets[index], SEEK_SET) != 0) return false;
    uint8_t hdr[8]; if (fread(hdr, 1, sizeof(hdr), v->file) != sizeof(hdr)) return false;
    *flags = hdr[0];
    uint32_t len = read_le32(hdr + 4);
    return len > 0 && len <= v->frame_bytes;
}

static bool tcv_decode_one(TcvVideo *v, uint32_t index) {
    if (!v || !v->opened || index >= v->frame_count || v->offsets[index] > LONG_MAX) return false;
    if (fseek(v->file, (long)v->offsets[index], SEEK_SET) != 0) return false;
    uint8_t hdr[8]; if (fread(hdr, 1, sizeof(hdr), v->file) != sizeof(hdr)) return false;
    uint8_t flags = hdr[0]; uint32_t payload_len = read_le32(hdr + 4);
    if (!payload_len || payload_len > v->frame_bytes || fread(v->payload, 1, payload_len, v->file) != payload_len) return false;
    if (flags & 2u) {
        if (payload_len != v->frame_bytes) return false;
        memcpy(v->decoded, v->payload, v->frame_bytes);
    } else {
        uLongf dest_len = (uLongf)v->frame_bytes;
        int zr = uncompress(v->decoded, &dest_len, v->payload, (uLong)payload_len);
        if (zr != Z_OK || dest_len != v->frame_bytes) return false;
    }
    if (flags & 1u) memcpy(v->pixels, v->decoded, v->frame_bytes);
    else {
        if (!v->has_frame || v->current_frame + 1 != index) return false;
        for (size_t i = 0; i < v->frame_bytes; ++i) v->pixels[i] ^= v->decoded[i];
    }
    v->current_frame = index; v->has_frame = true;
    return true;
}

static void tcv_close(TcvVideo *v) {
    if (!v) return;
    if (v->file) fclose(v->file);
    free(v->offsets); free(v->pixels); free(v->decoded); free(v->payload);
    memset(v, 0, sizeof(*v));
}

static bool tcv_open(TcvVideo *v, const char *path) {
    if (!v || !path) return false;
    tcv_close(v);
    FILE *f = fopen(path, "rb"); if (!f) return false;
    if (fseek(f, 0, SEEK_END) != 0) { fclose(f); return false; }
    long file_size = ftell(f); if (file_size < 20 || fseek(f, 0, SEEK_SET) != 0) { fclose(f); return false; }
    uint8_t h[20]; if (fread(h, 1, sizeof(h), f) != sizeof(h) || memcmp(h, "TCV1", 4)) { fclose(f); return false; }
    uint16_t width = read_le16(h + 4), height = read_le16(h + 6), fps = read_le16(h + 8), key = read_le16(h + 10);
    uint32_t frames_n = read_le32(h + 12), index_offset = read_le32(h + 16);
    if (width != 160 || height != 90 || fps == 0 || fps > 10 || key == 0 || key > 60 ||
        frames_n == 0 || frames_n > TCV_MAX_FRAMES || index_offset != 20u ||
        (uint64_t)index_offset + (uint64_t)frames_n * 4u > (uint64_t)file_size) { fclose(f); return false; }
    uint32_t *offsets = (uint32_t *)malloc((size_t)frames_n * sizeof(uint32_t));
    uint8_t *pixels = (uint8_t *)calloc(1, TCV_FRAME_BYTES);
    uint8_t *decoded = (uint8_t *)malloc(TCV_FRAME_BYTES);
    uint8_t *payload = (uint8_t *)malloc(TCV_FRAME_BYTES);
    if (!offsets || !pixels || !decoded || !payload) { free(offsets); free(pixels); free(decoded); free(payload); fclose(f); return false; }
    if (fseek(f, (long)index_offset, SEEK_SET) != 0) { free(offsets); free(pixels); free(decoded); free(payload); fclose(f); return false; }
    for (uint32_t i = 0; i < frames_n; ++i) {
        uint8_t b[4]; if (fread(b, 1, 4, f) != 4) { free(offsets); free(pixels); free(decoded); free(payload); fclose(f); return false; }
        offsets[i] = read_le32(b);
        if (offsets[i] < index_offset + frames_n * 4u || offsets[i] > (uint32_t)(file_size - 8)) {
            free(offsets); free(pixels); free(decoded); free(payload); fclose(f); return false;
        }
    }
    v->file = f; v->width = width; v->height = height; v->fps = fps; v->key_interval = key;
    v->frame_count = frames_n; v->index_offset = index_offset; v->offsets = offsets;
    v->pixels = pixels; v->decoded = decoded; v->payload = payload; v->frame_bytes = TCV_FRAME_BYTES;
    v->opened = true; v->has_frame = false; v->playing = false;
    if (!tcv_decode_one(v, 0)) { tcv_close(v); return false; }
    return true;
}

static bool tcv_seek(TcvVideo *v, float seconds) {
    if (!v || !v->opened || !v->frame_count) return false;
    if (seconds < 0) seconds = 0;
    uint32_t target = (uint32_t)(seconds * (float)v->fps);
    if (target >= v->frame_count) target = v->frame_count - 1;
    uint32_t key = target; uint8_t flags = 0;
    while (key > 0) { if (!tcv_frame_flags(v, key, &flags)) return false; if (flags & 1u) break; --key; }
    v->has_frame = false;
    for (uint32_t i = key; i <= target; ++i) if (!tcv_decode_one(v, i)) { v->playing = false; return false; }
    v->playing = false;
    return true;
}

static void tcv_pump(void) {
    TcvVideo *v = &dub_video;
    if (!v->opened || !v->playing || !v->fps) return;
    uint64_t now = osGetTime();
    uint64_t elapsed_ms = now >= v->start_time_ms ? now - v->start_time_ms : 0;
    uint64_t target64 = (elapsed_ms * v->fps) / 1000u;
    if (target64 >= v->frame_count) { (void)tcv_seek(v, (float)(v->frame_count - 1) / (float)v->fps); v->playing = false; return; }
    uint32_t target = (uint32_t)target64;
    while (v->current_frame < target) {
        if (!tcv_decode_one(v, v->current_frame + 1)) { v->playing = false; set_message("Dub video decode failed; rebuild this pack on PC"); return; }
    }
}

static void draw_tcv_video(Canvas *c, int x, int y, int w, int h) {
    TcvVideo *v = &dub_video;
    if (!c || !v->opened || !v->has_frame || !v->pixels || w <= 0 || h <= 0) return;
    int x0 = x < 0 ? 0 : x, y0 = y < 0 ? 0 : y;
    int x1 = x + w > c->w ? c->w : x + w;
    int y1 = y + h > c->h ? c->h : y + h;
    for (int py = y0; py < y1; ++py) {
        int dy = py - y;
        int sy = (dy * (int)v->height) / h;
        uint32_t *row = c->pixels + (size_t)py * (size_t)c->w;
        for (int px = x0; px < x1; ++px) {
            int sx = ((px - x) * (int)v->width) / w;
            size_t pos = ((size_t)sy * v->width + (size_t)sx) * 2u;
            uint16_t rgb565 = (uint16_t)v->pixels[pos] | ((uint16_t)v->pixels[pos + 1] << 8);
            unsigned rr = ((rgb565 >> 11) & 31u) * 255u / 31u;
            unsigned gg = ((rgb565 >> 5) & 63u) * 255u / 63u;
            unsigned bb = (rgb565 & 31u) * 255u / 31u;
            row[px] = 0xFF000000u | (rr << 16) | (gg << 8) | bb;
        }
    }
}

static void dub_replay_pump(void) {
    if (!dub_replay_active || !active_dub_pack || !dub_video.opened) return;
    pump_dub_overlay_audio();
    uint64_t now = osGetTime();
    float elapsed = (float)(now >= dub_replay_start_ms ? now - dub_replay_start_ms : 0) / 1000.0f;
    /* Do not wait for the previous line: timestamps are absolute on the video
       timeline and the independent channels permit natural overlaps. */
    while (dub_replay_next_clip < voice_clip_count &&
           voice_clips[dub_replay_next_clip].timestamp <= elapsed + 0.015f) {
        char path[512]; int idx = dub_replay_next_clip++;
        bool played = false;
        if (make_active_dub_record_path(idx, path, sizeof(path), false)) {
            FILE *check = fopen(path, "rb");
            if (check) { fclose(check); played = play_dub_overlay_wav(path); }
        }
        if (!played) (void)play_dub_overlay_wav(voice_clips[idx].path);
    }
    if (!dub_video.playing && dub_replay_next_clip >= voice_clip_count && !dub_overlay_audio_active()) {
        dub_replay_active = false; music_stream_stop(); start_selected_music(); set_message("Dub playback finished");
    }
}

static void start_dub_replay(void) {
    if (!active_dub_pack || !dub_video.opened || voice_clip_count <= 0) { set_message("Load a converted dub pack first"); return; }
    if (recording) finish_recording();
    stop_playback();
    stop_dub_overlay_audio();
    if (!tcv_seek(&dub_video, 0.0f)) { set_message("Could not seek dub video to start"); return; }
    char backing[512]; snprintf(backing, sizeof(backing), "%s/_backing_track.3ds.wav", active_pack_dir);
    dub_replay_next_clip = 0; dub_replay_start_ms = osGetTime(); dub_replay_active = true;
    dub_video.playing = true; dub_video.start_time_ms = dub_replay_start_ms;
    if (!music_stream_start_path(backing)) {
        snprintf(backing, sizeof(backing), "%s/_backing_track.wav", active_pack_dir);
        if (!music_stream_start_path(backing)) music_stream_stop();
    }
    set_message("Playing full dub pack with recorded line timings");
}

static void play_current_clip(void) {
    if (voice_clip_count <= 0) { set_message("This voice pack has no compatible WAV clips"); return; }
    int index = game.clip_index;
    if (index < 0 || index >= voice_clip_count) index = game.clip_index = 0;
    NativeVoiceClip *clip = &voice_clips[index];
    load_current_pack_art(clip);
    game_subtitle[0] = '\0';
    if (show_subtitles && clip->caption[0]) {
        if (clip->characters[0]) snprintf(game_subtitle, sizeof(game_subtitle), "%.35s: %.118s", clip->characters, clip->caption);
        else snprintf(game_subtitle, sizeof(game_subtitle), "%.159s", clip->caption);
    }
    stop_playback();
    if (active_dub_pack) {
        if (!tcv_seek(&dub_video, clip->timestamp)) {
            set_message("This line could not seek the compressed dub video"); return;
        }
        dub_video.playing = false;
        (void)play_wav_file(clip->path);
        char status[96]; snprintf(status, sizeof(status), "Dub line %d/%d at %.2fs", index + 1, voice_clip_count, clip->timestamp);
        set_message(status);
        return;
    }
    if (!play_wav_file(clip->path)) set_message("Could not play this pack's WAV prompt");
}

static void play_judge_score_sfx(void) {
    char dir[384], path[512];
    if (!ndsp_ready || !get_pack_dir(3, game.judge, dir, sizeof(dir))) return;
    snprintf(path, sizeof(path), "%s/scoreblip%d.wav", dir, (game.round % 5) + 1);
    (void)play_wav_file(path);
}

static void begin_match(void) {
    char dir[384], video_path[512];
    if (recording) finish_recording();
    dub_replay_active = false;
    stop_dub_overlay_audio();
    tcv_close(&dub_video);
    active_dub_pack = false;
    active_pack_dir[0] = active_pack_name[0] = '\0';
    if (!get_pack_dir(0, game.voice, dir, sizeof(dir))) {
        set_message("Selected voice pack folder is missing"); return;
    }
    snprintf(active_pack_dir, sizeof(active_pack_dir), "%s", dir);
    ItemList packs; list_pack_dir(0, &packs);
    if (game.voice >= 0 && game.voice < packs.count)
        snprintf(active_pack_name, sizeof(active_pack_name), "%.95s", packs.items[game.voice].name);
    else snprintf(active_pack_name, sizeof(active_pack_name), "Voice Pack");

    if (game.mode == 1) {
        int n = snprintf(video_path, sizeof(video_path), "%s/dub_video.tcv", dir);
        if (n <= 0 || (size_t)n >= sizeof(video_path) || !tcv_open(&dub_video, video_path)) {
            char ogv[512]; snprintf(ogv, sizeof(ogv), "%s/dub_video.ogv", dir);
            FILE *original = fopen(ogv, "rb");
            if (original) { fclose(original); set_message("Dub video needs PC conversion: run prepare_3ds_dub_packs.py"); }
            else set_message("Dub mode needs a pack containing dub_video.ogv and timestamped clips");
            page = PAGE_SETUP; selected = 0; return;
        }
        voice_clip_count = load_voice_clips(dir, true);
        if (voice_clip_count <= 0) {
            tcv_close(&dub_video); set_message("Dub pack has no timestamped WAV clips; check each clip .ini/.txt");
            page = PAGE_SETUP; selected = 0; return;
        }
        active_dub_pack = true;
        if (!ensure_dub_record_directories()) {
            active_dub_pack = false; tcv_close(&dub_video);
            set_message("Cannot create this dub pack's recording session on SD");
            page = PAGE_SETUP; selected = 0; return;
        }
    } else {
        voice_clip_count = load_voice_clips(dir, false);
        if (voice_clip_count <= 0) {
            set_message("Selected voice pack has no compatible audio; prepare MP3/OGG packs on PC first");
            page = PAGE_SETUP; selected = 0; return;
        }
    }
    game.round = 0;
    game.clip_index = 0;
    game.selected_member = 0;
    memset(game.score, 0, sizeof(game.score));
    save_state();
    page = PAGE_GAME;
    selected = 0;
    play_current_clip();
}

static void next_round(void) {
    if (recording) finish_recording();
    stop_playback();
    if (active_dub_pack) {
        dub_replay_active = false;
        dub_video.playing = false;
        music_stream_stop();
        game.clip_index++;
        if (game.clip_index >= voice_clip_count) {
            game.clip_index = voice_clip_count - 1;
            page = PAGE_RESULTS;
            set_message("All dub lines recorded; choose WATCH DUB to replay the scene");
            selected = 0;
            save_state();
            return;
        }
        page = PAGE_GAME;
        selected = 0;
        play_current_clip();
        return;
    }
    if (auto_save_dub && game.last_recording[0]) {
        /* finish_recording already wrote the latest take to recordings/dub_latest.wav. */
    }
    if (game.member_count > 0) {
        int base = ((game.clip_index + game.voice + game.judge + game.round) % 6);
        for (int i = 0; i < game.member_count; ++i) game.score[i] += base;
    }
    game.round++;
    game.clip_index = voice_clip_count > 0 ? (game.clip_index + 1) % voice_clip_count : 0;
    if (game.round >= game.total_rounds) {
        game.round = game.total_rounds - 1;
        save_state(); page = PAGE_RESULTS;
        play_judge_score_sfx();
    } else {
        save_state(); page = PAGE_GAME;
        play_current_clip();
    }
    selected = 0;
}

static bool copy_file_limited(const char *src, const char *dst) {
    if (!src || !dst) return false;
    FILE *in=fopen(src,"rb"); if(!in) return false;
    FILE *out=fopen(dst,"wb"); if(!out){ fclose(in); return false; }
    uint8_t buf[4096]; bool ok=true; size_t n;
    while ((n=fread(buf,1,sizeof(buf),in))>0) if (fwrite(buf,1,n,out)!=n) { ok=false; break; }
    if (ferror(in)) ok=false;
    if (fflush(out)!=0) ok=false;
    if (fclose(out)!=0) ok=false;
    fclose(in);
    if(!ok) remove(dst);
    return ok;
}

static void save_latest_dub(void) {
    if (recording) finish_recording();
    if (active_dub_pack) {
        char path[512];
        if (make_active_dub_record_path(game.clip_index, path, sizeof(path), true)) {
            FILE *f = fopen(path, "rb");
            if (f) { fclose(f); snprintf(game.last_recording, sizeof(game.last_recording), "%.255s", path); set_message("Current line is saved in this dub pack session"); return; }
        }
        set_message("Record the current line first; each line saves into the pack session");
        return;
    }
    char latest[320]; snprintf(latest,sizeof(latest),"%s/dub_latest.wav",REC_DIR);
    if (game.last_recording[0]) {
        FILE *f=fopen(game.last_recording,"rb");
        if (f) {
            fclose(f);
            if (strcmp(game.last_recording,latest)!=0 && !copy_file_limited(game.last_recording,latest)) {
                set_message("Failed copying dub into latest recording"); return;
            }
            snprintf(game.last_recording,sizeof(game.last_recording),"%s",latest);
            set_message("Dub saved to recordings/dub_latest.wav"); return;
        }
    }
    FILE *fallback=fopen(latest,"rb");
    if (fallback) { fclose(fallback); snprintf(game.last_recording,sizeof(game.last_recording),"%s",latest); set_message("Dub is saved in recordings/"); return; }
    set_message("Record a dub before saving");
}

static void watch_latest_dub(void) {
    if (recording) finish_recording();
    if (active_dub_pack) { start_dub_replay(); return; }
    if (game.last_recording[0] && play_wav_file(game.last_recording)) {
        set_message("Playing latest dub"); return;
    }
    char latest[320]; snprintf(latest, sizeof(latest), "%s/dub_latest.wav", REC_DIR);
    if (play_wav_file(latest)) {
        snprintf(game.last_recording, sizeof(game.last_recording), "%s", latest);
        set_message("Playing saved dub"); return;
    }
    ItemList l; list_dir(REC_DIR, &l);
    for (int i=l.count-1; i>=0; --i) {
        if (has_ext(l.items[i].name, ".wav")) {
            char path[384]; snprintf(path, sizeof(path), "%s/%s", REC_DIR, l.items[i].name);
            if (play_wav_file(path)) { snprintf(game.last_recording, sizeof(game.last_recording), "%s", path); set_message("Playing saved dub"); return; }
        }
    }
    set_message("No saved WAV dub found");
}

static void open_pack_browser(int type, Page return_page) {
    pack_type = clamp_int(type, 0, 6);
    pack_return_page = return_page;
    pack_selected = 0;
    if (pack_type == 0) pack_selected = game.voice;
    else if (pack_type == 1) pack_selected = game.player;
    else if (pack_type == 2) pack_selected = game.host;
    else if (pack_type == 3) pack_selected = game.judge;
    else if (pack_type == 4) pack_selected = game.studio;
    else if (pack_type == 5) pack_selected = game.menu;
    else if (pack_type == 6) pack_selected = game.twitch;
    pack_selected = clamp_int(pack_selected, 0, pack_count_for_type(pack_type)-1);
    pack_scroll_offset = pack_selected > 3 ? pack_selected - 3 : 0;
    page = PAGE_PACK_LIST; selected = 4;
}

static void activate_menu(int id) {
    if (id < 0) return;
    play_menu_sfx("select");
    if (page == PAGE_PACK_LIST && id >= 10) {
        pack_selected = clamp_int(id - 10, 0, pack_count_for_type(pack_type)-1);
        assign_selected_pack();
        return;
    }
    if (page == PAGE_PACK_LIST && id >= 4) {
        pack_selected = clamp_int(pack_scroll_offset + id - 4, 0, pack_count_for_type(pack_type)-1);
        assign_selected_pack(); return;
    }
    switch (page) {
        case PAGE_HOME:
            switch (id) {
                case 0: page = PAGE_PLAY; break;
                case 1: page = PAGE_CUSTOMIZE; break;
                case 2: page = PAGE_FOLDER; break;
                case 3: page = PAGE_SETTINGS; break;
                case 4: page = PAGE_DATA; break;
                case 5: page = PAGE_EXTRAS; break;
                case 6: page = PAGE_GUIDE; break;
                case 7: page = PAGE_CREDITS; break;
            } break;
        case PAGE_PLAY:
            if (id == 0) { game.mode = 0; page = PAGE_MODE; }
            else if (id == 1) { game.mode = 1; page = PAGE_MODE; }
            else if (id == 2) page = PAGE_CINEMA;
            else if (id == 3) go_home();
            break;
        case PAGE_MODE:
            if (id == 0) game.mode = 0;
            else if (id == 1) game.mode = 1;
            else if (id == 2) game.total_rounds = clamp_int(game.total_rounds-1,1,9);
            else if (id == 3) game.total_rounds = clamp_int(game.total_rounds+1,1,9);
            else if (id == 4) page = PAGE_MEMBERS;
            else if (id == 5) page = PAGE_PLAY;
            save_state(); break;
        case PAGE_MEMBERS:
            if (id >= 0 && id < 4) { game.member_count = id+1; save_state(); }
            else if (id == 4) page = PAGE_SETUP;
            else if (id == 5) page = PAGE_MODE;
            break;
        case PAGE_SETUP:
            if (id >= 0 && id <= 9) {
                int type = id/2;
                int *target = setup_value_ptr(type);
                int count = pack_count_for_type(type);
                if (target) *target = clamp_int(*target + ((id & 1) ? 1 : -1), 0, count-1);
                save_state(); play_menu_sfx("decrease");
            } else if (id == 10) begin_match();
            else if (id == 11) page = PAGE_MEMBERS;
            break;
        case PAGE_GAME:
        case PAGE_DUB:
            if (id == 0) { if (!recording) start_recording(); else { finish_recording(); if (auto_next_round) next_round(); } }
            else if (id == 1) next_round();
            else if (id == 2) watch_latest_dub();
            else if (id == 3) save_latest_dub();
            break;
        case PAGE_RESULTS:
            if (id == 0) {
                if (active_dub_pack) { game.clip_index = 0; page = PAGE_GAME; play_current_clip(); }
                else if (game.round + 1 < game.total_rounds) { game.round++; game.clip_index=voice_clip_count > 0 ? (game.clip_index+1)%voice_clip_count : 0; page=PAGE_GAME; play_current_clip(); }
                else begin_match();
                selected=0; save_state();
            } else if (id == 1) watch_latest_dub();
            else if (id == 2) save_latest_dub();
            else if (id == 3) page=PAGE_SETUP;
            else if (id == 4) go_home();
            else if (id == 5) begin_match();
            break;
        case PAGE_PACK_LIST:
            if (id==0) pack_selected=(pack_selected+pack_count_for_type(pack_type)-1)%pack_count_for_type(pack_type);
            else if (id==1) pack_selected=(pack_selected+1)%pack_count_for_type(pack_type);
            else if (id==2) assign_selected_pack();
            else if (id==3) { page=pack_return_page; selected=0; }
            break;
        case PAGE_PACKS:
            if (id >= 0 && id < 7) open_pack_browser(id, PAGE_PACKS);
            else if (id == 7) go_home();
            break;
        case PAGE_CUSTOMIZE:
            if (id >= 0 && id < 6) open_pack_browser(id, PAGE_CUSTOMIZE);
            else if (id == 6) { page=PAGE_PACKS; selected=0; }
            else if (id == 7) go_home();
            break;
        case PAGE_SETTINGS:
            if (id >= 0 && id <= 5) { settings_group=id; page=PAGE_SETTING_DETAIL; selected=0; }
            else if (id == 6) { save_state(); set_message("Settings saved"); }
            else if (id == 7) go_home();
            break;
        case PAGE_SETTING_DETAIL:
            if (settings_group == 0) {
                if (id==0) music_volume=clamp_int(music_volume-1,0,10);
                else if (id==1) music_volume=clamp_int(music_volume+1,0,10);
                else if (id==2) sfx_volume=clamp_int(sfx_volume-1,0,10);
                else if (id==3) sfx_volume=clamp_int(sfx_volume+1,0,10);
                else if (id==4) { music_track=(music_track+1)%5; start_selected_music(); }
                else if (id==5) play_menu_sfx("select");
                else if (id==6) { save_state(); set_message("Audio settings saved"); }
                else if (id==7) { save_state(); page=PAGE_SETTINGS; selected=0; }
                set_music_volume();
            } else if (settings_group == 1) {
                if (id==0) (void)init_mic();
                else if (id==1) mic_gain=clamp_int(mic_gain-8,0,127);
                else if (id==2) mic_gain=clamp_int(mic_gain+8,0,127);
                else if (id==3) configured_record_seconds=clamp_int(configured_record_seconds-1,2,MAX_RECORD_SECONDS);
                else if (id==4) configured_record_seconds=clamp_int(configured_record_seconds+1,2,MAX_RECORD_SECONDS);
                else if (id==5) { if (recording) finish_recording(); else start_recording(); }
                else if (id==6) { save_state(); set_message("Microphone settings saved"); }
                else if (id==7) { save_state(); page=PAGE_SETTINGS; selected=0; }
                if (mic_ready) (void)MICU_SetGain((u8)mic_gain);
            } else if (settings_group == 2) {
                if (id==0) waveform_mode=(waveform_mode+2)%3;
                else if (id==1) waveform_mode=(waveform_mode+1)%3;
                else if (id==2) show_help_overlays=!show_help_overlays;
                else if (id==3) set_message("Waukegan LDO raster font enabled");
                else if (id==4) { selected=0; set_message("UI selection reset"); }
                else if (id==5) { save_state(); set_message("Display settings saved"); }
                else if (id==6) { save_state(); page=PAGE_SETTINGS; selected=0; }
                else if (id==7) go_home();
            } else if (settings_group == 3) {
                if (id==0) auto_save_dub=!auto_save_dub;
                else if (id==1) auto_next_round=!auto_next_round;
                else if (id==2) show_subtitles=!show_subtitles;
                else if (id==3) show_help_overlays=!show_help_overlays;
                else if (id==4) { save_state(); set_message("Dub settings saved"); }
                else if (id==5) { save_state(); page=PAGE_SETTINGS; selected=0; }
            } else if (settings_group == 4) {
                if (id==0) game.total_rounds=clamp_int(game.total_rounds-1,1,9);
                else if (id==1) game.total_rounds=clamp_int(game.total_rounds+1,1,9);
                else if (id==2) game.member_count=clamp_int(game.member_count-1,1,4);
                else if (id==3) game.member_count=clamp_int(game.member_count+1,1,4);
                else if (id==4) game_speedups=!game_speedups;
                else if (id==5) { save_state(); set_message("Gameshow options saved"); }
                else if (id==6) { save_state(); page=PAGE_SETTINGS; selected=0; }
            } else {
                if (id==0) set_message("Twitch login and the desktop relay are not supported by this native offline build");
                else if (id==1) page=PAGE_SETTINGS;
            }
            normalize_state(); if (id<6) save_state();
            break;
        case PAGE_DATA:
            if (id==0) { save_state(); set_message("Save written"); }
            else if (id==1) {
                remove(SAVE_FILE); load_state();
                if (setup_storage()) set_message("Native settings reset"); else set_message("Could not reset settings");
            }
            else if (id==2) { ItemList l; list_dir(REC_DIR,&l); set_message(l.count?"Recordings are in recordings/":"No recordings yet"); }
            else if (id==3) { page=PAGE_PACKS; selected=0; }
            else if (id==4) go_home();
            break;
        case PAGE_EXTRAS:
            if (id==0) { page=PAGE_GUIDE; selected=0; }
            else if (id==1) open_pack_browser(0,PAGE_EXTRAS);
            else if (id==2) page=PAGE_CINEMA;
            else if (id==3) { page=PAGE_CREDITS; credits_page=0; }
            else if (id==4) go_home();
            break;
        case PAGE_GUIDE:
            if (id==0) guide_page=(guide_page+3)%4;
            else if (id==1) guide_page=(guide_page+1)%4;
            else if (id==2) page=PAGE_FOLDER;
            else if (id==3) page=PAGE_EXTRAS;
            break;
        case PAGE_CREDITS:
            if (id==0) credits_page=(credits_page+1)%2;
            else if (id==1) go_home();
            break;
        case PAGE_FOLDER:
            if (id==0) { page=PAGE_PACKS; selected=0; }
            else if (id==1) { page=PAGE_DATA; selected=2; }
            else if (id==2) { save_state(); set_message("State saved"); }
            else if (id==3) go_home();
            break;
        case PAGE_CINEMA:
            if (id==0) { game.mode=1; begin_match(); }
            else if (id==1) watch_latest_dub();
            else if (id==2) save_latest_dub();
            else if (id==3) page=PAGE_PLAY;
            break;
        default: go_home(); break;
    }
    if (page != PAGE_PACK_LIST && page != PAGE_SETTING_DETAIL && page != PAGE_SETUP) selected = 0;
}

static void back_page(void) {
    play_menu_sfx("back");
    switch (page) {
        case PAGE_HOME: break;
        case PAGE_PLAY: go_home(); break;
        case PAGE_MODE: page=PAGE_PLAY; break;
        case PAGE_MEMBERS: page=PAGE_MODE; break;
        case PAGE_SETUP: page=PAGE_MEMBERS; break;
        case PAGE_GAME: stop_playback(); if (recording) finish_recording(); dub_replay_active=false; dub_video.playing=false; page=PAGE_SETUP; break;
        case PAGE_RESULTS: page=PAGE_GAME; break;
        case PAGE_DUB: case PAGE_CINEMA: page=PAGE_PLAY; break;
        case PAGE_PACKS: case PAGE_SETTINGS: case PAGE_DATA: case PAGE_EXTRAS: case PAGE_GUIDE: case PAGE_CREDITS: case PAGE_FOLDER: go_home(); break;
        case PAGE_CUSTOMIZE: go_home(); break;
        case PAGE_PACK_LIST: page=pack_return_page; break;
        case PAGE_SETTING_DETAIL: page=PAGE_SETTINGS; break;
        default: go_home(); break;
    }
    selected=0;
}

static int keyboard_activate(void) {
    int count=1;
    switch (page) {
        case PAGE_HOME: count=8; break;
        case PAGE_PLAY: count=4; break;
        case PAGE_MODE: count=6; break;
        case PAGE_MEMBERS: count=6; break;
        case PAGE_SETUP: count=12; break;
        case PAGE_GAME: case PAGE_DUB: count=4; break;
        case PAGE_RESULTS: count=6; break;
        case PAGE_PACKS: count=8; break;
        case PAGE_CUSTOMIZE: count=8; break;
        case PAGE_PACK_LIST: count=4+(last_packs.count<4?last_packs.count:4); break;
        case PAGE_SETTINGS: count=8; break;
        case PAGE_SETTING_DETAIL: count=settings_group==3?6:settings_group==5?2:settings_group==4?7:8; break;
        case PAGE_DATA: count=5; break;
        case PAGE_EXTRAS: count=5; break;
        case PAGE_GUIDE: count=4; break;
        case PAGE_CREDITS: count=2; break;
        case PAGE_FOLDER: count=4; break;
        case PAGE_CINEMA: count=4; break;
        default: count=1; break;
    }
    if (count < 1) count=1;
    if (selected < 0 || selected >= count) selected=0;
    return count;
}

static int touch_hit(int x, int y) {
    for (int i=touch_button_count-1; i>=0; --i) {
        TouchButton *b=&touch_buttons[i];
        if (x>=b->x && y>=b->y && x<b->x+b->w && y<b->y+b->h) return b->id;
    }
    return -1;
}

static void handle_touch(void) {
    if (!(hidKeysDown() & KEY_TOUCH)) return;
    touchPosition pos; hidTouchRead(&pos);
    int id=touch_hit((int)pos.px,(int)pos.py);
    if (id>=0) {
        if (page==PAGE_PACK_LIST && id>=10) {
            pack_selected=clamp_int(id-10,0,pack_count_for_type(pack_type)-1);
            assign_selected_pack();
        } else activate_menu(id);
    }
}

int main(int argc, char **argv) {
    (void)argc; (void)argv;
    gfxInitDefault();
    if (R_SUCCEEDED(ndspInit())) {
        ndsp_ready=true; ndspSetMasterVol(1.0f);
        ndspChnSetFormat(0, NDSP_FORMAT_STEREO_PCM16);
        ndspChnSetRate(0, 22050.0f);
        float initial_mix[12]={1,1,0,0,0,0,0,0,0,0,0,0};
        ndspChnSetMix(0,initial_mix);
    } else set_message("Audio output unavailable; menus still work");

    top_canvas.pixels=(uint32_t *)calloc((size_t)top_canvas.w*(size_t)top_canvas.h,sizeof(uint32_t));
    bottom_canvas.pixels=(uint32_t *)calloc((size_t)bottom_canvas.w*(size_t)bottom_canvas.h,sizeof(uint32_t));
    if (!top_canvas.pixels || !bottom_canvas.pixels) {
        free(top_canvas.pixels); free(bottom_canvas.pixels);
        if (ndsp_ready) ndspExit();
        gfxExit();
        return 1;
    }
    if (!setup_storage()) set_message("SD storage unavailable or read-only");
    load_state();
    load_ui_assets();
    game.last_recording[0]='\0';
    char latest[320]; snprintf(latest,sizeof(latest),"%s/dub_latest.wav",REC_DIR);
    FILE *latest_file=fopen(latest,"rb");
    if (latest_file) { fclose(latest_file); snprintf(game.last_recording,sizeof(game.last_recording),"%s",latest); }
    if (ndsp_ready) start_selected_music();
    if (!sprites[SPR_FONT_SMALL].rgba || !sprites[SPR_FONT_LARGE].rgba)
        set_message("Install the SD assets bundle for the full UI");

    while (aptMainLoop()) {
        hidScanInput();
        u32 k=hidKeysDown();
        if (k & KEY_START) break;
        if (k & KEY_B) back_page();
        int count=keyboard_activate();
        if ((k & KEY_UP) && count>0) { selected=(selected+count-1)%count; play_menu_sfx("hover"); }
        if ((k & KEY_DOWN) && count>0) { selected=(selected+1)%count; play_menu_sfx("hover"); }
        if ((k & KEY_LEFT) && page==PAGE_SETUP) {
            int *v=setup_value_ptr(selected/2);
            if(v) *v=clamp_int(*v-1,0,pack_count_for_type(selected/2)-1);
            save_state(); play_menu_sfx("decrease");
        } else if ((k & KEY_RIGHT) && page==PAGE_SETUP) {
            int *v=setup_value_ptr(selected/2);
            if(v) *v=clamp_int(*v+1,0,pack_count_for_type(selected/2)-1);
            save_state(); play_menu_sfx("select");
        }
        if (k & KEY_A) {
            if (page==PAGE_PACK_LIST && selected>=4) {
                pack_selected=clamp_int(pack_scroll_offset+selected-4,0,pack_count_for_type(pack_type)-1);
                assign_selected_pack();
            } else activate_menu(selected);
        }
        handle_touch();
        if (recording) {
            bool sampling=false;
            if (R_SUCCEEDED(MICU_IsSampling(&sampling)) && !sampling) finish_recording();
            else if ((frames-recording_started_frame) > (uint64_t)configured_record_seconds*60u) finish_recording();
        }
        if (playback_active && playback_wave.status==NDSP_WBUF_DONE) stop_playback();
        tcv_pump();
        music_stream_pump();
        dub_replay_pump();
        render();
        canvas_flush(&top_canvas,GFX_TOP,GFX_LEFT);
        canvas_flush(&bottom_canvas,GFX_BOTTOM,GFX_LEFT);
        gfxFlushBuffers();
        gfxSwapBuffers();
        gspWaitForVBlank();
    }

    if (recording) finish_recording();
    stop_playback();
    stop_dub_overlay_audio();
    music_stream_stop();
    tcv_close(&dub_video);
    save_state();
    if (mic_ready) { micExit(); mic_ready=false; }
    if (mic_buffer) { linearFree(mic_buffer); mic_buffer=NULL; }
    free_ui_assets();
    free(active_clip_art.rgba); active_clip_art.rgba = NULL;
    free(top_canvas.pixels); top_canvas.pixels=NULL;
    free(bottom_canvas.pixels); bottom_canvas.pixels=NULL;
    if (ndsp_ready) { ndspExit(); ndsp_ready=false; }
    gfxExit();
    return 0;
}
