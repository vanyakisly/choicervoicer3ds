#!/usr/bin/env python3
"""Build and run the native session-manifest writer on a temporary host SD tree."""
from __future__ import annotations
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def main() -> None:
    cc = shutil.which("cc") or shutil.which("gcc")
    if not cc:
        raise SystemExit("A C compiler is required for the Dub manifest regression test")
    with tempfile.TemporaryDirectory(prefix="tcv-dub-manifest-") as temp:
        base = Path(temp)
        (base / "sdmc:").mkdir()
        exe = base / "test_dub_manifest"
        cmd = [cc, "-std=gnu11", "-O0", "-ffunction-sections", "-fdata-sections",
               "-Wno-implicit-function-declaration", "-Wno-int-conversion",
               "-Wno-pointer-to-int-cast", "-Wno-incompatible-pointer-types",
               "-Wno-unused-parameter", "-Wno-unused-function",
               "-I", str(ROOT / "tools" / "3ds_test_stub"),
               str(ROOT / "tools" / "test_dub_manifest.c"),
               "-Wl,--gc-sections", "-lz", "-lm", "-o", str(exe)]
        subprocess.run(cmd, check=True)
        subprocess.run([str(exe)], cwd=base, check=True)
    print("PASS: native Save Dub manifest writer saves unique timestamped takes in a temporary SD tree.")


if __name__ == "__main__":
    main()
