#!/usr/bin/env python3
"""Compile a host test harness to exercise the real C pack metadata scanner."""
from __future__ import annotations
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def main() -> None:
    cc = shutil.which('cc') or shutil.which('gcc')
    if not cc:
        raise SystemExit('A C compiler is required for the native pack-loader regression test')
    with tempfile.TemporaryDirectory(prefix='tcv-loader-test-') as temp:
        temp_path = Path(temp)
        executable = temp_path / 'test_pack_loader'
        cmd = [cc, '-std=gnu11', '-O0', '-ffunction-sections', '-fdata-sections',
               '-Wno-implicit-function-declaration', '-Wno-int-conversion',
               '-Wno-pointer-to-int-cast', '-Wno-incompatible-pointer-types',
               '-Wno-unused-parameter', '-Wno-unused-function',
               '-I', str(ROOT / 'tools' / '3ds_test_stub'),
               str(ROOT / 'tools' / 'test_pack_loader.c'), '-Wl,--gc-sections', '-lz', '-lm', '-o', str(executable)]
        subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        pack = temp_path / 'Sample Dub Pack'
        pack.mkdir()
        # Existing high-quality WAV is retained, but the normalized companion must be selected.
        (pack / '01_A.wav').write_bytes(b'original')
        (pack / '01_A.3ds.wav').write_bytes(b'normalized')
        (pack / '02_B.3ds.wav').write_bytes(b'normalized')
        (pack / '03_C.3ds.wav').write_bytes(b'normalized')
        (pack / '01_A.ini').write_text('[data]\ncaption="First line"\ndub_timestamps=[1.25]\ndub_characters=["Narrator"]\nimage="01_A.jpg"\n', encoding='utf-8')
        (pack / '02_B.txt').write_text('[data]\ncaption="Second line"\ndub_timestamps=[00:02.500]\ndub_characters=["Second"]\n', encoding='utf-8')
        (pack / '03_C.ini').write_text('[data]\ncaption="Dub-only line"\ndub_timestamps=[3.5]\ndub_only="true"\n', encoding='utf-8')
        subprocess.run([str(executable), str(pack)], check=True)
    print('PASS: native C loader reads timestamps, captions, character tags, .3ds.wav companions, and dub_only.')


if __name__ == '__main__':
    main()
