#!/usr/bin/env python3
"""Compile and exercise actual native Dub Pack discovery against test folders."""
from __future__ import annotations
import shutil
import subprocess
import tempfile
from pathlib import Path
try:
    import resource
except ImportError:  # Windows does not expose setrlimit; source stack checks still run.
    resource = None

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
        cmd = [cc, "-std=gnu11", "-O2", "-fstack-usage", "-ffunction-sections", "-fdata-sections",
               "-Wno-implicit-function-declaration", "-Wno-int-conversion",
               "-Wno-pointer-to-int-cast", "-Wno-incompatible-pointer-types",
               "-Wno-unused-parameter", "-Wno-unused-function",
               "-I", str(ROOT / "tools" / "3ds_test_stub"),
               str(ROOT / "tools" / "test_dub_pack_browser.c"),
               "-Wl,--gc-sections", "-lz", "-lm", "-o", str(exe)]
        subprocess.run(cmd, check=True)
        subprocess.run([str(exe), str(base)], check=True)
        # Exercise the exact multi-root entrypoint used when the user opens the
        # pack browser. Keep all fixtures relative to that process's cwd because
        # the 3DS paths are literal sdmc:/ and romfs:/ prefixes in the native code.
        roots = [
            (base / "sdmc:" / "3ds" / "TheChoicerVoicer3DS_User" / "packs_voice", "Nested Pack", True),
            (base / "sdmc:" / "3ds" / "The Choicer Voicer" / "packs_voice", "Legacy Pack", False),
            (base / "romfs:" / "tcv" / "packs_voice", "Embedded Pack", False),
        ]
        for root, pack_name, nested_folder in roots:
            root.mkdir(parents=True, exist_ok=True)
            if nested_folder:
                make_pack(root / "Collection", pack_name, "dub_video.tcv", "[1.0]")
            else:
                make_pack(root, pack_name, "dub_video.tcv", "[1.0]")
        def limit_stack():
            assert resource is not None
            soft, hard = resource.getrlimit(resource.RLIMIT_STACK)
            target = 64 * 1024
            if hard != resource.RLIM_INFINITY:
                target = min(target, hard)
            resource.setrlimit(resource.RLIMIT_STACK, (target, hard))
        run_kwargs = {"cwd": base, "check": True}
        if resource is not None:
            run_kwargs["preexec_fn"] = limit_stack
        subprocess.run([str(exe), "--scan-all"], **run_kwargs)
        # The app-side scan entry point must stay small enough for the 3DS
        # stack; inspect GCC's measured function frame sizes to catch regressions.
        usage_files = list(base.glob("*.su"))
        if not usage_files:
            raise SystemExit("GCC did not emit the requested -fstack-usage report")
        usage_text = "\n".join(f.read_text(encoding="utf-8", errors="replace") for f in usage_files)
        import re
        def measured_frame(name: str) -> int:
            rows = [line for line in usage_text.splitlines() if re.search(r":" + re.escape(name) + r"(?:\.|\s)", line)]
            if not rows:
                raise SystemExit(f"No GCC stack-usage row found for {name}")
            return max(int(row.split("\t")[1]) for row in rows)
        if measured_frame("scan_all_dub_pack_roots") > 1024:
            raise SystemExit("scan_all_dub_pack_roots uses too much stack; keep scratch buffers static")
        if measured_frame("scan_dub_pack_root") > 4096:
            raise SystemExit("scan_dub_pack_root uses too much stack for Old 3DS")
        if measured_frame("begin_match") > 4096:
            raise SystemExit("begin_match uses too much stack for Old 3DS")
        if measured_frame("activate_menu") > 2048:
            raise SystemExit("activate_menu uses too much stack for Old 3DS")
        if measured_frame("scan_voice_dir") > 16384:
            raise SystemExit("scan_voice_dir uses too much stack for Old 3DS")
        # Also test the complete real example pack included with this updated source.
        actual_pack_root = ROOT / "packs_voice"
        subprocess.run([str(exe), str(actual_pack_root), "--verity-fixture"], check=True)
    stack_mode = "with a 64 KiB stack limit" if resource is not None else "with GCC stack-frame checks"
    print(f"PASS: pack discovery works across user/legacy/embedded roots {stack_mode}, handles nested folders, and recognizes the 46-line verity-song pack.")


if __name__ == "__main__":
    main()
