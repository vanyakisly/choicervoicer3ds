#!/usr/bin/env python3
"""Prepare The Choicer Voicer's real artwork/audio/default packs for the native 3DS runtime.

Run on the GitHub runner (Pillow + ffmpeg required), not on the 3DS.
"""
from __future__ import annotations
import argparse
import shutil
import struct
import subprocess
import wave
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
from prepare_3ds_dub_packs import (AUDIO_EXTENSIONS, IMAGE_EXTENSIONS, convert_audio_tree, convert_pack_images, prepare_tree as prepare_voice_packs)

SPRITES = {
    "logo_banner": ("graphic/image/cv_temp_preview_banner.png", (240, 90)),
    "logo_icon": ("graphic/image/cv_temp_preview_icon.png", (128, 128)),
    "developer_logo": ("graphic/image/yeahmaybe_logo.png", (150, 86)),
    "host_default": ("game_default/packs_host/Default - Shae/host.png", (116, 220)),
    "player_default": ("game_default/packs_player/Player/player.png", (92, 184)),
    "judge_1": ("game_default/packs_judges/The Choicer Voicer's Default Judges/judge1.png", (70, 145)),
    "judge_2": ("game_default/packs_judges/The Choicer Voicer's Default Judges/judge2.png", (70, 145)),
    "judge_3": ("game_default/packs_judges/The Choicer Voicer's Default Judges/judge3.png", (70, 145)),
    "judge_4": ("game_default/packs_judges/The Choicer Voicer's Default Judges/judge4.png", (70, 145)),
    "judge_5": ("game_default/packs_judges/The Choicer Voicer's Default Judges/judge5.png", (70, 145)),
    "wave_good": ("graphic/image/waveform_good.png", (300, 112)),
    "wave_loud": ("graphic/image/waveform_loud.png", (300, 112)),
    "wave_quiet": ("graphic/image/waveform_quiet.png", (300, 112)),
    "wave_timing": ("graphic/image/waveform_timing.png", (300, 112)),
    "gameshow_scene": ("assets/images/screens/game_example_twitch.png", (400, 225)),
    "panelist_scene": ("assets/images/screens/panelist_example.png", (400, 225)),
    "dub_standard_scene": ("assets/images/screens/preview_image_dub_standard.png", (400, 225)),
    "dub_freestyle_scene": ("assets/images/screens/preview_image_dub_freestyle.png", (400, 225)),
    "help_packguide": ("graphic/image/shae_help_packguide.png", (300, 140)),
    "help_pack_folders": ("graphic/image/shae_help_packs_folders.png", (110, 180)),
    "help_judges": ("graphic/image/shae_help_judges.png", (300, 170)),
    "help_performance": ("graphic/image/shae_help_performance.png", (300, 170)),
    "help_score": ("graphic/image/shae_help_score.png", (240, 130)),
    "mic": ("graphic/image/waverecord_mic.png", (70, 116)),
    "record_button": ("graphic/image/waverecord_roundedwhite.png", (230, 122)),
    "credit_pierce": ("graphic/image/credit_pierce.png", (80, 80)),
    "credit_vinny": ("graphic/image/credit_vinny.png", (80, 80)),
    "credit_jimmy": ("graphic/image/credit_jimmy.png", (80, 80)),
    "credit_kiophen": ("graphic/image/credit_kiophen.png", (80, 80)),
    "credit_azureotsu": ("graphic/image/credit_azureotsu.png", (80, 80)),
    "credit_madclown": ("graphic/image/credit_madclown.png", (80, 80)),
    "credit_alizarin": ("graphic/image/credit_alizarin.png", (80, 80)),
    "clip_1": ("game_default/packs_voice/The Choicer Voicer Tutorial Pack/ChoicerVoicerTutorialPack1.png", (106, 106)),
    "clip_2": ("game_default/packs_voice/The Choicer Voicer Tutorial Pack/ChoicerVoicerTutorialPack2.png", (106, 106)),
    "clip_3": ("game_default/packs_voice/The Choicer Voicer Tutorial Pack/ChoicerVoicerTutorialPack3.png", (106, 106)),
    "clip_4": ("game_default/packs_voice/The Choicer Voicer Tutorial Pack/ChoicerVoicerTutorialPack4.png", (106, 106)),
    "clip_5": ("game_default/packs_voice/The Choicer Voicer Tutorial Pack/ChoicerVoicerTutorialPack5.png", (106, 106)),
}

PACKS = ["packs_voice", "packs_player", "packs_host", "packs_judges", "packs_studio", "packs_menu", "packs_twitch"]


def write_rgba(path: Path, image: Image.Image) -> None:
    image = image.convert("RGBA")
    w, h = image.size
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("wb") as f:
        f.write(struct.pack("<4sHH", b"TCVR", w, h))
        f.write(image.tobytes())


def fit_image(source: Path, maximum: tuple[int, int]) -> Image.Image:
    im = Image.open(source).convert("RGBA")
    im.thumbnail(maximum, Image.Resampling.LANCZOS)
    return im


def make_font(source_root: Path, out_dir: Path, name: str, font_file: str, size: int, cell: tuple[int, int]) -> None:
    font_path = source_root / "graphic/font" / font_file
    if not font_path.is_file():
        return
    cw, ch = cell
    cols, rows = 16, 6
    atlas = Image.new("RGBA", (cols*cw, rows*ch), (255, 255, 255, 0))
    d = ImageDraw.Draw(atlas)
    font = ImageFont.truetype(str(font_path), size=size)
    for i, code in enumerate(range(32, 128)):
        char = chr(code)
        x, y = (i % cols) * cw, (i // cols) * ch
        bbox = d.textbbox((0, 0), char, font=font, stroke_width=0)
        gw, gh = bbox[2]-bbox[0], bbox[3]-bbox[1]
        dx = x + max(0, (cw-gw)//2) - bbox[0]
        dy = y + max(0, (ch-gh)//2) - bbox[1] - 1
        d.text((dx, dy), char, font=font, fill=(255, 255, 255, 255))
    write_rgba(out_dir / f"{name}.rgba", atlas)


def copy_tree(source: Path, destination: Path) -> None:
    if not source.exists():
        return
    if destination.exists():
        shutil.rmtree(destination)
    shutil.copytree(source, destination)


def convert_compressed_audio(audio_root: Path) -> None:
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        raise SystemExit("ffmpeg is required by prepare_3ds_assets.py to convert MP3/OGG sounds for the 3DS build")
    for source in list(audio_root.rglob("*.mp3")) + list(audio_root.rglob("*.ogg")):
        # Native runtime understands PCM WAV; keep original compressed source alongside the converted file.
        destination = source.with_suffix(".wav")
        if destination.exists():
            continue
        subprocess.run([
            ffmpeg, "-hide_banner", "-loglevel", "error", "-y", "-i", str(source),
            "-ar", "22050", "-ac", "1", "-c:a", "pcm_s16le", str(destination)
        ], check=True)


def optimize_large_wavs(root: Path, minimum_bytes: int = 1024 * 1024) -> tuple[int, int]:
    """Shrink large WAVs to mono PCM16/16-kHz to fit the native 4-MiB audio cap.

    Only files larger than 1 MiB are inspected, avoiding hundreds of tiny FFmpeg
    invocations during pack staging. Already compliant WAV companions are kept.
    """
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        raise SystemExit("ffmpeg is required to optimize native WAV files")
    converted = 0
    bytes_saved = 0
    for source in sorted(root.rglob("*.wav")):
        if not source.is_file() or source.stat().st_size < minimum_bytes:
            continue
        try:
            with wave.open(str(source), "rb") as reader:
                compliant = (reader.getnchannels() == 1 and reader.getframerate() == 16000
                             and reader.getsampwidth() == 2 and reader.getcomptype() == "NONE")
            if compliant:
                continue
        except (wave.Error, EOFError):
            # Let FFmpeg repair/normalize WAVs with unsupported chunk layouts.
            pass
        before = source.stat().st_size
        temporary = source.with_name(source.name + ".optimized.wav")
        try:
            subprocess.run([
                ffmpeg, "-hide_banner", "-loglevel", "error", "-y", "-threads", "1",
                "-i", str(source), "-vn", "-ar", "16000", "-ac", "1",
                "-c:a", "pcm_s16le", str(temporary)
            ], check=True)
            if not temporary.is_file() or temporary.stat().st_size < 44:
                raise RuntimeError(f"ffmpeg produced an invalid WAV: {source}")
            # Validate output format before replacing the only staged copy.
            with wave.open(str(temporary), "rb") as reader:
                if (reader.getnchannels(), reader.getframerate(), reader.getsampwidth(), reader.getcomptype()) != (1, 16000, 2, "NONE"):
                    raise RuntimeError(f"ffmpeg output did not normalize correctly: {source}")
            temporary.replace(source)
            converted += 1
            bytes_saved += before - source.stat().st_size
        finally:
            try:
                temporary.unlink()
            except FileNotFoundError:
                pass
    return converted, bytes_saved


def prune_runtime_files(runtime_root: Path) -> tuple[int, int]:
    """Drop original-format duplicates only after native companions are verified.

    `.tcv-source-file` markers identify alternate-named source videos (e.g.
    movie.mkv) that were transcoded to dub_video.tcv. We can remove those from
    the embedded staging tree without touching the original repository source.
    """
    removed = 0
    bytes_removed = 0
    root_resolved = runtime_root.resolve()
    for marker in sorted(runtime_root.rglob('.tcv-source-file')):
        try:
            rel = marker.read_text(encoding='utf-8', errors='replace').strip().replace('\\', '/')
            source = (marker.parent / rel).resolve()
            source.relative_to(root_resolved)
            if source.is_file() and source != marker.resolve():
                size = source.stat().st_size
                source.unlink()
                removed += 1
                bytes_removed += size
            marker.unlink()
            removed += 1
        except (OSError, ValueError):
            try:
                marker.unlink()
                removed += 1
            except OSError:
                pass

    for source in sorted((p for p in runtime_root.rglob('*') if p.is_file()), reverse=True):
        low = source.name.casefold()
        suffix = source.suffix.casefold()
        remove = False
        # Check native companions before the broad audio-extension set: WAV is
        # itself in AUDIO_EXTENSIONS, so source.with_suffix('.wav') would point
        # back to the same file and could mistakenly delete every default WAV.
        if low.endswith('.3ds.wav'):
            remove = False
        elif suffix == '.wav':
            # Preserve default music/SFX WAVs unless a distinct 3DS companion exists.
            native_companion = source.with_name(source.stem + '.3ds.wav')
            remove = native_companion.is_file() and native_companion.resolve() != source.resolve()
        elif suffix in AUDIO_EXTENSIONS:
            # Compressed sources can be removed only when a distinct normalized
            # WAV or dedicated .3ds.wav companion has actually been generated.
            candidates = (source.with_suffix('.wav'), source.with_name(source.stem + '.3ds.wav'))
            remove = any(c.resolve() != source.resolve() and c.is_file() for c in candidates)
        elif suffix == '.ogv':
            remove = source.with_name('dub_video.tcv').is_file()
        elif suffix in IMAGE_EXTENSIONS:
            remove = source.with_suffix('.tcvr').is_file()
        elif suffix == '.import':
            remove = True
        if remove:
            try:
                size = source.stat().st_size
                source.unlink()
                removed += 1
                bytes_removed += size
            except OSError:
                pass
    return removed, bytes_removed


def _native_timestamp_seconds(value: str) -> float | None:
    value = value.strip().strip('[]()').strip().strip('\"\'')
    if not value:
        return None
    try:
        parts = value.split(':')
        if len(parts) == 3:
            seconds = float(parts[0]) * 3600.0 + float(parts[1]) * 60.0 + float(parts[2])
        elif len(parts) == 2:
            seconds = float(parts[0]) * 60.0 + float(parts[1])
        elif len(parts) == 1:
            seconds = float(parts[0])
        else:
            return None
    except ValueError:
        return None
    return seconds if 0.0 <= seconds <= 86400.0 else None


def _count_native_timestamps(stem: Path) -> int:
    """Count timestamps the C runtime will accept for one normalized line."""
    raw = None
    for ext in ('.ini', '.cfg', '.txt'):
        meta = stem.with_suffix(ext)
        if not meta.is_file():
            continue
        try:
            text = meta.read_text(encoding='utf-8-sig', errors='replace')
        except OSError:
            continue
        # Native parser deliberately consumes the first existing sidecar. The
        # converter has already merged non-native sidecars into canonical INI.
        for line in text.splitlines():
            stripped = line.strip()
            if not stripped or stripped.startswith(('#', ';', '[')):
                continue
            sep = '=' if '=' in stripped else (':' if ':' in stripped else None)
            if not sep:
                continue
            key, value = stripped.split(sep, 1)
            if key.strip().casefold() in ('dub_timestamps', 'dub_timestamp'):
                raw = value.strip()
                break
        break
    if raw is not None:
        value = raw.strip()
        if value.startswith(('[', '(')):
            value = value[1:]
        value = value.rstrip('])} \t')
        count = sum(1 for item in value.split(',') if _native_timestamp_seconds(item) is not None)
        if count:
            return count
    # Match the C loader's final fallback: `clip_1-25.wav` means 1.25 s.
    leaf = stem.name
    pivot = leaf.rfind('_')
    if pivot >= 0 and '-' in leaf[pivot + 1:]:
        fallback = leaf[pivot + 1:].replace('-', '.')
        if _native_timestamp_seconds(fallback) is not None:
            return 1
    return 0


def write_embedded_dub_catalog(voice_root: Path) -> int:
    """Write a tiny index so the 3DS doesn't recursively scan immutable RomFS.

    Each record is relative-pack-path<TAB>number-of-timestamped-line-events.
    Custom/legacy SD roots are still scanned as an optional fallback.
    """
    records: list[tuple[str, int]] = []
    if voice_root.is_dir():
        for video in sorted(voice_root.rglob('dub_video.tcv'), key=lambda p: str(p).casefold()):
            rel_dir = video.parent.relative_to(voice_root)
            if str(rel_dir) == '.':
                continue
            rel = rel_dir.as_posix()
            parts = rel.split('/')
            if len(rel) >= 192 or any(not part or part in ('.', '..') or part.startswith(('.', '_')) for part in parts):
                continue
            clip_count = 0
            for audio in sorted(video.parent.rglob('*.3ds.wav'), key=lambda p: str(p).casefold()):
                relative_audio = audio.relative_to(video.parent)
                if any(part.startswith(('.', '_')) for part in relative_audio.parts):
                    continue
                stem = audio.with_name(audio.name[:-len('.3ds.wav')])
                clip_count += _count_native_timestamps(stem)
            records.append((rel, min(clip_count, 256)))
    catalog = voice_root / '.tcv_pack_index.tsv'
    catalog.parent.mkdir(parents=True, exist_ok=True)
    with catalog.open('w', encoding='utf-8', newline='\n') as stream:
        for relative, clip_count in records:
            stream.write(f'{relative}\t{clip_count}\n')
    print(f'Indexed {len(records)} embedded dub pack(s) in {catalog.name}; runtime scan avoids recursive RomFS walk.')
    return len(records)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", default=".", help="Original source project directory")
    parser.add_argument("--output", required=True, help="Read-only runtime data tree embedded into the .3dsx RomFS")
    args = parser.parse_args()
    src = Path(args.source).resolve()
    out = Path(args.output).resolve()
    if out == src:
        raise SystemExit("Refusing to use the entire source project as the generated output directory")
    # Rebuild the generated tree from scratch so stale conversions never leak
    # into a later build (especially after a previous interrupted staging run).
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True, exist_ok=True)
    native = out / "assets_native"
    native.mkdir(parents=True, exist_ok=True)

    for key, (relative, maximum) in SPRITES.items():
        source = src / relative
        if not source.is_file():
            print(f"[warn] optional sprite absent: {relative}")
            continue
        write_rgba(native / f"{key}.rgba", fit_image(source, maximum))

    make_font(src, native, "font_small", "Waukegan LDO.ttf", 14, (12, 18))
    make_font(src, native, "font_large", "Waukegan LDO Bold.ttf", 18, (16, 22))
    required_sprites = ["logo_banner.rgba", "host_default.rgba", "player_default.rgba",
                        "judge_1.rgba", "wave_good.rgba", "mic.rgba",
                        "font_small.rgba", "font_large.rgba"]
    missing = [name for name in required_sprites if not (native / name).is_file()]
    if missing:
        raise SystemExit("Required original TCV UI assets could not be prepared: " + ", ".join(missing))

    # Keep the original audio tree available and use the real game-default SFX/music.
    copy_tree(src / "audio", out / "audio")
    convert_compressed_audio(out / "audio")
    optimized_audio, audio_bytes_saved = optimize_large_wavs(out / "audio")

    # Real starter packs (voice samples, host/players/judges, menu SFX and configs).
    # Custom packs committed at repository-root packs_voice/ etc. are merged into
    # the build artifact under their original folder names, with custom files
    # overriding a same-named default pack if the author intentionally supplied it.
    for pack in PACKS:
        destination = out / pack
        copy_tree(src / "game_default" / pack, destination)
        user_pack_root = src / pack
        if user_pack_root.is_dir():
            destination.mkdir(parents=True, exist_ok=True)
            for user_pack in user_pack_root.iterdir():
                if user_pack.is_dir() and not user_pack.name.startswith("."):
                    shutil.copytree(user_pack, destination / user_pack.name, dirs_exist_ok=True)
        if pack != "packs_voice" and destination.exists():
            # Converters already emit 22.05-kHz PCM16 companions. Avoid a second
            # whole-tree FFmpeg pass; it adds minutes without changing valid output.
            convert_audio_tree(destination)
            optimize_large_wavs(destination)
            convert_pack_images(destination)

    # Real dub packs are kept under packs_voice. Transcode common video containers
    # and normalize the line audio/metadata into the native TCV + PCM format.
    prepare_voice_packs(out / "packs_voice", transcode_audio=True)
    optimized_voice, voice_bytes_saved = optimize_large_wavs(out / "packs_voice")
    # prepare_voice_packs produces PCM16/22.05-kHz companions directly, so no
    # second normalization pass is needed. All native playback is mono to reduce
    # the Old 3DS memory bandwidth and card footprint.

    # Do not copy the original full-resolution graphic/assets/model trees into
    # ROMFS. They remain in the source repository; the 3DS runtime only needs
    # the compact native sprites, converted PCM audio, metadata, and TCV clips.
    removed_count, removed_bytes = prune_runtime_files(out)
    # Build a static catalog after conversion/pruning. RomFS is read-only, so
    # the app can load this small index instead of statting every embedded file.
    embedded_dub_count = write_embedded_dub_catalog(out / "packs_voice")
    (out / "ROMFS-INFO.txt").write_text(
        "The Choicer Voicer — embedded Old 3DS runtime data\n\n"
        "This tree is embedded read-only inside TheChoicerVoicer3DS.3dsx.\n"
        "Do not copy this tree to the SD card.\n"
        "Writable settings and recordings are automatically stored in\n"
        "SD:/3ds/TheChoicerVoicer3DS_User/.\n"
        "Optional custom packs can be placed in SD:/3ds/TheChoicerVoicer3DS_User/packs_voice/.\n"
        "Existing packs under SD:/3ds/The Choicer Voicer/packs_voice/ are read as a legacy\n"
        "fallback, but the application never writes to that folder.\n",
        encoding="utf-8"
    )
    print("Converted compressed audio to mono PCM16; large WAVs are reduced to 16-kHz so they fit the 4-MiB playback cap")
    print(f"Optimized {optimized_audio + optimized_voice} large WAVs; saved {audio_bytes_saved + voice_bytes_saved:,} bytes")
    print(f"Pruned {removed_count} duplicate/source files ({removed_bytes:,} bytes) from runtime data")
    print(f"Indexed {embedded_dub_count} embedded dub pack(s)")
    print(f"Prepared compact embedded runtime tree at {out}")


if __name__ == "__main__":
    main()
