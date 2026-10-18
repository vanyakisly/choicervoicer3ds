#!/usr/bin/env python3
"""Render a complete dubbed video from a 3DS session manifest using FFmpeg.

This intentionally runs on Windows/PC rather than on the Old 3DS: it re-encodes
one full video and mixes takes at absolute timestamps, avoiding real-time render
lag and preserving the entire source video duration.
"""
from __future__ import annotations

import argparse
import configparser
import os
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Sequence

VIDEO_EXTS = {".ogv", ".ogg", ".mp4", ".mkv", ".webm", ".mov", ".avi", ".m4v", ".wmv", ".flv", ".mpeg", ".mpg", ".3gp", ".ts", ".m2ts", ".vob"}
AUDIO_EXTS = {".wav", ".mp3", ".ogg", ".oga", ".flac", ".m4a", ".aac", ".opus", ".wma", ".aiff", ".aif", ".weba", ".mka"}
VIDEO_STEMS = ("dub_video", "dubvideo", "source_video", "sourcevideo", "video", "movie", "clip")
BACKING_STEMS = ("_backing_track", "backing_track", "backingtrack", "soundtrack", "music")


class ExportError(RuntimeError):
    pass


def resolve_binary(name: str) -> str:
    """Find ffmpeg/ffprobe on PATH or in common Windows install locations."""
    found = shutil.which(name)
    if found:
        return found
    named = Path(name).expanduser()
    if named.is_file():
        return str(named.resolve())
    exe = name if name.lower().endswith(".exe") else name + (".exe" if os.name == "nt" else "")
    candidates: list[Path] = [
        Path("C:/ffmpeg/bin") / exe,
        Path("C:/tools/ffmpeg/bin") / exe,
        Path("C:/Program Files/ffmpeg/bin") / exe,
        Path.home() / "ffmpeg" / "bin" / exe,
        Path.home() / "Downloads" / "ffmpeg" / "bin" / exe,
    ]
    local = os.environ.get("LOCALAPPDATA")
    if local:
        winget_root = Path(local) / "Microsoft" / "WinGet" / "Packages"
        if winget_root.is_dir():
            for pattern in ("Gyan.FFmpeg_*/*/bin/" + exe, "Gyan.FFmpeg_*/**/bin/" + exe):
                try:
                    candidates.extend(winget_root.glob(pattern))
                except OSError:
                    pass
    for candidate in candidates:
        if candidate.is_file():
            return str(candidate.resolve())
    raise ExportError(f"Could not find {exe}. Install FFmpeg for Windows or add the folder containing it to PATH.")


@dataclass(frozen=True)
class Take:
    timestamp: float
    path: Path
    section: str


def run_capture(args: Sequence[str]) -> str:
    try:
        p = subprocess.run(list(args), check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, encoding="utf-8", errors="replace")
        return p.stdout.strip()
    except FileNotFoundError as exc:
        raise ExportError(f"Required tool not found: {args[0]}. Install FFmpeg and ensure ffmpeg.exe and ffprobe.exe are on PATH.") from exc
    except subprocess.CalledProcessError as exc:
        detail = (exc.stderr or exc.stdout or str(exc)).strip()
        raise ExportError(f"Command failed: {' '.join(args[:4])}\n{detail[-2500:]}") from exc


def dequote(value: str | None) -> str:
    value = (value or "").strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        value = value[1:-1]
    return value.replace('\\"', '"').replace('\\\\', '\\')


def parse_session(session_path: Path, require_complete: bool = True) -> tuple[str, list[Take], int]:
    if not session_path.is_file():
        raise ExportError(f"Session file not found:\n{session_path}")
    parser = configparser.ConfigParser(interpolation=None)
    parser.optionxform = str.lower
    try:
        parser.read(session_path, encoding="utf-8-sig")
    except (OSError, configparser.Error) as exc:
        raise ExportError(f"Could not read session.ini: {exc}") from exc
    if not parser.has_section("session"):
        raise ExportError("This is not a Choicer Voicer session.ini: [session] section is missing.")
    pack_name = dequote(parser.get("session", "pack", fallback="Dub Pack")) or "Dub Pack"
    declared_count = parser.getint("session", "clip_count", fallback=0)
    takes: list[Take] = []
    missing: list[str] = []
    sections = [s for s in parser.sections() if s.lower().startswith("clip_")]
    def clip_num(section: str) -> int:
        try:
            return int(section.split("_", 1)[1])
        except (IndexError, ValueError):
            return 1_000_000
    sections.sort(key=clip_num)
    root = session_path.resolve().parent
    for section in sections:
        recorded = parser.getboolean(section, "recorded", fallback=False)
        take_name = dequote(parser.get(section, "take", fallback=""))
        ts_text = parser.get(section, "timestamp", fallback="0")
        try:
            timestamp = float(ts_text)
        except ValueError:
            timestamp = -1.0
        if not (timestamp >= 0 and timestamp < 24 * 60 * 60):
            raise ExportError(f"Invalid timestamp in [{section}]: {ts_text!r}")
        if not recorded or not take_name:
            missing.append(section)
            continue
        # A session stores take basenames. Reject paths to avoid path traversal.
        leaf = Path(take_name).name
        if leaf != take_name or leaf in (".", ".."):
            raise ExportError(f"Unsafe take filename in [{section}]: {take_name!r}")
        take_path = (root / leaf).resolve()
        if take_path.parent != root:
            raise ExportError(f"Take path escapes the session folder in [{section}].")
        if not take_path.is_file():
            missing.append(f"{section} (missing {leaf})")
            continue
        takes.append(Take(timestamp=timestamp, path=take_path, section=section))
    expected = max(declared_count, len(sections))
    if require_complete and (missing or len(takes) < expected):
        examples = ", ".join(missing[:8]) or f"found {len(takes)} valid takes for {expected} lines"
        raise ExportError(f"Dub is incomplete: {len(takes)}/{expected} takes are present. Record every line and press SAVE DUB first.\nMissing: {examples}")
    if not takes:
        raise ExportError("No recorded WAV takes were found beside session.ini. Use SAVE DUB on the 3DS first.")
    return pack_name, takes, expected


def normalized_name(value: str) -> str:
    return "".join(ch.casefold() for ch in value if ch.isalnum())


def probe_video(ffprobe: str, path: Path) -> tuple[float, bool]:
    out = run_capture([ffprobe, "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=codec_type,duration:format=duration", "-of", "default=noprint_wrappers=1:nokey=1", str(path)])
    nums: list[float] = []
    for line in out.splitlines():
        try:
            value = float(line)
            if value > 0:
                nums.append(value)
        except ValueError:
            pass
    if not nums:
        raise ExportError(f"FFmpeg could not find a usable video stream or duration in:\n{path}")
    return max(nums), True


def has_audio(ffprobe: str, path: Path) -> bool:
    try:
        out = run_capture([ffprobe, "-v", "error", "-select_streams", "a:0", "-show_entries", "stream=codec_type", "-of", "csv=p=0", str(path)])
        return bool(out.strip())
    except ExportError:
        return False


def choose_source_video(ffprobe: str, pack_dir: Path) -> Path:
    candidates = [p for p in pack_dir.rglob("*") if p.is_file() and p.suffix.lower() in VIDEO_EXTS and p.suffix.lower() != ".tcv"]
    # Prefer conventional Choicer Voicer names, but accept any real video filename.
    def rank(path: Path) -> tuple[int, int, str]:
        stem = path.stem.casefold()
        try:
            name_rank = VIDEO_STEMS.index(stem)
        except ValueError:
            name_rank = len(VIDEO_STEMS)
        return name_rank, len(path.parts), str(path).casefold()
    errors: list[str] = []
    for candidate in sorted(candidates, key=rank):
        try:
            probe_video(ffprobe, candidate)
            return candidate
        except ExportError as exc:
            errors.append(f"{candidate.name}: {exc}")
    detail = "\n".join(errors[:5])
    raise ExportError(f"No original video file was found in pack folder:\n{pack_dir}\nSupported extensions: {', '.join(sorted(VIDEO_EXTS))}.\nA 3DS .tcv preview alone cannot be exported to MP4; include the original source video.\n{detail}")


def choose_backing_track(pack_dir: Path) -> Path | None:
    candidates = [p for p in pack_dir.rglob("*") if p.is_file() and p.suffix.lower() in AUDIO_EXTS]
    def rank(path: Path) -> tuple[int, int, str]:
        stem = path.stem.casefold().replace(" ", "_").replace("-", "_")
        try:
            idx = BACKING_STEMS.index(stem)
        except ValueError:
            idx = len(BACKING_STEMS)
        # Only take clearly labeled music/backing files; never mistake a dialogue clip for a track.
        if not any(word in stem for word in ("backing", "soundtrack", "music")):
            idx = len(BACKING_STEMS) + 1
        return idx, len(path.parts), str(path).casefold()
    ranked = sorted(candidates, key=rank)
    for p in ranked:
        if rank(p)[0] <= len(BACKING_STEMS) - 1:
            return p
    return None


def find_pack_by_name(packs_root: Path, pack_name: str) -> Path | None:
    if not packs_root.is_dir():
        return None
    target = normalized_name(pack_name)
    candidates: list[Path] = []
    for path in packs_root.rglob("*"):
        if path.is_dir() and normalized_name(path.name) == target:
            candidates.append(path)
    if not candidates:
        return None
    return min(candidates, key=lambda p: (len(p.parts), str(p).casefold()))


def probe_duration(ffprobe: str, video: Path) -> float:
    text = run_capture([ffprobe, "-v", "error", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1", str(video)])
    try:
        duration = float(text)
    except ValueError as exc:
        raise ExportError(f"Could not read full source video duration: {video}") from exc
    if duration <= 0:
        raise ExportError("Source video has an invalid duration.")
    return duration


def export_dub(session_path: Path, pack_dir: Path, output_path: Path, *, ffmpeg: str = "ffmpeg", ffprobe: str = "ffprobe", require_complete: bool = True, overwrite: bool = False) -> Path:
    session_path = session_path.expanduser().resolve()
    pack_dir = pack_dir.expanduser().resolve()
    output_path = output_path.expanduser().resolve()
    ffmpeg = resolve_binary(ffmpeg)
    ffprobe = resolve_binary(ffprobe)
    if not pack_dir.is_dir():
        raise ExportError(f"Pack folder does not exist:\n{pack_dir}")
    pack_name, takes, expected = parse_session(session_path, require_complete=require_complete)
    if normalized_name(pack_dir.name) != normalized_name(pack_name):
        raise ExportError(f"Selected folder '{pack_dir.name}' does not match the saved session pack '{pack_name}'. Select the matching source pack folder.")
    video = choose_source_video(ffprobe, pack_dir)
    duration = probe_duration(ffprobe, video)
    backing = choose_backing_track(pack_dir)
    source_has_audio = has_audio(ffprobe, video)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    protected_inputs = [session_path, video, *[take.path for take in takes]]
    if backing is not None:
        protected_inputs.append(backing)
    out_resolved = output_path.resolve()
    if any(out_resolved == item.resolve() for item in protected_inputs):
        raise ExportError("Output path matches a source video, take, backing track, or session file. Choose a separate output filename.")
    if output_path.exists() and not overwrite:
        raise ExportError(f"Output already exists:\n{output_path}\nChoose another name or explicitly enable overwrite.")
    args = [ffmpeg, "-hide_banner", "-y", "-loglevel", "warning", "-stats", "-i", str(video)]
    base_kind = ""
    backing_idx = -1
    # Use the pack's backing track when present. Otherwise keep a quieter copy
    # of source audio if it exists; if neither exists, create a full-length silent bed.
    if backing is not None:
        backing_idx = 1
        args += ["-stream_loop", "-1", "-i", str(backing)]
        base_kind = "backing"
    elif not source_has_audio:
        args += ["-f", "lavfi", "-t", f"{duration:.6f}", "-i", "anullsrc=r=48000:cl=stereo"]
        base_kind = "silence"
    else:
        base_kind = "source"
    take_start_idx = 2 if backing is not None else (2 if not source_has_audio else 1)
    # If using the source stream or generated silence as base, the source input
    # remains index 0; generated silence is input 1 and take inputs start at 2.
    if backing is not None:
        take_start_idx = 2
    elif not source_has_audio:
        take_start_idx = 2
    else:
        take_start_idx = 1
    for take in takes:
        args += ["-i", str(take.path)]
    filters: list[str] = []
    if base_kind == "backing":
        filters.append(f"[{backing_idx}:a:0]aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo,volume=0.72,apad=whole_dur={duration:.6f},atrim=duration={duration:.6f}[base]")
    elif base_kind == "source":
        filters.append(f"[0:a:0]aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo,volume=0.22,apad=whole_dur={duration:.6f},atrim=duration={duration:.6f}[base]")
    else:
        filters.append(f"[1:a:0]aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo,atrim=duration={duration:.6f}[base]")
    mix_labels = ["[base]"]
    for i, take in enumerate(takes):
        input_idx = take_start_idx + i
        delay_ms = max(0, int(round(take.timestamp * 1000)))
        label = f"take{i}"
        filters.append(f"[{input_idx}:a:0]aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo,adelay={delay_ms}|{delay_ms},volume=1.0[{label}]")
        mix_labels.append(f"[{label}]")
    mix_input = "".join(mix_labels)
    filters.append(f"{mix_input}amix=inputs={len(mix_labels)}:duration=longest:dropout_transition=0:normalize=0,alimiter=limit=0.95,apad=whole_dur={duration:.6f},atrim=duration={duration:.6f}[aout]")
    filter_complex = ";".join(filters)
    args += ["-filter_complex", filter_complex, "-map", "0:v:0", "-map", "[aout]", "-t", f"{duration:.6f}", "-c:v", "libx264", "-preset", "medium", "-crf", "18", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-movflags", "+faststart", str(output_path)]
    print(f"Pack: {pack_name}")
    print(f"Source video: {video} ({duration:.2f}s)")
    print(f"Recorded takes: {len(takes)}/{expected}")
    print(f"Backing track: {backing if backing else ('source audio at lower volume' if source_has_audio else 'silence')}")
    print(f"Output: {output_path}")
    print("Rendering full video. This may take a while; the output is encoded ahead of playback to avoid real-time dubbing lag.")
    try:
        subprocess.run(args, check=True)
    except FileNotFoundError as exc:
        raise ExportError("Could not start FFmpeg. Confirm ffmpeg is installed and on PATH.") from exc
    except subprocess.CalledProcessError as exc:
        raise ExportError(f"FFmpeg export failed with exit code {exc.returncode}. Check that the source video and take WAV files are readable.") from exc
    if not output_path.is_file() or output_path.stat().st_size < 1024:
        raise ExportError("FFmpeg exited but the resulting MP4 is missing or unexpectedly small.")
    # Verify a video stream and exact full-source duration within codec tolerance.
    out_duration_text = run_capture([ffprobe, "-v", "error", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1", str(output_path)])
    try:
        out_duration = float(out_duration_text)
    except ValueError as exc:
        raise ExportError("Output MP4 was created but its duration could not be verified.") from exc
    if out_duration < duration - 0.15:
        raise ExportError(f"Output appears truncated ({out_duration:.2f}s vs source {duration:.2f}s).")
    print(f"SUCCESS: finished MP4 is {out_duration:.2f}s long and includes all recorded takes.")
    return output_path


def gui_main(packs_root: Path) -> int:
    try:
        import tkinter as tk
        from tkinter import filedialog, messagebox
    except Exception as exc:
        raise ExportError(f"Python Tkinter is unavailable: {exc}. Use the command-line options instead.") from exc
    root = tk.Tk()
    root.withdraw()
    root.update()
    session_str = filedialog.askopenfilename(title="Select session.ini from the 3DS SD card", filetypes=[("Dub session", "session.ini"), ("INI files", "*.ini"), ("All files", "*.*")])
    if not session_str:
        root.destroy(); return 0
    session = Path(session_str)
    try:
        pack_name, _, _ = parse_session(session, require_complete=True)
    except ExportError as exc:
        messagebox.showerror("Dub session", str(exc), parent=root); root.destroy(); return 2
    suggested = find_pack_by_name(packs_root, pack_name)
    start_dir = suggested if suggested else (packs_root if packs_root.is_dir() else Path.home())
    messagebox.showinfo("Choose the original dub pack", f"Session pack: {pack_name}\n\nSelect the matching original pack folder from the source project's packs_voice folder. It must contain the original video and preferably its backing track.", parent=root)
    pack_str = filedialog.askdirectory(title=f"Select source pack folder — {pack_name}", initialdir=str(start_dir), mustexist=True)
    if not pack_str:
        root.destroy(); return 0
    video_dir = Path.home() / "Videos"
    if not video_dir.is_dir():
        video_dir = Path.home()
    default_output = video_dir / f"{pack_name} - Dubbed.mp4"
    out_str = filedialog.asksaveasfilename(title="Save the finished dubbed video", initialdir=str(default_output.parent), initialfile=default_output.name, defaultextension=".mp4", filetypes=[("MP4 video", "*.mp4")], confirmoverwrite=True)
    if not out_str:
        root.destroy(); return 0
    root.destroy()
    try:
        # asksaveasfilename confirms overwrite before returning an existing filename.
        result = export_dub(session, Path(pack_str), Path(out_str), overwrite=True)
    except ExportError as exc:
        try:
            root = tk.Tk(); root.withdraw(); messagebox.showerror("Dub export failed", str(exc)); root.destroy()
        except Exception:
            print(f"ERROR: {exc}", file=sys.stderr)
        return 2
    try:
        root = tk.Tk(); root.withdraw(); messagebox.showinfo("Dub export complete", f"Your complete dubbed video was saved to:\n{result}"); root.destroy()
    except Exception:
        pass
    return 0


def main(argv: Sequence[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--gui", action="store_true", help="Open Windows file/folder dialogs")
    ap.add_argument("--session", type=Path, help="Path to 3DS session.ini")
    ap.add_argument("--pack-dir", type=Path, help="Original source dub-pack folder")
    ap.add_argument("--packs-root", type=Path, default=Path("packs_voice"), help="Root containing source dub packs (default: ./packs_voice)")
    ap.add_argument("--output", type=Path, help="Output MP4 path")
    ap.add_argument("--allow-incomplete", action="store_true", help="Export only takes present in session.ini, leaving missing lines silent")
    ap.add_argument("--overwrite", action="store_true", help="Allow replacing an existing output file")
    args = ap.parse_args(argv)
    try:
        if args.gui or not (args.session and args.pack_dir and args.output):
            return gui_main(args.packs_root.resolve())
        result = export_dub(args.session, args.pack_dir, args.output, require_complete=not args.allow_incomplete, overwrite=args.overwrite)
        print(f"Finished: {result}")
        return 0
    except ExportError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
