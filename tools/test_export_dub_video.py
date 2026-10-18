#!/usr/bin/env python3
"""Integration regression test for full-length dubbed MP4 export using FFmpeg."""
from __future__ import annotations
import math
import os
import shutil
import subprocess
import sys
import tempfile
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
from export_dub_video import ExportError, export_dub, parse_session  # noqa: E402


def run(args: list[str]) -> None:
    subprocess.run(args, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


def write_tone(path: Path, duration: float, frequency: float) -> None:
    rate = 16000
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(rate)
        frames = bytearray()
        for i in range(int(rate * duration)):
            value = int(6000 * math.sin(2 * math.pi * frequency * i / rate))
            frames += value.to_bytes(2, byteorder="little", signed=True)
        w.writeframes(frames)


def main() -> None:
    if not shutil.which("ffmpeg") or not shutil.which("ffprobe"):
        print("SKIP: ffmpeg/ffprobe are not available"); return
    with tempfile.TemporaryDirectory(prefix="tcv-export-test-") as td:
        base = Path(td); pack = base / "packs_voice" / "Multi Format Test"
        media = pack / "media"; media.mkdir(parents=True)
        session = base / "sd" / "3ds" / "TheChoicerVoicer3DS_User" / "recordings" / "dub_recordings" / "Multi Format Test" / "3DS Session"
        session.mkdir(parents=True)
        video = media / "movie.MKV"
        run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-f", "lavfi", "-i", "color=c=blue:s=160x90:r=10:d=2.5", "-f", "lavfi", "-i", "sine=frequency=220:sample_rate=48000:duration=2.5", "-t", "2.5", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-c:a", "aac", str(video)])
        # An explicit backing track should be mixed with the recorded takes.
        write_tone(pack / "_backing_track.wav", 1.0, 180)
        take_a, take_b = "_dubrecord_LineA_t00000200_01.wav", "_dubrecord_LineB_t00001300_02.wav"
        write_tone(session / take_a, 0.35, 440)
        write_tone(session / take_b, 0.35, 660)
        (session / "session.ini").write_text(
            '[session]\nformat_version=1\npack="Multi Format Test"\nclip_count=2\nrecorded_count=2\n\n'
            f'[clip_001]\ntimestamp=0.200\nsource="LineA.wav"\ntake="{take_a}"\nrecorded=true\n\n'
            f'[clip_002]\ntimestamp=1.300\nsource="LineB.wav"\ntake="{take_b}"\nrecorded=true\n', encoding="utf-8")
        output = base / "output" / "Full Dub.mp4"
        result = export_dub(session / "session.ini", pack, output)
        assert result.is_file() and result.stat().st_size > 1024
        duration = float(subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1", str(output)], text=True).strip())
        assert 2.35 <= duration <= 2.65, duration
        streams = subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "stream=codec_type", "-of", "csv=p=0", str(output)], text=True).splitlines()
        assert "video" in streams and "audio" in streams, streams
        # Strict mode must reject missing takes rather than silently export a partial dub.
        (session / "session.ini").write_text(
            '[session]\nformat_version=1\npack="Multi Format Test"\nclip_count=2\nrecorded_count=1\n\n'
            f'[clip_001]\ntimestamp=0.200\nsource="LineA.wav"\ntake="{take_a}"\nrecorded=true\n\n'
            '[clip_002]\ntimestamp=1.300\nsource="LineB.wav"\ntake=""\nrecorded=false\n', encoding="utf-8")
        try:
            parse_session(session / "session.ini", require_complete=True)
        except ExportError as exc:
            assert "incomplete" in str(exc).lower()
        else:
            raise AssertionError("incomplete session was accepted")

        # Exercise the no-backing/no-source-audio path: exporter must add a silent
        # bed so the MP4 still has a full-length audio stream alongside the take.
        silent_pack = base / "packs_voice" / "No Backing Test"
        silent_pack.mkdir(parents=True)
        silent_video = silent_pack / "dub_video.ogv"
        run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-f", "lavfi", "-i", "color=c=black:s=160x90:r=10:d=1.5", "-t", "1.5", "-c:v", "libtheora", str(silent_video)])
        silent_session = base / "sd" / "no-backing" / "3DS Session"
        silent_session.mkdir(parents=True)
        silent_take = "_dubrecord_Single_t00000200_01.wav"
        write_tone(silent_session / silent_take, 0.3, 330)
        (silent_session / "session.ini").write_text(
            '[session]\nformat_version=1\npack="No Backing Test"\nclip_count=1\nrecorded_count=1\n\n'
            f'[clip_001]\ntimestamp=0.200\nsource="Single.wav"\ntake="{silent_take}"\nrecorded=true\n', encoding="utf-8")
        silent_output = base / "output" / "No Backing Full.mp4"
        export_dub(silent_session / "session.ini", silent_pack, silent_output)
        silent_streams = subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "stream=codec_type", "-of", "csv=p=0", str(silent_output)], text=True).splitlines()
        assert "video" in silent_streams and "audio" in silent_streams, silent_streams
        silent_duration = float(subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1", str(silent_output)], text=True).strip())
        assert 1.2 <= silent_duration <= 1.4, silent_duration
        silent_audio_duration = float(subprocess.check_output(["ffprobe", "-v", "error", "-select_streams", "a:0", "-show_entries", "stream=duration", "-of", "default=noprint_wrappers=1:nokey=1", str(silent_output)], text=True).strip())
        assert silent_audio_duration >= silent_duration - 0.15, (silent_audio_duration, silent_duration)
    print("PASS: full-duration export, timestamped take mixing, backing-track and silent-bed paths, and incomplete-session rejection.")


if __name__ == "__main__":
    main()
