# v25 — Fix compact asset staging failure

Fixed the build failure after “Prepared compact embedded runtime tree”. The runtime pruning function previously checked WAVs in the generic `AUDIO_EXTENSIONS` branch first; `source.with_suffix('.wav')` then pointed back to the same WAV and caused standalone default music/SFX WAVs to be removed.

The pruning order now preserves `.3ds.wav` native companions and default `.wav` files without a distinct companion. An original WAV is removed only when a separate `.3ds.wav` companion exists. Compressed sources are removed only when a distinct normalized WAV companion exists. The asset-preparation workflow now prints the failed command/line if a validation step fails.
