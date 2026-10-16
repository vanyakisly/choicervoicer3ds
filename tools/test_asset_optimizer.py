#!/usr/bin/env python3
"""Regression test for compact mono WAVs embedded in Old 3DS RomFS."""
from __future__ import annotations
import tempfile
import wave
from pathlib import Path
from prepare_3ds_assets import optimize_large_wavs


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
        print(f"PASS: large stereo WAV converted to mono PCM16/16 kHz; saved {saved:,} bytes.")


if __name__ == "__main__":
    main()
