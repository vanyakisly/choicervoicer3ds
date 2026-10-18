# v22 — Pack-agnostic dub support

- Removed all workflow requirements for the `verity song` title/path and its fixed 46-line count.
- GitHub Actions now validates every generated `dub_video.tcv` found under the embedded `packs_voice/` tree; zero bundled dub videos is a warning rather than a build failure.
- The container preprocessor scans all eligible pack directories under repository-root `packs_voice/`, merges every top-level pack/collection directory into the runtime tree, and fails with path-specific diagnostics when a recognized timed dub pack cannot be converted.
- Reworked the browser regression fixture around arbitrary names (`Alternate Voice Dub`, `Riley`, `Alex`) and arbitrary line counts.
- Existing synthetic conversion tests cover standard OGV, alternate MKV/FLAC/TIFF/JSON and nested video/metadata; no conversion logic special-cases a pack title.
- All source custom packs placed under repository-root `packs_voice/` before a build are prepared and embedded. Runtime cannot decode arbitrary unconverted videos directly; adding/changing packs requires rerunning the GitHub build.
