#!/usr/bin/env python3
"""Compile and exercise actual native Dub Pack discovery against test folders."""
from __future__ import annotations
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def make_pack(root: Path, name: str, video: str, timestamps: str | None) -> None:
    pack = root / name
    pack.mkdir(parents=True)
    (pack / video).write_bytes(b"fixture video marker")
    if timestamps is not None:
        (pack / "Line.3ds.wav").write_bytes(b"normalized wav fixture")
        (pack / "Line.ini").write_text(f'[data]\ncaption="Line"\ndub_timestamps={timestamps}\n', encoding="utf-8")


def make_nested_verity_style_pack(root: Path) -> Path:
    # Mirrors the user's verity_song.zip layout: an extracted top-level folder,
    # 001_Name.wav + 001_Name.jpg + 001_Name.txt, dub_video.ogv, and pack info.
    pack = root / "Collection" / "verity song"
    pack.mkdir(parents=True)
    (pack / "dub_video.tcv").write_bytes(b"fixture converted video")
    (pack / "_pack_info.ini").write_text('[data]\ntitle="verity song"\nicon="001_Verity.jpg"\n', encoding="utf-8")
    (pack / "001_Verity.3ds.wav").write_bytes(b"normalized line audio")
    (pack / "001_Verity.jpg").write_bytes(b"fixture art")
    (pack / "001_Verity.txt").write_text('[data]\ncaption="Hey, its me, its Verity!"\nimage="001_Verity.jpg"\ndub_timestamps=[1.695]\ndub_characters=["Verity"]\n', encoding="utf-8")
    (pack / "002_the_guy.3ds.wav").write_bytes(b"normalized line audio")
    (pack / "002_the_guy.txt").write_text('[data]\ncaption="i got a question"\ndub_timestamps=[8.163]\ndub_characters=["the guy"]\n', encoding="utf-8")
    return pack


def main() -> None:
    cc = shutil.which("cc") or shutil.which("gcc")
    if not cc:
        raise SystemExit("A C compiler is required for the native Dub Pack browser test")
    with tempfile.TemporaryDirectory(prefix="tcv-dub-browser-") as temp:
        base = Path(temp)
        make_pack(base, "Needs Convert", "dub_video.ogv", "[1.0]")
        make_pack(base, "No Timestamps", "dub_video.tcv", None)
        make_pack(base, "Ready Dub", "dub_video.tcv", "[0.5, 2.25]")
        voice_only = base / "Voice Only"
        voice_only.mkdir()
        (voice_only / "hello.3ds.wav").write_bytes(b"voice fixture")
        nested = make_nested_verity_style_pack(base)
        exe = base / "test_dub_pack_browser"
        cmd = [cc, "-std=gnu11", "-O0", "-ffunction-sections", "-fdata-sections",
               "-Wno-implicit-function-declaration", "-Wno-int-conversion",
               "-Wno-pointer-to-int-cast", "-Wno-incompatible-pointer-types",
               "-Wno-unused-parameter", "-Wno-unused-function",
               "-I", str(ROOT / "tools" / "3ds_test_stub"),
               str(ROOT / "tools" / "test_dub_pack_browser.c"),
               "-Wl,--gc-sections", "-lz", "-lm", "-o", str(exe)]
        subprocess.run(cmd, check=True)
        subprocess.run([str(exe), str(base)], check=True)
        # Also test the complete real example pack included with this updated source.
        actual_pack_root = ROOT / "packs_voice"
        subprocess.run([str(exe), str(actual_pack_root), "--verity-fixture"], check=True)
    print("PASS: recursive Dub Pack discovery finds folder-based packs, parses the verity-song file pattern, filters voice-only folders, and keeps exact nested paths.")


if __name__ == "__main__":
    main()
