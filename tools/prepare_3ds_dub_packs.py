#!/usr/bin/env python3
"""Prepare original The Choicer Voicer packs for the Old 3DS native runtime.

Dub-pack video is sampled to 160x90 RGB565 at 10 fps. Frames are keyframed
periodically and zlib-compressed as XOR deltas between keyframes. Conversion
happens only in the generated staging tree; a source marker lets staging remove
redundant original video from embedded RomFS once dub_video.tcv is verified.
Audio clips/backing tracks from common FFmpeg-readable formats are normalized
to PCM16 WAV companions because the native runtime does not decode compressed
media directly on the Old 3DS.
"""
from __future__ import annotations
import argparse
import json
import re
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

# FFmpeg can decode a much broader set of formats than the native runtime.
# All videos are transcoded to the compact TCV format and all line audio to PCM.
VIDEO_EXTENSIONS = {
    '.ogv', '.ogg', '.mp4', '.m4v', '.mov', '.mkv', '.webm', '.avi', '.wmv',
    '.flv', '.mpeg', '.mpg', '.m2v', '.3gp', '.3g2', '.ts', '.mts', '.m2ts',
    '.vob', '.asf', '.mxf', '.gif', '.apng', '.dv', '.y4m', '.nut',
}
VIDEO_STEMS = ('dub_video', 'dubvideo', 'source_video', 'sourcevideo', 'video', 'movie', 'clip')
VIDEO_AMBIGUOUS_AUDIO_EXTENSIONS = {'.ogg', '.oga', '.weba', '.mka'}
VIDEO_EXT_PRIORITY = ('.ogv', '.mp4', '.mkv', '.webm', '.mov', '.avi', '.m4v', '.mpeg', '.mpg', '.3gp', '.ogg', '.wmv', '.flv', '.ts', '.gif')
AUDIO_EXTENSIONS = {
    '.wav', '.mp3', '.ogg', '.flac', '.m4a', '.aac', '.opus', '.wma', '.aiff',
    '.aif', '.caf', '.ac3', '.amr', '.mp2', '.mka', '.weba', '.ape', '.tta',
    '.wv', '.oga', '.ra', '.voc', '.au', '.snd',
}
IMAGE_EXTENSIONS = {'.png', '.jpg', '.jpeg', '.webp', '.bmp', '.tif', '.tiff', '.gif'}
NATIVE_AUDIO_RATE = 22050


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


def _is_native_companion(path: Path) -> bool:
    return path.name.casefold().endswith('.3ds.wav')


def _audio_candidates(root: Path) -> list[Path]:
    candidates = []
    for path in root.rglob('*'):
        if not path.is_file() or path.suffix.casefold() not in AUDIO_EXTENSIONS:
            continue
        if _is_native_companion(path) or any(part.startswith('.') for part in path.relative_to(root).parts):
            continue
        # OGG/OGA/WEBA/MKA can be audio-only or contain video. Don't try to
        # treat a renamed movie as a line/backing audio file merely because its
        # extension is also accepted by an audio decoder.
        if path.suffix.casefold() in VIDEO_AMBIGUOUS_AUDIO_EXTENSIONS and probe_has_video(path):
            continue
        candidates.append(path)
    return sorted(candidates, key=lambda p: (str(p.parent).casefold(), p.stem.casefold(), p.suffix.casefold()))


def convert_audio_tree(root: Path) -> int:
    """Create ordinary mono PCM WAV files for non-voice pack audio.

    This deliberately accepts common audio formats through FFmpeg, rather than
    assuming all original assets are MP3/OGG. Sources are preserved in staging
    until the native runtime pruning step.
    """
    ffmpeg = ffmpeg_path()
    converted = 0
    for source in _audio_candidates(root):
        # Ordinary WAV is already a file the native runtime can read. Compressed
        # or unusual WAV containers are normalized; don't overwrite a source WAV.
        dest = source.with_suffix('.wav')
        if source.suffix.casefold() == '.wav':
            continue
        if dest.exists() and dest.stat().st_mtime >= source.stat().st_mtime:
            continue
        tmp = dest.with_name(dest.name + '.tmp.wav')
        try:
            subprocess.run([ffmpeg, '-hide_banner', '-loglevel', 'error', '-y', '-threads', '1',
                            '-i', str(source), '-map', '0:a:0', '-vn', '-sn', '-dn',
                            '-ar', str(NATIVE_AUDIO_RATE), '-ac', '1', '-c:a', 'pcm_s16le', str(tmp)], check=True)
            _validate_pcm_wav(tmp, rate=NATIVE_AUDIO_RATE, channels=1)
            tmp.replace(dest)
            converted += 1
        finally:
            try: tmp.unlink()
            except FileNotFoundError: pass
    return converted


def _validate_pcm_wav(path: Path, rate: int = NATIVE_AUDIO_RATE, channels: int = 1) -> None:
    import wave
    if not path.is_file() or path.stat().st_size <= 44:
        raise RuntimeError(f'Audio conversion produced an empty/invalid WAV: {path}')
    try:
        with wave.open(str(path), 'rb') as wav:
            if (wav.getframerate(), wav.getnchannels(), wav.getsampwidth(), wav.getcomptype()) != (rate, channels, 2, 'NONE'):
                raise RuntimeError(f'Audio conversion produced an unsupported PCM format: {path}')
            if wav.getnframes() <= 0:
                raise RuntimeError(f'Audio conversion produced no samples: {path}')
    except (wave.Error, EOFError) as exc:
        raise RuntimeError(f'Audio conversion produced a malformed WAV: {path}: {exc}') from exc


def prepare_voice_pack_audio(root: Path) -> int:
    """Make one PCM16 mono companion per line/backing track, from common formats.

    A source such as line.flac, line.m4a, line.opus, or line.wav gets a
    `line.3ds.wav` companion. Original assets are kept in the repository; only
    the staging tree is embedded in the 3DS app. Same-stem duplicates choose a
    deterministic source priority to prevent companion files being overwritten.
    """
    ffmpeg = ffmpeg_path()
    converted = 0
    candidates = _audio_candidates(root)
    priority = {
        '.wav': 0, '.flac': 1, '.aiff': 2, '.aif': 3, '.ape': 4, '.tta': 5,
        '.wv': 6, '.m4a': 7, '.aac': 8, '.mp3': 9, '.opus': 10, '.ogg': 11,
        '.oga': 12, '.wma': 13, '.ac3': 14, '.amr': 15, '.mp2': 16, '.mka': 17,
        '.weba': 18, '.caf': 19, '.ra': 20, '.voc': 21, '.au': 22, '.snd': 23,
    }
    selected: dict[str, Path] = {}
    for candidate in sorted(candidates, key=lambda p: priority.get(p.suffix.casefold(), 99)):
        key = str(candidate.relative_to(root).with_suffix('')).casefold()
        selected.setdefault(key, candidate)

    for source in sorted(selected.values(), key=lambda p: str(p).casefold()):
        dest = source.with_name(source.stem + '.3ds.wav')
        if dest.exists() and dest.stat().st_mtime >= source.stat().st_mtime:
            try:
                _validate_pcm_wav(dest)
                continue
            except RuntimeError:
                pass
        tmp = dest.with_name(dest.name + '.tmp.wav')
        try:
            subprocess.run([ffmpeg, '-hide_banner', '-loglevel', 'error', '-y', '-threads', '1',
                            '-i', str(source), '-map', '0:a:0', '-vn', '-sn', '-dn',
                            '-ar', str(NATIVE_AUDIO_RATE), '-ac', '1', '-c:a', 'pcm_s16le', str(tmp)], check=True)
            _validate_pcm_wav(tmp, rate=NATIVE_AUDIO_RATE, channels=1)
            tmp.replace(dest)
            converted += 1
        except subprocess.CalledProcessError as exc:
            raise RuntimeError(f'Could not convert audio clip `{source}`. Check that it contains a decodable audio stream.') from exc
        finally:
            try: tmp.unlink()
            except FileNotFoundError: pass
    return converted


def _parse_simple_metadata(text: str) -> dict[str, object]:
    values: dict[str, object] = {}
    list_key: str | None = None
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith(('[', ';', '#', '//')):
            continue
        if line.startswith('- ') and list_key:
            values.setdefault(list_key, [])
            current = values[list_key]
            if isinstance(current, list):
                current.append(line[2:].strip().strip('\"\''))
            continue
        sep = '=' if '=' in line else (':' if ':' in line else None)
        if not sep:
            list_key = None
            continue
        key, value = line.split(sep, 1)
        key = key.strip().casefold()
        value = value.strip().rstrip(',')
        if not key:
            list_key = None
            continue
        if not value:
            values[key] = []
            list_key = key
        else:
            values[key] = value
            list_key = None
    return values


def _metadata_scalar(value: object, key: str) -> str:
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return str(value)
    if isinstance(value, bool):
        return 'true' if value else 'false'
    if isinstance(value, list):
        pieces = []
        for item in value:
            if isinstance(item, (int, float)) and not isinstance(item, bool):
                pieces.append(str(item))
            else:
                pieces.append(json.dumps(str(item), ensure_ascii=False))
        return '[' + ', '.join(pieces) + ']'
    value = str(value).strip()
    if key == 'dub_timestamps':
        # Accept comma, semicolon, or pipe separated timestamps in simple sidecars.
        if value.startswith(('[', '(')):
            return value
        pieces = [p.strip() for p in re.split(r'[,;|]', value) if p.strip()]
        if len(pieces) > 1:
            return '[' + ', '.join(json.dumps(p) if ':' in p else p for p in pieces) + ']'
        return '[' + (json.dumps(pieces[0]) if pieces and ':' in pieces[0] else (pieces[0] if pieces else value)) + ']'
    if key in ('caption', 'dub_characters', 'image'):
        if value.startswith(('[', '(')) and key != 'caption':
            return value
        return json.dumps(value.strip('"\''), ensure_ascii=False)
    return value


_METADATA_ALIASES = {
    'caption': {'caption', 'subtitle', 'subtitles', 'line_text', 'dialogue', 'text', 'transcript', 'line'},
    'dub_timestamps': {'dub_timestamps', 'dub_timestamp', 'timestamps', 'timestamp', 'timecodes', 'timecode', 'start_time', 'start_timestamp', 'video_time', 'video_timestamp', 'time_in_video', 'timestamp_seconds', 'timestamps_seconds', 'dub_time', 'dub_start', 'start', 'starttime', 'offset', 'at', 'position'},
    'dub_characters': {'dub_characters', 'dub_character', 'characters', 'character', 'speaker', 'speaker_name', 'actor'},
    'image': {'image', 'image_file', 'image_path', 'thumbnail', 'thumbnail_path', 'portrait', 'icon'},
    'dub_only': {'dub_only'},
}


def normalize_pack_metadata(root: Path) -> int:
    """Merge common INI/TXT/CFG/JSON/YAML sidecars into native per-line INI.

    Multiple sidecars for the same clip are merged with INI/CFG taking
    precedence, then TXT, JSON, and YAML. Common field aliases are mapped to the
    exact keys the compact 3DS parser understands. Source sidecars remain in the
    repository; this edits only the generated staging tree.
    """
    normalized = 0
    meta_extensions = ('.ini', '.cfg', '.txt', '.json', '.yaml', '.yml')
    sources = [p for p in root.rglob('*') if p.is_file() and p.suffix.casefold() in AUDIO_EXTENSIONS
               and not _is_native_companion(p)]
    suffix_priority = {'.ini': 0, '.cfg': 1, '.txt': 2, '.json': 3, '.yaml': 4, '.yml': 5}
    for audio in sources:
        try:
            siblings = list(audio.parent.iterdir())
        except OSError:
            continue
        sidecars = [p for p in siblings if p.is_file() and p.stem.casefold() == audio.stem.casefold()
                    and p.suffix.casefold() in meta_extensions]
        if not sidecars:
            continue
        sidecars.sort(key=lambda p: (suffix_priority.get(p.suffix.casefold(), 9), p.name.casefold()))
        merged: dict[str, object] = {}
        saw_non_native_format = False
        saw_alias = False
        for sidecar in sidecars:
            ext = sidecar.suffix.casefold()
            try:
                raw_text = sidecar.read_text(encoding='utf-8-sig', errors='replace')
                if ext == '.json':
                    obj = json.loads(raw_text)
                    if isinstance(obj, dict) and isinstance(obj.get('data'), dict):
                        obj = obj['data']
                    fields = {str(k).casefold(): v for k, v in obj.items()} if isinstance(obj, dict) else {}
                    saw_non_native_format = True
                else:
                    fields = _parse_simple_metadata(raw_text)
                    if not fields and ext == '.txt':
                        first_line = next((ln.strip() for ln in raw_text.splitlines() if ln.strip()), '')
                        if first_line:
                            fields = {'caption': first_line}
                    if ext in ('.yaml', '.yml'):
                        saw_non_native_format = True
            except (OSError, ValueError, TypeError):
                continue
            for key, value in fields.items():
                target = next((target for target, aliases in _METADATA_ALIASES.items() if key in aliases), None)
                if target is None or value in (None, '') or target in merged:
                    continue
                merged[target] = value
                if key != target:
                    saw_alias = True
            if sidecar.suffix != ext:
                saw_non_native_format = True

        if not merged:
            # A simple plain-text .txt is already handled by the native fallback.
            continue
        # Build a canonical .ini for the native parser. This also combines a
        # caption in a TXT with timestamps in an INI/JSON sidecar.
        canonical = audio.with_suffix('.ini')
        already_simple = (len(sidecars) == 1 and sidecars[0] == canonical and
                          not saw_alias and not saw_non_native_format and
                          all(k in merged for k in ('caption', 'dub_timestamps', 'dub_characters', 'image', 'dub_only')))
        if already_simple:
            continue
        lines = ['[data]']
        for key in ('caption', 'dub_timestamps', 'dub_characters', 'image', 'dub_only'):
            if key in merged:
                lines.append(f'{key}={_metadata_scalar(merged[key], key)}')
        tmp = canonical.with_name(canonical.name + '.tmp')
        tmp.write_text('\n'.join(lines) + '\n', encoding='utf-8')
        tmp.replace(canonical)
        normalized += 1
    if normalized:
        print(f'[metadata] merged/normalized {normalized} per-line sidecar set(s) for native parsing')
    return normalized


def probe_has_video(path: Path) -> bool:
    ffprobe = shutil.which('ffprobe')
    if not ffprobe:
        # Let FFmpeg report an invalid candidate when ffprobe isn't installed.
        return path.suffix.casefold() in VIDEO_EXTENSIONS
    result = subprocess.run([ffprobe, '-v', 'error', '-select_streams', 'v:0',
                             '-show_entries', 'stream=codec_type', '-of', 'csv=p=0', str(path)],
                            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    return result.returncode == 0 and 'video' in result.stdout.casefold()


def _pack_info_video(pack_dir: Path) -> Path | None:
    info_names = {
        '_pack_info.ini', 'pack_info.ini', 'pack.ini', 'info.ini', '_pack_info.txt',
        '_pack_info.json', 'pack_info.json', 'pack.json', '_pack_info.yaml', '_pack_info.yml',
    }
    for info in pack_dir.iterdir():
        if not info.is_file() or info.name.casefold() not in info_names:
            continue
        try:
            text = info.read_text(encoding='utf-8-sig', errors='replace')
            if info.suffix.casefold() == '.json':
                parsed = json.loads(text)
                if isinstance(parsed, dict) and isinstance(parsed.get('data'), dict):
                    parsed = parsed['data']
                fields = {str(k).casefold(): v for k, v in parsed.items()} if isinstance(parsed, dict) else {}
            else:
                fields = _parse_simple_metadata(text)
        except (OSError, ValueError, TypeError):
            continue
        for key in ('dub_video', 'video', 'video_file', 'video_path', 'source_video', 'movie', 'media_file'):
            value = fields.get(key)
            if not value:
                continue
            token = str(value).strip().strip('"\'')
            if not token:
                continue
            candidate = (pack_dir / token).resolve()
            try:
                candidate.relative_to(pack_dir.resolve())
            except ValueError:
                continue
            if candidate.is_file() and candidate.suffix.casefold() not in ('.tcv', '.ini', '.cfg', '.txt', '.json', '.yaml', '.yml'):
                return candidate
    return None


def _audio_base_stem(path: Path) -> str:
    name = path.name
    if name.casefold().endswith('.3ds.wav'):
        return name[:-len('.3ds.wav')]
    return path.stem


def pack_has_timed_line_audio(pack_dir: Path) -> bool:
    """Return true when a folder has line audio plus usable timing metadata.

    This guards the fallback that auto-detects a single arbitrarily named video:
    ordinary voice-only packs or preview folders shouldn't be mistaken for dub
    packs just because they contain an audio file and a movie/image asset.
    """
    try:
        files = [p for p in pack_dir.iterdir() if p.is_file() and not p.name.startswith('.')]
    except OSError:
        return False
    audio = [p for p in files if (p.suffix.casefold() in AUDIO_EXTENSIONS or p.name.casefold().endswith('.3ds.wav'))
             and not p.name.startswith('_')]
    if not audio:
        return False
    metadata = [p for p in files if p.suffix.casefold() in ('.ini', '.cfg', '.txt', '.json', '.yaml', '.yml')]
    metadata_by_stem = {p.stem.casefold(): p for p in metadata}
    time_keys = set(_METADATA_ALIASES['dub_timestamps'])
    for clip in audio:
        stem = _audio_base_stem(clip).casefold()
        sidecar = metadata_by_stem.get(stem)
        if sidecar:
            try:
                text = sidecar.read_text(encoding='utf-8-sig', errors='replace')
                if any(re.search(rf'(?im)^\s*["\']?{re.escape(key)}["\']?\s*[:=]\s*[^\s,}}]+', text) for key in time_keys):
                    return True
                if sidecar.suffix.casefold() == '.json':
                    data = json.loads(text)
                    if isinstance(data, dict):
                        if isinstance(data.get('data'), dict): data = data['data']
                        if any(str(key).casefold() in time_keys and data.get(key) not in (None, '', []) for key in data):
                            return True
            except (OSError, ValueError, TypeError):
                pass
        if re.search(r'_[^_]*-\d[\d.-]*$', clip.stem):
            return True
    return False


def discover_video_candidates(pack_dir: Path) -> list[Path]:
    """Find a video source regardless of common container or basename.

    `dub_video.tcv` is always the generated target. Standard `dub_video.*`
    names take priority; `_pack_info.ini` may explicitly point to another path;
    and a single detectable video may be auto-selected when its folder contains
    timestamped dialogue audio. This supports nested extraction folders without
    mistaking voice-only packs for video packs.
    """
    if not pack_dir.is_dir():
        return []
    direct = [p for p in pack_dir.iterdir() if p.is_file() and not p.name.startswith('.')]
    result: list[Path] = []
    declared = _pack_info_video(pack_dir)
    if declared:
        result.append(declared)
    ext_rank = {ext: i for i, ext in enumerate(VIDEO_EXT_PRIORITY)}
    stem_rank = {stem: i for i, stem in enumerate(VIDEO_STEMS)}
    named = [p for p in direct if p.suffix.casefold() != '.tcv' and p.stem.casefold() in stem_rank]
    named.sort(key=lambda p: (stem_rank[p.stem.casefold()], ext_rank.get(p.suffix.casefold(), 100), p.name.casefold()))
    for p in named:
        if p not in result:
            result.append(p)
    if not result:
        generic = [p for p in direct if p.suffix.casefold() in VIDEO_EXTENSIONS and p.suffix.casefold() != '.tcv']
        generic.sort(key=lambda p: (ext_rank.get(p.suffix.casefold(), 100), p.name.casefold()))
        generic = [p for p in generic if probe_has_video(p)]
        if len(generic) == 1 and pack_has_timed_line_audio(pack_dir):
            result.append(generic[0])
    if not result and pack_has_timed_line_audio(pack_dir):
        # Some exports put the video in a one-level `video/`/`media/` directory.
        # Only auto-adopt a single descendant video if the pack root itself has
        # the timestamped line audio. Collection folders therefore stay safe.
        descendants: list[Path] = []
        for subdir in pack_dir.iterdir():
            if not subdir.is_dir() or subdir.name.startswith('.'):
                continue
            for candidate in subdir.rglob('*'):
                if not candidate.is_file() or candidate.suffix.casefold() not in VIDEO_EXTENSIONS:
                    continue
                if candidate.stem.casefold() in ('cover', 'thumbnail', 'preview', 'poster'):
                    continue
                if probe_has_video(candidate):
                    descendants.append(candidate)
                    if len(descendants) > 1:
                        break
            if len(descendants) > 1:
                break
        if len(descendants) == 1:
            result.append(descendants[0])
    # An explicit but corrupt `dub_video` should still be tried first, followed
    # by alternate known names; convert_video reports each failure and only the
    # pack fails when all candidates are unusable.
    return result


def _valid_tcv(path: Path) -> bool:
    try:
        with path.open('rb') as f:
            header = f.read(HEADER.size)
        if len(header) != HEADER.size:
            return False
        magic, width, height, fps, key_interval, count, index_offset = HEADER.unpack(header)
        if (magic, width, height, fps, key_interval, index_offset) != (b'TCV1', WIDTH, HEIGHT, FPS, KEY_INTERVAL, HEADER.size):
            return False
        if count < 1 or count > MAX_FRAMES or path.stat().st_size < HEADER.size + count * 4:
            return False
        return True
    except (OSError, struct.error):
        return False


def _write_source_marker(pack_dir: Path, source: Path) -> None:
    try:
        relative = source.resolve().relative_to(pack_dir.resolve())
    except ValueError:
        relative = source.name
    (pack_dir / '.tcv-source-file').write_text(str(relative).replace('\\', '/') + '\n', encoding='utf-8')

def convert_pack_images(root: Path) -> int:
    """Write bounded RGBA companions so pack icons/line art can render natively."""
    converted = 0
    for source in (p for p in root.rglob('*') if p.is_file() and p.suffix.casefold() in IMAGE_EXTENSIONS):
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
    # Normalize metadata first, so aliases / JSON sidecars / uppercase extensions
    # are available when the native C scanner loads each converted line.
    normalize_pack_metadata(root)
    converted_videos = 0
    failures: list[str] = []
    directories = [root] + sorted((p for p in root.rglob('*') if p.is_dir()
                                  and not any(part.startswith('.') for part in p.relative_to(root).parts)),
                                 key=lambda p: str(p).casefold())
    for pack_dir in directories:
        tcv = pack_dir / 'dub_video.tcv'
        candidates = discover_video_candidates(pack_dir)
        if not candidates:
            if tcv.exists() and _valid_tcv(tcv):
                print(f'[skip] already-ready TCV: {tcv.relative_to(root)}')
            elif tcv.exists():
                failures.append(f'{pack_dir.relative_to(root)}: existing dub_video.tcv is invalid and no source video was found to rebuild it')
                print(f'[error] Invalid TCV and no source video to rebuild: {tcv}', file=sys.stderr)
            elif pack_has_timed_line_audio(pack_dir):
                failures.append(f'{pack_dir.relative_to(root)}: timestamped dialogue exists, but no video was found; add a source video or set `video_file` in _pack_info.ini')
                print(f'[error] Dub pack has timestamped dialogue but no discoverable video: {pack_dir}', file=sys.stderr)
            continue
        if tcv.exists() and _valid_tcv(tcv):
            try:
                newest_source = max(p.stat().st_mtime for p in candidates if p.is_file())
            except ValueError:
                newest_source = 0
            if tcv.stat().st_mtime >= newest_source:
                _write_source_marker(pack_dir, candidates[0])
                print(f'[skip] current TCV: {tcv.relative_to(root)}')
                continue
        converted = False
        candidate_errors = []
        for source in candidates:
            try:
                if source.resolve() == tcv.resolve():
                    continue
                meta = convert_video(source, tcv)
                if not _valid_tcv(tcv):
                    raise RuntimeError('converter output failed TCV header validation')
                _write_source_marker(pack_dir, source)
                converted_videos += 1
                print(f'[video] {source.relative_to(root)} -> {tcv.relative_to(root)}: '
                      f'{meta["frames"]} frames, {meta["duration"]:.1f}s, {meta["bytes"]:,} bytes')
                converted = True
                break
            except (OSError, RuntimeError, ValueError, subprocess.CalledProcessError) as exc:
                candidate_errors.append(f'{source.name}: {exc}')
        if not converted:
            details = '; '.join(candidate_errors) or 'no usable video source found'
            failures.append(f'{pack_dir.relative_to(root)}: {details}')
            print(f'[error] Dub pack video conversion failed for {pack_dir}: {details}', file=sys.stderr)
    converted_audio = prepare_voice_pack_audio(root) if transcode_audio else 0
    converted_images = convert_pack_images(root)
    print(f'[done] {converted_videos} video(s), {converted_audio} audio companion(s), '
          f'{converted_images} image companion(s) prepared under {root}')
    if failures:
        preview = '\n'.join(f'  - {line}' for line in failures[:30])
        extra = '' if len(failures) <= 30 else f'\n  ... and {len(failures) - 30} more'
        raise RuntimeError('Some dub packs could not be converted. Fix/replace these source videos and rebuild:\n'
                           + preview + extra)
    return converted_videos, converted_audio


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--tree', required=True, help='Root directory containing voice/dub packs; scans nested folders')
    parser.add_argument('--no-audio', action='store_true', help='Only convert videos to .tcv')
    args = parser.parse_args()
    try:
        prepare_tree(Path(args.tree), not args.no_audio)
    except (OSError, RuntimeError, ValueError, subprocess.CalledProcessError) as e:
        print(f'[error] {e}', file=sys.stderr)
        return 2
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
