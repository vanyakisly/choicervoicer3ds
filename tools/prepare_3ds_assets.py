#!/usr/bin/env python3
"""Prepare The Choicer Voicer's real artwork/audio/default packs for the native 3DS runtime.

Run on the GitHub runner (Pillow + ffmpeg required), not on the 3DS.
"""
from __future__ import annotations
import argparse
import shutil
import struct
import subprocess
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
from prepare_3ds_dub_packs import convert_audio_tree, prepare_tree as prepare_voice_packs

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
            "-ar", "22050", "-ac", "2", "-c:a", "pcm_s16le", str(destination)
        ], check=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", default=".", help="Original source project directory")
    parser.add_argument("--output", required=True, help="SD:/luma/3ds/The Choicer Voicer staging directory")
    args = parser.parse_args()
    src = Path(args.source).resolve()
    out = Path(args.output).resolve()
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
            convert_audio_tree(destination)

    # Real dub packs are still stored in packs_voice. Keep the original OGV
    # source and create native-friendly TCV video plus WAV companions for clips.
    prepare_voice_packs(out / "packs_voice", transcode_audio=True)

    # Retain all original graphic, asset, and model trees in addition to the
    # compact sprites used by the native renderer.  This keeps the supplied
    # artwork/fonts/screen examples available for future native UI work.
    copy_tree(src / "graphic", out / "source_assets" / "graphic")
    copy_tree(src / "assets", out / "source_assets" / "assets")
    copy_tree(src / "model", out / "source_assets" / "model")

    # A plain install note travels with the SD data folder.
    (out / "INSTALL-ASSETS.txt").write_text(
        "The Choicer Voicer — Old 3DS data\n\n"
        "Copy this entire folder to SD:/luma/3ds/The Choicer Voicer/ .\n"
        "Keep assets_native/, audio/, and the packs_* folders intact.\n"
        "All original graphic/, assets/, and model/ files are preserved under source_assets/.\n"
        "All original music and SFX are preserved under audio/; MP3/OGG files also\n"
        "get PCM WAV companions for native playback. Voice/dub pack source WAV/MP3/OGG files\n"
        "are preserved alongside normalized .3ds.wav companions (22.05 kHz PCM16), and \
"
        "pack image files receive compact .tcvr companions for the native renderer. Dub packs placed in repository-root\n"
        "packs_voice/<Pack Name>/ are copied intact, their dub_video.ogv is preserved,\n"
        "and a 160x90/10fps dub_video.tcv is generated for the Old 3DS player.\n"
        "Each dub clip needs a matching .ini/.cfg/.txt with dub_timestamps=[seconds]\n"
        "or a timestamp suffix such as _44-048 in its filename.\n",
        encoding="utf-8"
    )
    print(f"Prepared native UI, original audio, default/user packs, and converted dub videos at {out}")


if __name__ == "__main__":
    main()
