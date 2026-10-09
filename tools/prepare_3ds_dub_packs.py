#!/usr/bin/env python3
"""Prepare original The Choicer Voicer packs for the Old 3DS native runtime.

Dub-pack video is sampled to 160x90 RGB565 at 10 fps. Frames are keyframed
periodically and zlib-compressed as XOR deltas between keyframes. The original
OGV is kept in place; dub_video.tcv is the compact file consumed by the 3DS.
Audio clips/backing tracks are converted to PCM16 WAV companions because the
native runtime intentionally avoids software MP3/Vorbis decoding on hardware.
"""
from __future__ import annotations
import argparse
import shutil
import struct
import subprocess
import sys
import zlib
from pathlib import Path
from PIL import Image

WIDTH, HEIGHT, FPS, KEY_INTERVAL = 160, 90, 10, 10
MAX_FRAMES = 5400  # 9 min at 10 fps; protects the Old 3DS from giant packs.
HEADER = struct.Struct('<4sHHHHII')  # 20 bytes
FRAME_HEADER = struct.Struct('<B3xI')  # key/raw flags + payload size
FLAG_KEY = 1
FLAG_RAW = 2
FRAME_BYTES = WIDTH * HEIGHT * 2


def ffmpeg_path() -> str:
    ffmpeg = shutil.which('ffmpeg')
    if not ffmpeg:
        raise RuntimeError('ffmpeg is required. Install it and retry.')
    return ffmpeg


def rgb24_to_rgb565(frame: bytes) -> bytes:
    if len(frame) != WIDTH * HEIGHT * 3:
        raise ValueError('unexpected raw video frame size')
    out = bytearray(FRAME_BYTES)
    dst = 0
    for src in range(0, len(frame), 3):
        r, g, b = frame[src], frame[src + 1], frame[src + 2]
        value = ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3)
        out[dst] = value & 0xFF
        out[dst + 1] = value >> 8
        dst += 2
    return bytes(out)


def convert_video(source: Path, destination: Path) -> dict[str, int | float]:
    source = source.resolve()
    destination = destination.resolve()
    if not source.is_file():
        raise FileNotFoundError(source)
    destination.parent.mkdir(parents=True, exist_ok=True)
    ffmpeg = ffmpeg_path()
    # Keep aspect ratio and letterbox instead of stretching faces. Limit to 9 min.
    vf = f'scale={WIDTH}:{HEIGHT}:force_original_aspect_ratio=decrease,pad={WIDTH}:{HEIGHT}:(ow-iw)/2:(oh-ih)/2,fps={FPS}'
    cmd = [ffmpeg, '-hide_banner', '-loglevel', 'error', '-threads', '1', '-i', str(source),
           '-frames:v', str(MAX_FRAMES), '-an', '-vf', vf, '-fps_mode', 'cfr',
           '-f', 'rawvideo', '-pix_fmt', 'rgb565le', 'pipe:1']
    # Reserve header/index, then write frames sequentially. No whole-video RAM buffer.
    tmp = destination.with_suffix(destination.suffix + '.tmp')
    offsets: list[int] = []
    prev = bytes(FRAME_BYTES)
    count = 0
    proc = None
    try:
        with tmp.open('w+b') as out:
            out.write(b'\0' * (HEADER.size + MAX_FRAMES * 4))
            proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            assert proc.stdout is not None
            while count < MAX_FRAMES:
                raw = proc.stdout.read(FRAME_BYTES)
                if not raw:
                    break
                while len(raw) < FRAME_BYTES:
                    chunk = proc.stdout.read(FRAME_BYTES - len(raw))
                    if not chunk:
                        raise RuntimeError(f'ffmpeg returned a truncated video frame ({len(raw)} bytes)')
                    raw += chunk
                current = raw
                key = (count % KEY_INTERVAL == 0)
                if key:
                    delta = current
                else:
                    delta = bytes(a ^ b for a, b in zip(current, prev))
                compressed = zlib.compress(delta, 6)
                flags = FLAG_KEY if key else 0
                if len(compressed) >= len(delta):
                    payload, flags = delta, flags | FLAG_RAW
                else:
                    payload = compressed
                offsets.append(out.tell())
                out.write(FRAME_HEADER.pack(flags, len(payload)))
                out.write(payload)
                prev = current
                count += 1
            proc.stdout.close()
            stderr = proc.stderr.read() if proc.stderr else b''
            rc = proc.wait()
            if rc != 0:
                raise RuntimeError('ffmpeg failed: ' + stderr.decode('utf-8', 'replace')[-1500:])
            if count == 0:
                raise RuntimeError('ffmpeg produced no decoded frames')
            index_offset = HEADER.size
            out.seek(index_offset)
            for off in offsets:
                out.write(struct.pack('<I', off))
            # unused reserved index slots are not included in index_offset; frames begin after full reservation
            frame_data_start = HEADER.size + MAX_FRAMES * 4
            # Offsets already point to actual output positions. Store real index immediately after header
            # by rewriting the file compactly only when finishing (temporary second pass).
            frame_area = tmp.with_suffix(tmp.suffix + '.frames')
            out.flush()
            with tmp.open('rb') as full, frame_area.open('wb') as compact:
                compact.write(HEADER.pack(b'TCV1', WIDTH, HEIGHT, FPS, KEY_INTERVAL, count, HEADER.size))
                for off in offsets:
                    compact.write(struct.pack('<I', off - frame_data_start + HEADER.size + count * 4))
                for off in offsets:
                    full.seek(off)
                    # record header then payload
                    hdr = full.read(FRAME_HEADER.size)
                    if len(hdr) != FRAME_HEADER.size:
                        raise RuntimeError('truncated frame while compacting')
                    payload_len = FRAME_HEADER.unpack(hdr)[1]
                    payload = full.read(payload_len)
                    if len(payload) != payload_len:
                        raise RuntimeError('truncated payload while compacting')
                    compact.write(hdr)
                    compact.write(payload)
            frame_area.replace(tmp)
        tmp.replace(destination)
    except Exception:
        if proc is not None and proc.poll() is None:
            proc.kill()
            try: proc.wait(timeout=5)
            except Exception: pass
        try: tmp.unlink()
        except OSError: pass
        try: tmp.with_suffix(tmp.suffix + '.frames').unlink()
        except OSError: pass
        raise
    return {'frames': count, 'duration': count / FPS, 'bytes': destination.stat().st_size}


def convert_audio_tree(root: Path) -> int:
    ffmpeg = ffmpeg_path()
    converted = 0
    sources = [p for p in root.rglob('*') if p.is_file() and p.suffix.lower() in ('.mp3', '.ogg')]
    for source in sources:
        dest = source.with_suffix('.wav')
        if dest.exists() and dest.stat().st_mtime >= source.stat().st_mtime:
            continue
        # Voice prompts are mono to keep even 60-second clips within the 3DS RAM cap.
        mono = source.name.lower().startswith('_backing_track') is False
        cmd = [ffmpeg, '-hide_banner', '-loglevel', 'error', '-y', '-i', str(source),
               '-ar', '22050', '-ac', '1' if mono else '2', '-c:a', 'pcm_s16le', str(dest)]
        subprocess.run(cmd, check=True)
        converted += 1
    return converted


def prepare_voice_pack_audio(root: Path) -> int:
    """Create bounded PCM16 22.05-kHz companions without changing source media.

    A clip named line.wav becomes line.3ds.wav; the runtime uses the normalized
    companion but keeps the original filename and metadata relationship.
    """
    ffmpeg = ffmpeg_path()
    converted = 0
    candidates = [p for p in root.rglob('*') if p.is_file()
                  and p.suffix.lower() in ('.wav', '.mp3', '.ogg')
                  and not p.name.lower().endswith('.3ds.wav')]
    # If a pack includes same-stem variants, prefer WAV, then MP3, then OGG;
    # otherwise two inputs could silently overwrite one normalized companion.
    priority = {'.wav': 0, '.mp3': 1, '.ogg': 2}
    selected: dict[str, Path] = {}
    for candidate in sorted(candidates, key=lambda p: priority[p.suffix.lower()]):
        key = str(candidate.relative_to(root).with_suffix('')).casefold()
        selected.setdefault(key, candidate)
    sources = sorted(selected.values())
    for source in sources:
        dest = source.with_name(source.stem + '.3ds.wav')
        if dest.exists() and dest.stat().st_mtime >= source.stat().st_mtime:
            continue
        stereo = source.name.lower().startswith('_backing_track')
        cmd = [ffmpeg, '-hide_banner', '-loglevel', 'error', '-y', '-threads', '1',
               '-i', str(source), '-vn', '-ar', '22050', '-ac', '2' if stereo else '1',
               '-c:a', 'pcm_s16le', str(dest)]
        subprocess.run(cmd, check=True)
        converted += 1
    return converted


def convert_pack_images(root: Path) -> int:
    """Write bounded RGBA companions so pack icons/line art can render natively."""
    converted = 0
    for source in (p for p in root.rglob('*') if p.is_file() and p.suffix.lower() in ('.png', '.jpg', '.jpeg', '.webp', '.bmp')):
        destination = source.with_suffix('.tcvr')
        if destination.exists() and destination.stat().st_mtime >= source.stat().st_mtime:
            continue
        try:
            with Image.open(source) as opened:
                image = opened.convert('RGBA')
                image.thumbnail((256, 256), Image.Resampling.LANCZOS)
                w, h = image.size
                raw = image.tobytes()
            with destination.open('wb') as f:
                f.write(struct.pack('<4sHH', b'TCVR', w, h))
                f.write(raw)
            converted += 1
        except Exception as exc:
            print(f'[warn] Could not convert pack image {source}: {exc}', file=sys.stderr)
    return converted


def prepare_tree(root: Path, transcode_audio: bool = True) -> tuple[int, int]:
    root = root.resolve()
    if not root.is_dir():
        raise NotADirectoryError(root)
    converted_videos = 0
    for ogv in root.rglob('dub_video.ogv'):
        tcv = ogv.with_name('dub_video.tcv')
        if tcv.exists() and tcv.stat().st_mtime >= ogv.stat().st_mtime:
            print(f'[skip] current TCV: {tcv.relative_to(root)}')
            continue
        meta = convert_video(ogv, tcv)
        converted_videos += 1
        print(f'[video] {ogv.relative_to(root)} -> {tcv.name}: {meta["frames"]} frames, {meta["duration"]:.1f}s, {meta["bytes"]:,} bytes')
    converted_audio = prepare_voice_pack_audio(root) if transcode_audio else 0
    converted_images = convert_pack_images(root)
    print(f'[done] {converted_videos} video(s), {converted_audio} audio companion(s), {converted_images} image companion(s) prepared under {root}')
    return converted_videos, converted_audio


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--tree', required=True, help='Root directory containing packs_voice/<pack>/...')
    parser.add_argument('--no-audio', action='store_true', help='Only convert dub_video.ogv to .tcv')
    args = parser.parse_args()
    try:
        prepare_tree(Path(args.tree), not args.no_audio)
    except (OSError, RuntimeError, ValueError, subprocess.CalledProcessError) as e:
        print(f'[error] {e}', file=sys.stderr)
        return 2
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
