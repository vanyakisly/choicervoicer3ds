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
    prepare_voice_pack_audio, convert_pack_images, prepare_tree, normalize_pack_metadata,
)
from prepare_3ds_assets import prune_runtime_files
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
        assert fmt(backing) == (1, 22050, 16)
        tcvr = (pack / '01_TestLine.tcvr').read_bytes()
        im_magic, im_w, im_h = struct.unpack_from('<4sHH', tcvr)
        assert im_magic == b'TCVR' and im_w == 256 and im_h <= 256
        assert len(tcvr) == 8 + im_w * im_h * 4

        # Exercise the generalized pack pipeline with a case-variant MKV file
        # (not named dub_video.ogv), FLAC dialogue, JSON alias metadata, and TIFF art.
        alt_pack = root / 'packs_voice' / 'Nested Collection' / 'Alternate Format Pack'
        alt_pack.mkdir(parents=True)
        movie = alt_pack / 'movie.MKV'
        subprocess.run([
            ffmpeg, '-hide_banner', '-loglevel', 'error', '-y',
            '-f', 'lavfi', '-i', 'testsrc2=size=320x180:rate=12', '-t', '1.2',
            '-an', '-c:v', 'mpeg4', '-pix_fmt', 'yuv420p', '-f', 'matroska', str(movie),
        ], check=True)
        flac = alt_pack / '01_Line.FLAC'
        subprocess.run([
            ffmpeg, '-hide_banner', '-loglevel', 'error', '-y',
            '-f', 'lavfi', '-i', 'sine=frequency=550:duration=0.3', '-c:a', 'flac', str(flac),
        ], check=True)
        Image.new('RGB', (80, 60), (20, 150, 80)).save(alt_pack / '01_Line.TIFF')
        (alt_pack / '01_Line.JSON').write_text(
            '{"text":"Alternate-format line","timestamp":"00:00:00.500",'
            '"speaker":"Test Speaker","thumbnail":"01_Line.TIFF"}', encoding='utf-8')

        # A pack can keep the source video in a media subfolder and use simple YAML metadata.
        nested_pack = root / 'packs_voice' / 'Nested Video Pack'
        nested_pack.mkdir(parents=True)
        video_dir = nested_pack / 'media'
        video_dir.mkdir()
        nested_movie = video_dir / 'scene.mkv'
        subprocess.run([
            ffmpeg, '-hide_banner', '-loglevel', 'error', '-y',
            '-f', 'lavfi', '-i', 'color=c=blue:size=320x180:rate=12', '-t', '1.0',
            '-an', '-c:v', 'mpeg4', '-pix_fmt', 'yuv420p', '-f', 'matroska', str(nested_movie),
        ], check=True)
        nested_audio = nested_pack / '01_Nested.wav'
        subprocess.run([
            ffmpeg, '-hide_banner', '-loglevel', 'error', '-y',
            '-f', 'lavfi', '-i', 'sine=frequency=410:duration=0.25', '-c:a', 'pcm_s16le', str(nested_audio),
        ], check=True)
        (nested_pack / '01_Nested.YML').write_text('caption: Nested line\nstart_time: 00:00:00.400\nspeaker: Nested Speaker\n', encoding='utf-8')
        videos, normalized_audio = prepare_tree(root / 'packs_voice')
        # Every unrelated pack gets its own converted artifact; no title is special-cased.
        expected_pack_dirs = (pack, alt_pack, nested_pack)
        for expected_pack in expected_pack_dirs:
            assert (expected_pack / 'dub_video.tcv').is_file(), f'pack was not prepared: {expected_pack.relative_to(root)}'
            assert check_video(expected_pack / 'dub_video.tcv') >= 1
        assert videos >= 2, 'expected the generalized pack pipeline to convert alternate and nested non-OGV videos'
        converted_movie = alt_pack / 'dub_video.tcv'
        assert converted_movie.is_file() and check_video(converted_movie) >= 10
        assert (alt_pack / '01_Line.3ds.wav').is_file()
        assert (alt_pack / '01_Line.tcvr').is_file()
        normalized_ini = (alt_pack / '01_Line.ini').read_text(encoding='utf-8')
        assert 'caption="Alternate-format line"' in normalized_ini
        assert 'dub_timestamps=["00:00:00.500"]' in normalized_ini
        assert (alt_pack / '.tcv-source-file').read_text().strip() == 'movie.MKV'
        assert (nested_pack / 'dub_video.tcv').is_file() and check_video(nested_pack / 'dub_video.tcv') >= 10
        assert 'dub_timestamps=[\"00:00:00.400\"]' in (nested_pack / '01_Nested.ini').read_text(encoding='utf-8')
        assert (nested_pack / '.tcv-source-file').read_text().strip() == 'media/scene.mkv'
        # The ROMFS pruning step removes transcoded originals, but keeps runtime files.
        removed, bytes_removed = prune_runtime_files(root / 'packs_voice')
        assert not movie.exists(), 'alternate source video should be pruned after conversion for embedding'
        assert not flac.exists(), 'source FLAC should be pruned once its PCM companion exists'
        assert converted_movie.is_file() and (alt_pack / '01_Line.3ds.wav').is_file()

        # A timed dub cannot be silently packaged without any video source.
        bad_root = root / 'missing-video-packs'
        bad_pack = bad_root / 'Broken Dub'
        bad_pack.mkdir(parents=True)
        shutil.copy2(pack / '02_ExistingLine.3ds.wav', bad_pack / 'Line.wav')
        (bad_pack / 'Line.ini').write_text('[data]\ndub_timestamps=[0.5]\ncaption=Broken pack\n', encoding='utf-8')
        try:
            prepare_tree(bad_root)
        except RuntimeError as exc:
            assert 'timestamped dialogue exists, but no video was found' in str(exc)
        else:
            raise AssertionError('timed dub without video must produce a clear build error')
        print(f'PASS: multiple independently named packs converted to TCV; FLAC/OGG/WAV normalized; JSON timestamp aliases and TIFF artwork work; staged source media pruned safely ({removed} files, {bytes_removed:,} bytes).')


if __name__ == '__main__':
    main()
