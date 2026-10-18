# v23 — Startup and load-time optimization

- Preload only the fonts, logo/banner and first-screen host/developer art; load other sprites on first use. Per-sprite attempt state avoids repeatedly opening missing assets.
- Cache pack category directory lists for the lifetime of the app.
- Cache Dub Mode discovery after its first scan.
- Generate `packs_voice/.tcv_pack_index.tsv` during the asset-preparation stage. Embedded dub pack discovery parses this index instead of recursively scanning immutable RomFS trees. Legacy/user SD pack locations still use the bounded recursive scanner as optional compatibility roots.
- Validate catalog entries against the converted TCV videos during GitHub Actions. An empty catalog is allowed for a build that intentionally contains no bundled dub packs.
- Keep all bundled data embedded in the `.3dsx`, so the user does not need to change `SD:/3ds/The Choicer Voicer/`. Writable saves and recordings continue under `SD:/3ds/TheChoicerVoicer3DS_User/`.

Host-side regression tests cover catalog generation/reading, pack browsing, lazy sprite loading and cache presence. ARM cross-compilation and physical Old 3DS load-time/performance measurement are still required for hardware verification.
