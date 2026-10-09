#!/usr/bin/env python3
"""Offline regression test for the Old-3DS dub pack converter."""
from __future__ import annotations
import shutil
import struct
import subprocess
import tempfile
import zlib
from pathlib import Path
from prepare_3ds_dub_packs import (
    HEADER, FRAME_HEADER, FRAME_BYTES, FLAG_KEY, FLAG_RAW, convert_video,
    prepare_voice_pack_audio, convert_pack_images,
)
from PIL import Image


def check_video(path: Path) -> int:
    data = path.read_bytes()
    if len(data) < HEADER.size:
        raise AssertionError('TCV file shorter than header')
    magic, width, height, fps, key_interval, frame_count, index_offset = HEADER.unpack_from(data)
    assert magic == b'TCV1'
    assert (width, height, fps, key_interval) == (160, 90, 10, 10)
    assert 1 <= frame_count <= 5400
    assert index_offset == HEADER.size
    index_end = index_offset + frame_count * 4
    assert index_end <= len(data)
    offsets = list(struct.unpack_from(f'<{frame_count}I', data, index_offset))
    assert offsets == sorted(offsets) and len(set(offsets)) == len(offsets) and offsets[0] >= index_end
    pixels = bytearray(FRAME_BYTES)
    current = -1
    key_count = 0
    for i, offset in enumerate(offsets):
        assert offset + FRAME_HEADER.size <= len(data)
        flags, payload_len = FRAME_HEADER.unpack_from(data, offset)
        assert flags & ~(FLAG_KEY | FLAG_RAW) == 0
        assert 0 < payload_len <= FRAME_BYTES
        packet_end = offset + FRAME_HEADER.size + payload_len
        next_boundary = offsets[i + 1] if i + 1 < len(offsets) else len(data)
        assert packet_end <= next_boundary
        packet = data[offset + FRAME_HEADER.size:packet_end]
        assert len(packet) == payload_len
        if flags & FLAG_RAW:
            decoded = packet
            assert len(decoded) == FRAME_BYTES
        else:
            decoded = zlib.decompress(packet)
            assert len(decoded) == FRAME_BYTES
        if flags & FLAG_KEY:
            pixels[:] = decoded
            key_count += 1
        else:
            assert current == i - 1, 'delta frame does not follow previously decoded frame'
            for j, value in enumerate(decoded):
                pixels[j] ^= value
        current = i
    assert key_count >= 1
    assert all((flags & FLAG_KEY) for flags, _ in [FRAME_HEADER.unpack_from(data, offsets[k]) for k in range(0, frame_count, key_interval)])
    return frame_count


def main() -> None:
    ffmpeg = shutil.which('ffmpeg')
    if not ffmpeg:
        raise SystemExit('ffmpeg is required for this regression test')
    with tempfile.TemporaryDirectory(prefix='tcv-dub-test-') as temp:
        root = Path(temp)
        pack = root / 'packs_voice' / 'Sample Dub Pack'
        pack.mkdir(parents=True)
        source = pack / 'dub_video.ogv'
        # Generated frames avoid distributing any copyrighted sample pack.
        subprocess.run([
            ffmpeg, '-hide_banner', '-loglevel', 'error', '-y',
            '-f', 'lavfi', '-i', 'testsrc2=size=320x180:rate=15', '-t', '1.5',
            '-c:v', 'libtheora', '-pix_fmt', 'yuv420p', str(source),
        ], check=True)
        audio_ogg = pack / '01_TestLine.ogg'
        subprocess.run([
            ffmpeg, '-hide_banner', '-loglevel', 'error', '-y',
            '-f', 'lavfi', '-i', 'sine=frequency=440:duration=0.4',
            '-c:a', 'libvorbis', str(audio_ogg),
        ], check=True)
        wav_source = pack / '02_ExistingLine.wav'
        subprocess.run([
            ffmpeg, '-hide_banner', '-loglevel', 'error', '-y',
            '-f', 'lavfi', '-i', 'sine=frequency=660:duration=0.4',
            '-ar', '48000', '-ac', '2', '-c:a', 'pcm_s24le', str(wav_source),
        ], check=True)
        backing_source = pack / '_backing_track.ogg'
        subprocess.run([
            ffmpeg, '-hide_banner', '-loglevel', 'error', '-y',
            '-f', 'lavfi', '-i', 'sine=frequency=110:duration=0.4',
            '-ac', '2', '-c:a', 'libvorbis', str(backing_source),
        ], check=True)
        Image.new('RGB', (500, 300), (20, 90, 150)).save(pack / '01_TestLine.jpg')
        (pack / '01_TestLine.ini').write_text('[data]\ncaption="Test line"\ndub_timestamps=[0.5]\ndub_characters=["Narrator"]\nimage="01_TestLine.jpg"\n', encoding='utf-8')
        meta = convert_video(source, pack / 'dub_video.tcv')
        frames = check_video(pack / 'dub_video.tcv')
        assert frames == meta['frames'] and frames >= 10
        audio_count = prepare_voice_pack_audio(pack)
        image_count = convert_pack_images(pack)
        assert audio_count == 3, f'expected three normalized audio companions, got {audio_count}'
        assert image_count == 1, f'expected one image companion, got {image_count}'
        wav = pack / '01_TestLine.3ds.wav'
        backing = pack / '_backing_track.3ds.wav'
        existing = pack / '02_ExistingLine.3ds.wav'
        for path in (wav, backing, existing):
            assert path.is_file() and path.stat().st_size > 44
        def fmt(path: Path) -> tuple[int, int, int]:
            blob = path.read_bytes()[:44]
            assert blob[:4] == b'RIFF' and blob[8:12] == b'WAVE' and blob[12:16] == b'fmt '
            import struct as st
            _, channels, rate = st.unpack_from('<HHI', blob, 20)
            bits = st.unpack_from('<H', blob, 34)[0]
            return channels, rate, bits
        assert fmt(wav) == (1, 22050, 16)
        assert fmt(existing) == (1, 22050, 16)
        assert fmt(backing) == (2, 22050, 16)
        tcvr = (pack / '01_TestLine.tcvr').read_bytes()
        im_magic, im_w, im_h = struct.unpack_from('<4sHH', tcvr)
        assert im_magic == b'TCVR' and im_w == 256 and im_h <= 256
        assert len(tcvr) == 8 + im_w * im_h * 4
        print(f'PASS: {frames} indexed TCV frames decoded; WAV/OGG/backing-track audio normalized; JPG companion created.')


if __name__ == '__main__':
    main()
