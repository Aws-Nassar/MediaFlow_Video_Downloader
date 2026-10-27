# Decisions

Status values: **Accepted**, **Proposed**, **Open**.

## ADR-001 — One Flutter app for Windows and Android

**Status:** Accepted

**Context:** The repo has a PyQt5 desktop app and a Flutter Android app that is a
regression from the pre-Flutter Java app. Maintaining three stacks is not
sustainable.

**Decision:** Rebuild as one Flutter app targeting Windows and Android. Keep
`app.py` as the working desktop reference and `MediaFlow_Mobile/` as the rescued
Android fallback until parity.

**Consequences:** Shared UI, models, and tests; platform-specific engine and
storage code behind interfaces. No iOS in v1.

## ADR-002 — Native engines per platform

**Status:** Accepted

**Context:** yt-dlp is the broadest extractor engine, but Python packaging on
Android caused the Chaquopy problems in the rescue.

**Decision:**
- Windows: bundled `yt-dlp.exe` + `ffmpeg.exe` subprocess.
- Android: `youtubedl-android` + its FFmpeg build, wrapped in Kotlin.
- No new Chaquopy/Python runtime in the rebuild.

**Consequences:** Two engine integrations to test, but no CPython packaging on
Android. Engine versions are pinned per platform; site changes may require app
updates on Android.

## ADR-003 — Local-first, no backend

**Status:** Accepted

**Context:** anything.rip is a hosted proxy. MediaFlow should be private and
unlimited by someone else's bandwidth.

**Decision:** All downloads run on the user's device. No server, no account, no
telemetry by default.

**Consequences:** The app is limited by the device's network/IP and by site
anti-bot behavior. No debrid/paywall capabilities. Diagnostics are opt-in and
redacted.

## ADR-004 — Authorized content only; no bypass

**Status:** Accepted

**Context:** Some requested Drive folders and social links may be private,
restricted, age-gated, or paywalled.

**Decision:**
- Support link-shared/public content and content the user is authorized to
  access.
- Use cookies only for social sources and only for content the user can already
  view. Do not add Google OAuth to the rebuild.
- Refuse DRM, paywall, private-account, owner-disabled download, and policy
  bypass.
- Never add "alternate endpoint" tricks to defeat a restriction.

**Consequences:** Some links will remain undownloadable. The app explains why and
offers "open in browser" or "request access." This is a product boundary, not a
bug.

## ADR-005 — Studio Dark design system

**Status:** Accepted

**Context:** The desktop app has a functional but inconsistent dark UI; the
mobile app uses default Material.

**Decision:** Use the Studio Dark tokens and layouts in `design-system.md` on both
platforms, with Light and OLED variants.

**Consequences:** Shared theme and golden tests; no ad-hoc colors or one-off
components.

## ADR-006 — State management

**Status:** Accepted for scaffold

**Decision:** Use Flutter's built-in `ChangeNotifier` and `ListenableBuilder`
for the Phase 2 vertical slice. No state-management package is added yet.
Revisit if the queue/collection state becomes hard to test or compose.

**Consequences:** Zero new dependencies for the scaffold; the app state stays
plain Dart and is easy to unit-test. A package such as `provider` or `riverpod`
can be adopted later without changing the domain model.

## ADR-007 — Persistence

**Status:** Accepted (2026-10-27)

**Options:**
- `drift` + `drift_flutter`: typed schema, migrations, generated queries, good
  tests, and one SQLite path for Windows and Android.
- `sqflite` + `sqflite_common_ffi`: fewer dev dependencies, but two platform
  paths and hand-written SQL.
- JSON files: not acceptable for queue state and 10k history rows.

**Decision:** Use `drift 2.35` with `drift_flutter` and `path_provider`.
The database file lives in application-support storage, not the user output
folder. `drift_dev` + `build_runner` generate `lib/storage/app_database.g.dart`;
the generated file is committed so a normal build does not need codegen.

Schema v1 stores `jobs` and `batch_summaries`. Folder/ZIP entries, skipped items,
and summary failures are JSON columns. Queue writes happen on creation, status
transitions, and terminal results; progress writes are throttled to about once a
second. On startup, interrupted `downloading`/`processing` jobs return to
`queued` and auto-start. Incomplete `probing` rows are discarded. Missing batch
summaries are rebuilt from terminal jobs.

**Consequences:** New runtime dependencies are `drift`, `drift_flutter`, and
`path_provider`; dev dependencies are `drift_dev` and `build_runner`. Run
`dart run build_runner build` after changing a Drift table. `sqlite3` ships
native assets, including `libsqlite3.so` in the Android APK. The schema is a
subset of the target schema in `architecture.md`; job files, collection rows,
settings, and source auth remain future work.

## ADR-008 — Google Drive: link-shared access only, no OAuth

**Status:** Accepted

**Context:** The user does not want to connect a Google account. The supplied
lecture folders are link-shared: anonymous listing was verified (18 and 248
entries), and the missing download button is a UI limitation, not a permission
gate.

**Decision:**
- Support link-shared files and folders ("anyone with the link") without OAuth,
  a Google account, or an API key.
- Read the public folder listing, recurse with guards, and download files via
  public file endpoints. Handle large-file confirmation pages.
- Support individual-file and ZIP folder downloads.
- Truly restricted files (sign-in required), owner-disabled downloads, and
  Workspace policy blocks are terminal per-file errors. Skip and report them;
  never bypass them.
- Do not add Google auth packages or store Google tokens.

**Consequences:** Private Drive access is not supported. Google's public folder
HTML can change, so the parser needs recorded-HTML tests and a clear "Drive
layout changed" error. An optional app-owned API key can be a later reliability
fallback, but it is not part of v1.

## ADR-009 — Android storage

**Status:** Accepted for scaffold; app-specific default implemented, MediaStore/SAF
pending

**Context:** The rescue app declares `MANAGE_EXTERNAL_STORAGE`; the rebuild must
not.

**Decision:** Default to MediaStore `Downloads` on API 29+; custom folders via
SAF. For API 24–28, use app-specific external storage + FileProvider, or a
legacy write permission if a public folder is mandatory. Scaffold `minSdk` is
24; confirm before release. Never add `MANAGE_EXTERNAL_STORAGE`.

**Implementation note (2026-10-27):** Until MediaStore/SAF lands, Android uses
`getExternalFilesDir(DIRECTORY_DOWNLOADS)/MediaFlow` with `filesDir` fallback,
resolved over `MethodChannel('com.mediaflow.app/platform')`. The app requests no
broad storage permission. The same channel exposes `StatFs` free bytes for the
Drive selection sheet; Windows uses PowerShell and other desktops use `df -Pk`.
The Android path and channel are compiled into the debug APK but not yet run on
a device/emulator.

## ADR-010 — App location and identity

**Status:** Accepted for scaffold

**Decision:**
- Code: `apps/mediaflow/`.
- Application ID: `com.mediaflow.app` (Android); use the same identity for a
  future Windows package.
- Display name: `MediaFlow`.

**Consequences:** The new app can be installed alongside the rescue app during
testing. Confirm the final ID before signing a release.

## ADR-011 — Localization

**Status:** Accepted

**Context:** The rescue app uses a manual string map; it works but is easy to
drift.

**Decision:** Move to Flutter `gen-l10n` with ARB files for English and Arabic.
Use Western digits in Arabic UI. The Phase 2 scaffold uses a temporary
`AppStrings` map (no dependency); migrate to ARB when the localization
dependency is approved.

**Consequences:** One more build step; better placeholder safety and RTL
coverage. Keep the existing Arabic copy where it is good.

## ADR-012 — Multi-source scope

**Status:** Proposed

**v1.0 sources:** YouTube, TikTok, Facebook, Instagram, Kick, Twitch,
SoundCloud, Google Drive (link-shared only per ADR-008), direct HTTP, HLS/DASH,
and the generic yt-dlp host set.

**Later:** Mega, Gofile, image galleries, browser bookmarklet, scheduled jobs.

**Not planned:** torrents, DRM services, hosted proxy, iOS.

## ADR-013 — No sample URLs in the repository

**Status:** Accepted

**Context:** The links supplied for acceptance include real people's public
content.

**Decision:** Do not commit the raw URLs or downloaded media. Use placeholders in
docs and recorded JSON/fake engines in tests. Keep the real links in the private
acceptance notes.

**Consequences:** Manual acceptance is run locally; CI never depends on a live
site.

## ADR-014 — Legal and privacy notice

**Status:** Accepted

**Decision:** Show a short first-run/About notice: download only content you have
rights to; respect site terms and copyright; MediaFlow does not host or proxy
content; no DRM/paywall bypass.

**Consequences:** The app is a general-purpose tool, not a piracy service. Support
can point to this boundary when a source is restricted.

## ADR-015 — Failure isolation and batch summary

**Status:** Accepted

**Decision:**
- Every item has an independent status. One failure never stops the rest of the
  batch.
- Transient errors get up to three automatic retries with backoff; auth,
  permission, owner-disabled download, DRM, paywall, and unsupported errors are
  not retried.
- A failure card shows the item name, the original link, a localized reason, and
  actions: retry, open in browser, skip, copy link, details.
- When a batch finishes, show a summary with downloaded/failed/skipped counts,
  total size, duration, and a list of failed items. Actions: retry failed, copy
  failed links, open folder, view report.
- Persist the batch summary in History so it survives a restart.
- ZIP jobs include only successfully downloaded files; the summary lists every
  skipped file and reason.

**Consequences:** The queue needs a batch model and per-item error persistence.
The UI needs a dedicated failure card and summary sheet.

## ADR-016 — ZIP folder downloads

**Status:** Accepted

**Decision:**
- Support both "Download files individually" and "Download folder as ZIP."
- A folder link opens a selection screen with both actions; ZIP is not forced.
- Recursion is on by default with depth and file-count guards.
- Show file count and total size when available; warn about free space.
- If some files fail, build the ZIP from successful files and report the
  failures instead of failing the whole folder.
- Do not add a ZIP dependency until the implementation choice is approved;
  prefer a streaming implementation that supports large files.

**Consequences:** Large folders need progress, cancellation, and a free-space
check. Individual downloads remain the more resumable option.

**Implementation note (2026-10-27):** The rebuild uses a dependency-free
Store-method writer in `apps/mediaflow/lib/zip/`; it emits ZIP64 records when
required, stages successful files in a hidden folder, writes through `.part`,
and cleans staging on success, failure, and cancellation. The selection sheet
shows known totals and free space and asks for confirmation when the selected
payload (or roughly twice that for ZIP staging) exceeds free space. The current
public folder parser does not obtain per-file sizes, so real folder totals and
numeric warnings remain unavailable. Live Drive acceptance remains pending.

## ADR-017 — Bundled engine discovery and demo routing

**Status:** Accepted

**Decision:**
- Discover `yt-dlp`/`ffmpeg` without relying on the user's PATH: check
  `MEDIAFLOW_YTDLP`/`MEDIAFLOW_FFMPEG`, then the working directory, the app
  directory, and a `tools` folder beside either.
- If the real engine is present, route normal http(s) URLs to it. Keep only the
  documented `example.com` and `demo-mixed` sample links on the offline fake
  adapter.
- If the real engine is absent, unsupported URLs fail with `engineMissing` or
  `unsupportedUrl`; do not simulate a successful download.
- Keep the engine binaries out of git and verify them locally.

**Consequences:** The app can run the demo without binaries and use the real
engine when packaged. A release package must place both executables where the
resolver can find them; missing binaries are a visible failure, not a silent
fake download.

