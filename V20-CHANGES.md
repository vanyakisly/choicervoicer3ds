# v20 — Correct ready-pack selection and embed-time validation

- Fixed duplicate pack selection across user, legacy SD and embedded RomFS roots. A raw legacy OGV pack can no longer shadow a converted embedded TCV pack with the same display name. Equally capable custom/user packs retain priority.
- Added a regression test with the exact failure setup: the legacy path holds `dub_video.ogv`; the embedded copy holds `dub_video.tcv`; the browser must select the embedded ready copy.
- GitHub Actions now checks that the supplied `packs_voice/verity song/dub_video.ogv` was converted into an embedded `dub_video.tcv` with a valid TCV1 header, and validates headers for all embedded dub videos.
- Custom raw OGV packs must be committed under repository-root `packs_voice/` and rebuilt to be embedded/preconverted. Old SD folders remain read-only compatibility fallback; the app does not write there.
