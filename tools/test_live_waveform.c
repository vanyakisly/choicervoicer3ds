/* Host test of the live MIC sample snapshot used by the lower-screen waveform. */
#define main tcv_native_program_entry
#include "../3ds_port/source/main.c"
#undef main

static u32 mock_mic_offset;
static u32 mock_mic_size;
u32 micGetLastSampleOffset(void) { return mock_mic_offset; }
u32 micGetSampleDataSize(void) { return mock_mic_size; }

int main(void) {
    const size_t buffer_bytes = 12000u;
    mic_buffer = (u8 *)calloc(1, buffer_bytes);
    if (!mic_buffer) return 1;
    int16_t *pcm = (int16_t *)mic_buffer;
    for (size_t i = 0; i < buffer_bytes / 2u; ++i) pcm[i] = (int16_t)((int)i - 2900);

    mic_ready = true;
    recording = true;
    mock_mic_size = 10000u;
    mock_mic_offset = 10000u; /* 5000 complete PCM16 samples */
    update_live_waveform_snapshot();
    if (mic_wave_snapshot_count != MIC_WAVE_SNAPSHOT_SAMPLES) return 2;
    if (mic_wave_snapshot_offset != 10000u) return 3;
    if (mic_wave_snapshot[0] != pcm[5000u - MIC_WAVE_SNAPSHOT_SAMPLES]) return 4;
    if (mic_wave_snapshot[MIC_WAVE_SNAPSHOT_SAMPLES - 1u] != pcm[4999u]) return 5;

    /* If the MIC sample area reports an out-of-range offset, the snapshot is
       clamped to the service's real sample area and never reads beyond it. */
    mock_mic_offset = 50000u;
    update_live_waveform_snapshot();
    if (mic_wave_snapshot_offset != mock_mic_size) return 6;
    if (mic_wave_snapshot[MIC_WAVE_SNAPSHOT_SAMPLES - 1u] != pcm[4999u]) return 7;

    free(mic_buffer);
    mic_buffer = NULL;
    puts("PASS: live waveform snapshots recent completed PCM samples and clamps offsets.");
    return 0;
}
