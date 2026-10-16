/* Host regression test: MIC shared memory must use memalign(0x1000), not
   linearAlloc(), and the caller must keep the detailed service error visible. */
#define main tcv_native_program_entry
#include "../3ds_port/source/main.c"
#undef main

static Result mock_mic_init_result = 0;
static Result mock_clamp_result = 0;
static Result mock_gain_result = 0;
static int mock_init_calls = 0;
static int mock_exit_calls = 0;
static int mock_pointer_aligned = 0;
static int mock_size_aligned = 0;

Result micInit(u8 *buffer, u32 size) {
    mock_init_calls++;
    mock_pointer_aligned = (((uintptr_t)buffer & 0xFFFu) == 0u);
    mock_size_aligned = ((size & 0xFFFu) == 0u);
    if (!mock_pointer_aligned || !mock_size_aligned) return -99;
    if (mock_mic_init_result < 0) mock_exit_calls++; /* libctru micInit failure cleanup */
    return mock_mic_init_result;
}
void micExit(void) { mock_exit_calls++; }
Result MICU_SetClamp(bool clamp) { (void)clamp; return mock_clamp_result; }
Result MICU_SetGain(u8 gain) { (void)gain; return mock_gain_result; }

int main(void) {
    /* The success path must give libctru aligned shared memory. */
    if (!init_mic()) return 1;
    if (!mic_ready || !mic_buffer || !mock_pointer_aligned || !mock_size_aligned) return 2;
    if (((uintptr_t)mic_buffer & 0xFFFu) != 0u) return 3;
    micExit();
    free(mic_buffer); mic_buffer = NULL; mic_ready = false;

    /* The service failure should preserve its result code in the on-screen message. */
    mock_mic_init_result = -0x1234;
    if (init_mic()) return 4;
    if (mic_buffer != NULL || mic_ready) return 5;
    if (strstr(message, "MIC init failed") == NULL || strstr(message, "FFFFEDCC") == NULL) return 6;

    mock_mic_init_result = 0;
    mock_gain_result = -7;
    if (init_mic()) return 7;
    if (mic_buffer != NULL || mic_ready) return 8;
    if (mock_init_calls != 3 || mock_exit_calls < 3) return 9;

    puts("PASS: MIC uses 0x1000-aligned shared memory, frees failed allocations, and preserves exact MIC errors.");
    return 0;
}
