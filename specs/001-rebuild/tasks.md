# Tasks — MediaFlow Rebuild

Status: backlog draft. Do not start a phase until its entry criteria are met.

## Phase 0 — Rescue (done)

- [x] Fix mobile progress/result contract.
- [x] Add real share/open/delete and missing-file state.
- [x] Remove the broken FFmpeg asset and dead services.
- [x] Add 8 tests; keep `flutter analyze` clean.
- [x] Repair Android CI and Kotlin version.
- [x] Document the rescue in `AGENTS.md`.

Exit criteria: Android debug APK builds; tests and analyze pass. Runtime on a
device is still pending.

## Phase 1 — Specs and decisions (this package)

- [x] Product spec.
- [x] Source matrix.
- [x] Architecture.
- [x] Studio Dark design system.
- [x] Task backlog.
- [x] Review and accept the decisions in `decisions.md`.
- [x] Confirm the v1 source list and that Drive is link-shared, with no OAuth.
- [x] Confirm `apps/mediaflow/` and `com.mediaflow.app` for the scaffold.
- [x] Avoid new dependencies for Phase 2; defer DB/HTTP/ZIP choices.

Exit criteria: decisions accepted; no implementation starts on an unresolved
dependency or storage policy. Phase 2 uses no new packages.

## Phase 2 — Scaffold and vertical slice

Entry: Phase 1 decisions accepted.

Status: implemented with the fake engine. Android debug APK builds; the Windows
runner is implemented but not built because this machine has no Visual Studio
C++ toolchain.

- [x] Create `apps/mediaflow/` Flutter app with Android + Windows targets.
- [x] Add theme, typography, tokens, and app shell (nav, responsive layout).
- [x] Add a temporary `AppStrings` en/ar map and RTL smoke test; migrate to ARB
  when the localization dependency is approved.
- [x] Define domain models: `MediaDescriptor`, `DownloadJob`,
  `DownloadEvent`, `MediaFlowError`, `BatchSummary`.
- [x] Define `SourceAdapter`, `SourceRegistry`, and a fake adapter.
- [x] Implement `Analyze → Queue → Library` with the fake adapter, persisted in
  memory.
- [x] Implement per-item failure cards, continue-on-error, and a batch summary.
- [x] Add batch-level Video/Audio selection.
- [x] Add widget tests for Analyze empty/loaded, Queue failed/summary, and the
  Arabic RTL toggle.
- [x] Keep `app.py` and `MediaFlow_Mobile/` untouched and runnable.

Acceptance:
- [ ] Windows app runs the vertical slice with a fake URL (blocked by the missing
  Visual Studio C++ toolchain).
- [x] Android app shell builds and renders the same screens.
- [x] A mixed batch with failures continues and shows name/link/reason at the end.
- [x] `flutter analyze` clean; tests pass; no live URLs.
- [x] Screens match the Studio Dark tokens.

Suggested commit: `feat(app): scaffold unified Flutter shell and fake vertical
slice`.

## Phase 3 — Windows engine and YouTube

Entry: Phase 2 done; dependency approval for the engine path.

- [ ] Bundle `yt-dlp.exe` and `ffmpeg.exe` paths for dev/release.
- [ ] Implement JSON-marker progress parsing and final-path capture.
- [ ] Implement probe, download, cancel, retry, and error classification.
- [ ] Wire YouTube single video and Shorts.
- [ ] Add format/quality selection and audio-only.
- [ ] Persist jobs and file paths to SQLite (or the approved store).
- [ ] Add engine-version display and a missing-engine error.
- [ ] Add tests with recorded yt-dlp JSON and a fake executable.

Acceptance:
- A public YouTube video downloads with the best merged quality.
- Cancellation leaves no partial file.
- A bad URL shows a classified error, not raw stderr.
- Automated tests never hit the network.

Suggested commit: `feat(engine): add Windows yt-dlp bridge and YouTube slice`.

## Phase 4 — Android engine and YouTube

Entry: Phase 3 patterns proven; `youtubedl-android` pinned and verified.

- [ ] Add the Kotlin engine bridge and Method/EventChannels.
- [ ] Normalize Android events into the shared schema.
- [ ] Implement foreground service and progress notification.
- [ ] Verify cancellation, final-path reporting, cookie support, and FFmpeg.
- [ ] Write completed files through MediaStore/SAF.
- [ ] Handle Android 13 notification permission and service lifecycle.
- [ ] Remove any rebuild dependency on Chaquopy or `MANAGE_EXTERNAL_STORAGE`.

Acceptance:
- A public YouTube video downloads on a device.
- Backgrounding the app does not stop the download.
- The notification shows progress and cancels correctly.
- Files are visible to other apps and playable.
- No broad storage permission is requested.

Suggested commit: `feat(android): add youtubedl-android engine and foreground
downloads`.

## Phase 5 — Multi-source v1

Entry: both engines stable for YouTube.

- [ ] URL resolver + canonicalization for all v1 patterns.
- [ ] TikTok single video, with cookie guidance.
- [ ] Facebook video/reel/live.
- [ ] Instagram reel/post, with rate-limit backoff.
- [ ] Kick clip/VOD.
- [ ] Twitch clip/VOD.
- [ ] SoundCloud track/playlist.
- [ ] Direct HTTP with Range/resume.
- [ ] HLS/DASH through the engine.
- [ ] Per-host concurrency and retry policy.
- [ ] Source badge and source catalog.
- [ ] Manual acceptance S-01…S-14, S-18, S-19.

Acceptance:
- Each source category passes on Windows and Android with public content.
- Cookie-required cases show the auth action, not a generic failure.
- A mixed batch completes with per-item results.
- No source-specific bypass logic is added.

Suggested commit: `feat(sources): add v1 multi-source adapters and tests`.

## Phase 6 — Collections and link-shared Google Drive

Entry: v1 single-item flows stable; link-shared Drive parser fixtures ready.

- [ ] Collection probe/expand/select for playlists and folders.
- [ ] Persist collection items and per-item status.
- [ ] Google Drive ID parsing and link-shared file download.
- [ ] Drive folder listing via public folder HTML; recursion, limits, cycle
  detection.
- [ ] Drive selection sheet with "Download all" and "Download as ZIP."
- [ ] Streaming/ZIP64 folder ZIP from successful files; skipped-file report.
- [ ] Google-native export or skip.
- [ ] Restriction errors: sign-in required, owner-disabled, policy, quota,
  layout changed.
- [ ] Size preview, free-space check, skip/continue.
- [ ] Manual acceptance S-14…S-17, S-20, S-21.

Acceptance:
- A link-shared Drive folder with subfolders downloads selected files.
- A folder with no download button still lists and downloads.
- An owner-disabled file is reported as terminal; no bypass.
- A ZIP contains successful files and reports skipped files.
- A 100-item folder does not freeze the UI.
- No Google auth package, token, or sign-in control is present.

Suggested commit: `feat(drive): add link-shared Google Drive files, folders, and
ZIP`.

## Phase 7 — Queue, mobile intake, and resilience

Entry: core downloads and collections work.

- [ ] Persistent queue with restart recovery.
- [ ] Global pause-queue and per-item cancel/retry.
- [ ] Android share target (`ACTION_SEND` text).
- [ ] Windows clipboard/drag-drop intake.
- [ ] Duplicate detection and "already downloaded" hint.
- [ ] Live recording flow and stop/finalize.
- [ ] Disk-space and network-change handling.
- [ ] Retry/backoff and `Retry-After`.
- [ ] Persist per-item errors and batch summaries.
- [ ] Failure card actions: retry, open browser, copy link, skip, remove.
- [ ] Batch summary actions: retry failed, copy failed links, view report.
- [ ] Android completion notification for a mixed batch.

Acceptance:
- Killing the app during a download and reopening offers resume/retry.
- Sharing a link from TikTok/YouTube to MediaFlow opens Analyze.
- A 20-item batch survives restart and completes.
- Live stop finalizes and indexes the file.
- A mixed batch summary survives restart and retries only failed items.

Suggested commit: `feat(queue): persist jobs and add mobile share intake`.

## Phase 8 — Library, settings, and design polish

Entry: end-to-end flows work.

- [ ] Library search/filter/grid/list and missing-file states.
- [ ] Open/share/reveal/delete with correct confirmations.
- [ ] Settings sections and secure cookie management; no Google sign-in.
- [ ] Filename template and collision handling.
- [ ] Studio Dark/Light/OLED themes.
- [ ] Arabic RTL pass and golden tests.
- [ ] Accessibility pass (labels, focus, contrast, text scaling).
- [ ] Redacted diagnostics export.
- [ ] Empty/loading/error states across all screens.

Acceptance:
- All golden tests pass.
- No hard-coded user-facing strings.
- Arabic layout has no clipped primary actions.
- Diagnostics contain no cookies/tokens.
- Desktop and mobile feel like the same product.

Suggested commit: `feat(ui): complete library, settings, and Studio Dark polish`.

## Phase 9 — Release and hardening

Entry: v1 acceptance checklist passes.

- [ ] Windows installer with bundled engine binaries.
- [ ] Android release build with ABI splits and signing.
- [ ] CI builds Windows and Android, runs analyze/tests.
- [ ] Performance pass: startup, 10k library rows, 100-item folder.
- [ ] Security review: path traversal, secret logging, Drive capability-URL
  redaction, no Google credentials.
- [ ] Legal/privacy notice and first-run copy.
- [ ] Update README/AGENTS with the new app and release steps.
- [ ] Device/emulator smoke test on Android; Windows 10/11 smoke test.

Acceptance:
- Tagged release produces installable artifacts.
- No `MANAGE_EXTERNAL_STORAGE`; no Chaquopy in the rebuild.
- No live URLs in CI.
- Known limitations are documented.

Suggested commit: `chore(release): package Windows and Android v1`.

## Dependency gates

Do not add these until approved:

- DB: `drift` + `sqlite3_flutter_libs` (preferred) or `sqflite` + FFI.
- HTTP: `dio` (cancel/progress) or Dart `HttpClient`.
- ZIP: `archive` or a native per-platform streaming implementation.
- Windows UX: `desktop_drop`, `window_manager`.
- Utilities: `url_launcher`.
- Android engine: `youtubedl-android` (locked decision).

Do not add: `google_sign_in`, `googleapis`, `googleapis_auth`,
`flutter_secure_storage` for Google tokens, or any OAuth client.

Already present and reusable: `path_provider`, `file_picker`, `share_plus`,
`open_filex`, `shared_preferences`, `provider`.

## Definition of done (every task)

- Acceptance criteria met.
- `flutter analyze` clean.
- `flutter test` passes; new pure logic has tests.
- No live URLs or real downloads in tests.
- No secrets in logs, fixtures, or commits.
- Arabic strings added for new UI.
- Failure cases have a name, original link, localized reason, and summary.
- Docs/AGENTS updated if a trap or decision changed.
- Build verified on the affected platform, or the reason stated.

## Suggested first sprint

1. Confirm app path/ID and keep Phase 2 dependency-free.
2. Scaffold `apps/mediaflow`.
3. Build the fake-engine vertical slice with Studio Dark, Arabic RTL, failure
   cards, and a batch summary.
4. Add the Windows yt-dlp bridge for YouTube.
5. Add link-shared Drive listing and ZIP.
6. Demo Analyze → Download → Library on Windows.
