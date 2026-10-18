#!/usr/bin/env python3
"""Regression checks for quicker startup, pack browsing, and embedded catalog."""
from __future__ import annotations
import tempfile
from pathlib import Path

from prepare_3ds_assets import write_embedded_dub_catalog

ROOT = Path(__file__).resolve().parent.parent

def main() -> None:
    with tempfile.TemporaryDirectory(prefix="tcv-load-optimization-") as tmp:
        voice_root = Path(tmp) / "packs_voice"
        one = voice_root / "First Pack"
        one.mkdir(parents=True)
        (one / "dub_video.tcv").write_bytes(b"tcv fixture")
        (one / "Line.3ds.wav").write_bytes(b"wav fixture")
        (one / "Line.ini").write_text(
            '[data]\ndub_timestamps=[0.5, "00:02.500"]\n', encoding="utf-8")
        (one / "_backing_track.3ds.wav").write_bytes(b"backing fixture")
        two = voice_root / "Nested" / "Second Pack"
        two.mkdir(parents=True)
        (two / "dub_video.tcv").write_bytes(b"tcv fixture")
        (two / "Line_3-25.3ds.wav").write_bytes(b"wav fixture")
        count = write_embedded_dub_catalog(voice_root)
        assert count == 2
        catalog = (voice_root / ".tcv_pack_index.tsv").read_text(encoding="utf-8").splitlines()
        assert catalog == ["First Pack\t2", "Nested/Second Pack\t1"], catalog

    source = (ROOT / "3ds_port/source/main.c").read_text(encoding="utf-8")
    assets = (ROOT / "tools/prepare_3ds_assets.py").read_text(encoding="utf-8")
    assert "static ItemList pack_category_cache[7]" in source
    assert "if (pack_category_cache_valid[cache_index])" in source
    assert "static bool dub_pack_cache_valid = false" in source
    assert "if (!dub_pack_cache_valid)" in source
    assert "scan_embedded_dub_pack_catalog" in source
    assert "write_embedded_dub_catalog(out / \"packs_voice\")" in assets
    assert "sprite_load_attempted[id]" in source
    load_ui = source[source.index("static void load_ui_assets(void) {"):source.index("static void free_ui_assets(void)")]
    assert load_ui.count("load_sprite_id(") == 5, load_ui
    assert "if (!sprite_load_attempted[id]) (void)load_sprite_id(id);" in source
    print("PASS: embedded pack catalog, one-time pack caches, and lazy secondary UI asset loading.")

if __name__ == "__main__":
    main()
