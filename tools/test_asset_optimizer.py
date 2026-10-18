#!/usr/bin/env python3
"""Regression test for compact mono WAVs embedded in Old 3DS RomFS."""
from __future__ import annotations
import tempfile
import wave
from pathlib import Path
from prepare_3ds_assets import optimize_large_wavs, prune_runtime_files


def main() -> None:
    with tempfile.TemporaryDirectory(prefix="tcv-wav-opt-") as temp:
        root = Path(temp)
        path = root / "long_stereo_music.wav"
        frames = 300_000  # ~13.6 seconds; >1 MiB stereo PCM16 input
        with wave.open(str(path), "wb") as wav:
            wav.setnchannels(2)
            wav.setsampwidth(2)
            wav.setframerate(22050)
            # Quiet deterministic sample data; size/rate/channel count are the target.
            wav.writeframes((b"\x00\x00\x10\x00") * frames)
        original_size = path.stat().st_size
        converted, saved = optimize_large_wavs(root)
        assert converted == 1, f"expected one converted large WAV, got {converted}"
        with wave.open(str(path), "rb") as wav:
            assert wav.getnchannels() == 1
            assert wav.getframerate() == 16000
            assert wav.getsampwidth() == 2
            assert wav.getcomptype() == "NONE"
        assert path.stat().st_size < original_size
        assert saved == original_size - path.stat().st_size

        # Regression for compact asset staging: a WAV must not match itself as
        # its own converted companion and be deleted by the pruning pass.
        music_dir = root / "audio" / "music"
        music_dir.mkdir(parents=True)
        music = music_dir / "maintheme.wav"
        with wave.open(str(music), "wb") as wav:
            wav.setnchannels(1)
            wav.setsampwidth(2)
            wav.setframerate(16000)
            wav.writeframes(b"\x00\x00" * 160)
        compressed = music_dir / "converted.mp3"
        compressed.write_bytes(b"fake-mp3-for-pruning-test")
        companion = music_dir / "converted.wav"
        with wave.open(str(companion), "wb") as wav:
            wav.setnchannels(1)
            wav.setsampwidth(2)
            wav.setframerate(22050)
            wav.writeframes(b"\x00\x00" * 160)

        prune_runtime_files(root)
        assert music.is_file(), "default WAV without a native companion must survive runtime pruning"
        assert not compressed.exists(), "compressed source should be pruned when a separate WAV companion exists"
        assert companion.is_file(), "normalized WAV companion must remain available to runtime"
        print(f"PASS: large WAV optimization saved {saved:,} bytes; pruning preserves standalone default music and removes only verified duplicate audio sources.")


if __name__ == "__main__":
    main()
