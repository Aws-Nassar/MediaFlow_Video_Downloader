# Architecture — MediaFlow Rebuild

## 1. System context

```mermaid
flowchart LR
  User[User] --> UI[Flutter UI]
  UI --> App[Application layer]
  App --> Registry[Source registry]
  Registry --> YT[yt-dlp adapter]
  Registry --> Drive[Google Drive adapter]
  Registry --> HTTP[Direct HTTP adapter]
  YT --> Win[Windows: yt-dlp.exe + ffmpeg.exe]
  YT --> And[Android: youtubedl-android + FFmpeg]
  Drive --> Google[Link-shared Drive endpoints]
  HTTP --> Net[(Remote host)]
  App --> DB[(SQLite queue + library)]
  App --> Local[(App support: cookies, logs)]
  App --> Files[(User output folder)]
```

One Flutter codebase. Native work is limited to the Android engine bridge,
foreground service, and storage integration. Windows runs the engine as a
subprocess from Dart. Google Drive uses link-shared public endpoints only; there
is no Google sign-in, OAuth, or API key in the rebuild.

## 2. Layers

```
lib/
  app/                 app shell, routing, theme, l10n
  features/
    analyze/           URL intake, probe, format selection
    queue/             active/waiting jobs
    library/           history and files
    settings/          preferences, cookies, diagnostics
    sources/           source catalog / supported hosts
  domain/
    models/            MediaDescriptor, DownloadJob, DownloadEvent, errors
    sources/           SourceAdapter, SourceRegistry, capabilities
    queue/             scheduler, retry policy, state machine
    storage/           repositories (interfaces)
  infrastructure/
    engine/            YtDlpBridge, WindowsYtDlpEngine, AndroidYtDlpEngine
    drive/             link-shared listing, file download, ZIP
    http/              DirectHttpEngine
    db/                SQLite implementation
    auth/              cookie import (no Google OAuth)
    platform/          share, notifications, file open, storage
```

Rules:
- The domain layer has no Flutter or platform imports.
- Adapters depend on domain interfaces, not on UI.
- The UI never shells out and never touches cookie/token contents.
- All percentages crossing a boundary are `0..1`.

## 3. Source adapter contract

```dart
enum MediaKind { video, audio, image, file, collection }

class SourceCapabilities {
  final bool singleItem;
  final bool collection;
  final bool live;
  final bool audioOnly;
  final bool requiresAuth;
  final bool supportsCookies;
  final bool supportsSubtitles;
  final bool supportsThumbnail;
  final bool supportsResume;
}

class MediaRequest {
  final Uri uri;
  final AuthContext auth;
  final DownloadOptions options;
}

class MediaDescriptor {
  final String sourceId;
  final Uri canonicalUri;
  final String title;
  final String? author;
  final String? thumbnailUrl;
  final Duration? duration;
  final MediaKind kind;
  final List<MediaItem> items; // one item for a single download
  final SourceCapabilities capabilities;
}

sealed class DownloadEvent {
  const DownloadEvent();
}

class DownloadProgress extends DownloadEvent {
  final double fraction; // 0..1
  final int? downloadedBytes;
  final int? totalBytes;
  final double? bytesPerSecond;
  final Duration? eta;
  final String stage; // downloading, merging, converting, finalizing
}

class DownloadLog extends DownloadEvent { final String message; }
class DownloadCompleted extends DownloadEvent { final List<String> filePaths; }
class DownloadFailed extends DownloadEvent { final MediaFlowError error; }
class DownloadCancelled extends DownloadEvent {}

abstract interface class SourceAdapter {
  String get id;
  SourceCapabilities get capabilities;
  bool canHandle(Uri uri);
  Future<MediaDescriptor> probe(MediaRequest request);
  Stream<DownloadEvent> download(DownloadJob job);
  Future<void> cancel(String jobId);
}
```

`SourceRegistry` resolves by explicit priority:

1. Google Drive adapter (`drive.google.com`, `docs.google.com`).
2. Specialized adapters (future Mega/Gofile).
3. yt-dlp adapter for known extractor hosts and HLS/DASH.
4. Direct HTTP adapter for any other `http(s)` URL.

`canHandle` must be pattern-based, not a network call. The probe performs the
network call and returns a classified error if it fails.

## 4. Engine bridge

Both platforms expose the same event schema to Dart. The difference is how the
engine is launched.

### Shared event schema

```json
{"type":"progress","jobId":"...","fraction":0.42,"downloadedBytes":1048576,"totalBytes":2490368,"bytesPerSecond":512000,"etaSeconds":3,"stage":"downloading"}
{"type":"log","jobId":"...","message":"..."}
{"type":"completed","jobId":"...","filePaths":["..."]}
{"type":"failed","jobId":"...","code":"loginRequired","message":"..."}
{"type":"cancelled","jobId":"..."}
```

The current Android bridge forwards marker lines and normalizes them into this
schema in Dart; the JSON event schema remains the target boundary, not the
wire format yet.

### Windows

`WindowsYtDlpEngine` starts `yt-dlp.exe` with:
- `--ignore-config`, `--newline`, `--no-colors`
- a JSON progress template with a unique marker (verify the exact
  `--progress-template` syntax for the pinned yt-dlp version)
- `--print after_move:<marker>%(filepath)s` for final paths
- `--dump-single-json` for probe, or `--flat-playlist --dump-single-json` for a
  collection preview
- `--cookies <path>` when the user supplied cookies
- `--ffmpeg-location <path>` to the bundled FFmpeg
- output template and format selector from the job

Stdout/stderr are read as a stream. Lines with the marker become progress/file
events; everything else goes to the redacted log. Exit code plus stderr feed the
error classifier. Cancellation terminates the process tree and removes partial
files.

### Android

`AndroidYtDlpEngine` implements the shared `DownloadEngine` contract. The
current bridge uses one `MethodChannel` (`com.mediaflow.app/engine`) in both
directions:

- Dart calls `probe`, `download`, and `cancel`. Native sends only marked stdout
  lines back as `line` events.
- Dart builds the same arguments as Windows with `YtDlpCommandBuilder` and
  removes the trailing URL. Kotlin creates `YoutubeDLRequest(url)`, appends the
  shared arguments, and lets the library add `--no-cache-dir`, `--js-runtimes`,
  and `--ffmpeg-location`.
- Probe returns raw `--dump-single-json` output; Dart reuses the desktop
  `parseYtDlpProbe`. Download lines are parsed by the existing `MF_PROGRESS` and
  `MF_FILE` parsers. The native terminal map carries status, final path, size,
  details, exit code, and an optional initialization error code.
- `YoutubeDL` initializes lazily on the first probe; FFmpeg initializes lazily on
  the first download. `--no-simulate` is required because `--print` implies
  simulation.
- `android:extractNativeLibs="true"` and legacy JNI packaging are required
  because the library extracts the zipped Python and FFmpeg payloads.
- Final paths come from the `after_move:MF_FILE` marker. The library's
  `processId` cancellation kill is wired to the app job id; parent-process
  cancellation is covered, but child-process cleanup is not verified.
- A foreground service and progress notification are not implemented yet.
  Backgrounding can stop or kill a download. Cookies, version display, and
  MediaStore/SAF are also pending.

The bridge is covered with a fake gateway, a mocked method channel, and recorded
JSON. Device runtime and live-source acceptance are still required. Do not add a
second Python runtime.

### Direct HTTP

`DirectHttpEngine` handles plain files and uses:
- `HEAD`/`GET` with `Range` for resume.
- `Content-Length`, `Content-Disposition`, `Content-Type`.
- A cancel token and a progress stream.
- Filename sanitization and collision handling.

HLS/DASH goes to yt-dlp, not the direct engine.

## 5. Google Drive adapter (link-shared only)

### File
- Parse file/folder IDs from `/file/d/<id>`, `/open?id=`, `/uc?id=`, and
  `/drive/folders/<id>`.
- Download via the public `uc?export=download` flow. For large files, parse the
  confirmation page/form token and retry with it.
- Use `Content-Disposition` for the filename and `Content-Length` for size.
- No API key, OAuth, or Google account.

### Folder
- Read the link-shared folder listing from the public `embeddedfolderview` view
  (or equivalent public HTML). A missing download button is not a block.
- Parse entries into `DriveEntry(id, name, isFolder, mimeType, size?)`.
- Recurse into subfolders with a depth limit (10), item limit (10,000), and cycle
  detection.
- Probe returns a collection descriptor with item count and, when available,
  total size.
- The selection screen offers "Download all" and "Download as ZIP."
- ZIP is built from successful files only; skipped files are reported in the
  batch summary.

### ZIP
- Prefer a streaming ZIP implementation that supports large files and ZIP64.
- Show file count and total size when known, display free space, and confirm a
  low-space start (ZIP peak is about twice the payload).
- Progress reports both the current file and the overall archive.
- Cancellation removes the partial ZIP.
- A folder with failures still produces a ZIP of the successful files, plus a
  summary (and optionally a `failures.txt` manifest).

### Errors
- `permissionDenied` — the link requires sign-in. Terminal; offer browser.
- `downloadRestricted` — owner disabled download/copy. Terminal.
- `policyBlocked` — Workspace/admin policy. Terminal.
- `quotaExceeded` — retry later; no endpoint tricks.
- `notFound` — removed or wrong ID.
- `driveLayoutChanged` — public folder HTML no longer parses. Clear error; no
  silent partial result.

The adapter must never attempt alternate endpoints to defeat a restriction. It
may retry transient 429/5xx with backoff.

### Google-native files
Docs/Sheets/Slides are exported (PDF/DOCX/XLSX/PPTX) or skipped with a clear
reason. Shortcuts are resolved only when permitted; otherwise skipped.

## 6. Queue and scheduler

States:

```
queued -> probing -> downloading -> processing -> completed
   |         |            |             |
   +---------+------------+-------------+-> failed / skipped / cancelled
```

- Global concurrency: default 2 (Windows), 1 (Android).
- Per-host concurrency: default 1 for TikTok/Instagram/Facebook; 2 for
  YouTube/Drive; configurable.
- Retry: transient network/5xx/429 only, 3 attempts with exponential backoff and
  `Retry-After` support. Never retry auth, permission, owner-disabled, DRM,
  paywall, or unsupported errors.
- Queue state is persisted before each transition.
- On startup, jobs in `downloading`/`processing` return to `queued` and
  auto-start; probe-only rows are discarded. This is the implemented
  resume/retry path.
- "Pause queue" stops starting new jobs; active jobs keep running. True
  pause/resume is a later feature where the engine supports it.

Failure isolation:
- Every job owns its status and error. A failure never changes the status of
  sibling jobs.
- The failure card shows the title/fallback name, original link, localized
  reason, and actions. Raw engine output is behind "Details" and redacted.
- The batch is done when every job reaches `completed`, `failed`, `skipped`, or
  `cancelled`.
- A batch summary is computed and persisted: total, completed, failed, skipped,
  size, elapsed time, and the failed list.
- "Retry failed" enqueues only failed jobs as a new attempt within the same
  batch.

Collection expansion:
- Probe returns collection metadata and a paginated item list.
- Items are persisted so selection and per-item status survive restarts.
- The scheduler treats each selected item as a job, grouped by `batchId`.
- A Drive folder can be expanded into individual jobs or a ZIP job that owns the
  successful downloads.

## 7. Persistence

Use SQLite (decision: `drift` preferred, `sqflite` + FFI acceptable). Schema:

```sql
batches(
  id TEXT PRIMARY KEY,
  status TEXT NOT NULL,
  total_count INTEGER NOT NULL DEFAULT 0,
  completed_count INTEGER NOT NULL DEFAULT 0,
  failed_count INTEGER NOT NULL DEFAULT 0,
  skipped_count INTEGER NOT NULL DEFAULT 0,
  total_bytes INTEGER,
  created_at INTEGER NOT NULL,
  finished_at INTEGER
);

jobs(
  id TEXT PRIMARY KEY,
  batch_id TEXT REFERENCES batches(id) ON DELETE CASCADE,
  source_id TEXT NOT NULL,
  url TEXT NOT NULL,
  canonical_url TEXT,
  title TEXT,
  author TEXT,
  thumbnail_url TEXT,
  media_kind TEXT NOT NULL,
  format_id TEXT,
  quality TEXT,
  output_dir TEXT NOT NULL,
  status TEXT NOT NULL,
  progress REAL NOT NULL DEFAULT 0,
  downloaded_bytes INTEGER,
  total_bytes INTEGER,
  speed_bps REAL,
  eta_seconds INTEGER,
  error_code TEXT,
  error_message TEXT,
  engine_version TEXT,
  retry_count INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  completed_at INTEGER
);

job_files(
  id INTEGER PRIMARY KEY,
  job_id TEXT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  path TEXT NOT NULL,
  size_bytes INTEGER,
  missing INTEGER NOT NULL DEFAULT 0,
  deleted_at INTEGER
);

collection_items(
  id INTEGER PRIMARY KEY,
  batch_id TEXT NOT NULL,
  url TEXT NOT NULL,
  title TEXT,
  selected INTEGER NOT NULL DEFAULT 1,
  status TEXT NOT NULL,
  error_code TEXT,
  job_id TEXT
);

source_auth(
  source_id TEXT PRIMARY KEY,
  method TEXT NOT NULL,      -- cookies_file | browser
  cookie_path TEXT,          -- path only, never contents
  browser TEXT,
  updated_at INTEGER NOT NULL
);
```

`settings` stays in `shared_preferences`; cookie files live in app support
storage. History is the completed subset of `jobs` joined with `job_files`.
Batch summaries are the `batches` rows joined with failed jobs. Indexes on
`jobs.status`, `jobs.created_at`, `jobs.batch_id`, `jobs.source_id`, and
`batches.created_at`.

Implementation note (2026-10-27):
- Drift schema v1 currently implements `jobs` and `batch_summaries`. It stores
  the job fields the current UI and engine need, plus `zipEntriesJson`,
  `itemSkippedJson`, `failuresJson`, and `skippedItemsJson` for folder/ZIP
  batches. `job_files`, `collection_items`, `source_auth`, settings, and the
  separate `batches` row remain future work.
- The database is opened with `drift_flutter` in application-support storage.
  `jobs` are ordered by `created_at` plus a sortable ID; summaries use a
  microseconds `savedAtUs` key so the newest summary restores deterministically.
- A full job write happens on creation and every status transition. Progress
  writes are throttled to roughly one per second. `AppState.flushPersistence()`
  drains queued writes for tests and app lifecycle pauses.
- Interrupted `downloading`/`processing` jobs are written back as `queued` during
  restore and auto-scheduled. `probing` rows are deleted because analysis had not
  produced a durable download. Batch summaries missing at startup are rebuilt
  from terminal jobs.
- The database path is app support storage, not the output folder. Android still
  uses the app-specific output path from ADR-009.

Data migration:
- Optional one-time import of `~/.ytflow2_config.json` and
  `~/.ytflow2_history.json` on Windows.
- Mobile history import from the rescue app is optional; do not block v1.

## 8. Storage and filenames

Windows:
- Default: `%USERPROFILE%\Downloads\MediaFlow`.
- User-selected folder; path length and invalid characters handled.
- `.part`/engine temp files cleaned on cancel and startup.

Android:
- Default output: `MediaStore.Downloads/MediaFlow` on API 29+ (target).
- Custom output: SAF tree URI persisted with `takePersistableUriPermission`.
- API 24–28: app-specific external directory + FileProvider share, or a legacy
  write permission if a public folder is required. Decision pending; never
  `MANAGE_EXTERNAL_STORAGE`.
- Foreground service writes through a content resolver/SAF stream.

Implementation note (2026-10-27):
- Android currently resolves
  `getExternalFilesDir(DIRECTORY_DOWNLOADS)/MediaFlow` over
  `MethodChannel('com.mediaflow.app/platform')`, with `filesDir` as fallback.
  This is app-specific storage, not public Downloads; MediaStore/SAF remain
  pending. It requires no broad storage permission.
- The same channel returns `StatFs.availableBytes` for the output path. Windows
  free space is read with PowerShell; other desktops use `df -Pk`.
- The Drive selection sheet displays free space and asks for confirmation when
  every selected size is known and the payload exceeds free space. ZIP uses a
  peak estimate of twice the selected payload for staging plus the archive.
  A shortage warns; it does not hard-block.
- The current public folder parser does not obtain per-file sizes, so real
  folder totals and numeric low-space warnings remain unavailable.

Filename template default:
```
{title} [{id}] [{quality}].{ext}
```
Sanitize `< > : " / \ | ? *`, control characters, reserved Windows names, and
trailing dots/spaces. Max 180 characters before extension. Deduplicate with
` (2)`, ` (3)`. Arabic filenames are preserved.

## 9. Error model

```dart
enum MediaFlowErrorCode {
  invalidUrl,
  unsupportedUrl,
  loginRequired,
  cookiesExpired,
  permissionDenied,
  downloadRestricted,
  policyBlocked,
  drmProtected,
  paywalled,
  geoBlocked,
  rateLimited,
  quotaExceeded,
  notFound,
  liveUnavailable,
  driveLayoutChanged,
  zipFailed,
  diskFull,
  network,
  engineMissing,
  ffmpegMissing,
  cancelled,
  unknown,
}
```

Each error has `retryable`, a localized message key, and actions. Actions are
typed (`addCookies`, `openInBrowser`, `changeFolder`, `copyLink`, `retry`,
`skip`, `remove`). The UI never invents advice from raw stderr. Failure cards
show the original link, not a signed media URL.

## 10. Security and privacy

- No telemetry/analytics by default.
- Redact cookies, `Authorization`, signed query parameters, and tokens from logs.
- Cookie files live in app support storage, never in the repo, never in history.
- No Google credentials, OAuth client IDs, or Drive tokens are collected.
- Drive links are treated as capability URLs: do not log the raw URL in
  diagnostics; redact query parameters.
- Engine updates use HTTPS and checksum/signature verification where available.
- Reject `file:`, `javascript:`, and malformed URLs. Only `http(s)` is
  downloadable.
- Sanitize all filenames and verify the resolved path stays inside the selected
  output directory.
- Do not execute downloaded files; use the platform's open/share intent.

## 11. Testing

- **Unit:** source resolution, URL canonicalization, progress normalization,
  filename sanitizer, error classifier, scheduler/retry, collection paging,
  Drive HTML parsing, ZIP inclusion rules, batch summary counts.
- **Contract:** engine event schema, adapter capabilities, Drive path mapping.
- **Widget/golden:** Studio Dark, Light, OLED; Arabic RTL; 360dp phone and
  1280dp desktop; failure card; batch summary.
- **Integration:** fake engine for Analyze → Queue → Library; a mixed batch with
  failures; fake Drive HTML server with recorded responses; no live URLs.
- **Manual:** `product-spec.md` S-01…S-23, on Windows and Android, with public
  content.
- **Performance:** 10k library rows, 100-item collection, resume after kill.

## 12. CI and release

- `flutter analyze` and `flutter test` on every PR.
- Build Windows and Android debug artifacts on CI.
- Tagged release builds: Windows installer plus Android APK/AAB.
- Android ABI splits for release; no debug kernel blob in release.
- Bundle `yt-dlp.exe`/`ffmpeg.exe` on Windows; pin the Android engine.
- Secrets: signing keys only in CI/local secure storage. No Google OAuth client
  IDs are needed.
- Do not add live URLs to CI.

## 13. Dependency gates

These are proposed and require approval before being added:

| Dependency | Purpose | Platform | Alternative |
|---|---|---|---|
| `drift` + `drift_flutter` | typed DB/migrations | both | implemented |
| `dio` | HTTP with cancel/progress | both | Dart `HttpClient` |
| `archive` or native ZIP | folder ZIP | both | dependency-free Store/ZIP64 writer (implemented) |
| `desktop_drop` | drag/drop URLs | Windows | manual paste |
| `window_manager` | min size/title bar | Windows | default runner |
| `url_launcher` | open in browser | both | platform channel |
| `shared_preferences` | non-secret settings | both | existing |
| `provider` | optional state management | both | built-in `ChangeNotifier` |
| `youtubedl-android` | Android engine | Android | none (locked) |

Already present in the rescue app and likely reused: `path_provider`,
`file_picker`, `share_plus`, `open_filex`.

## 14. Migration from the current apps

- Keep `app.py` and `MediaFlow_Mobile/` runnable.
- New app lives in `apps/mediaflow/`; the Phase 2 scaffold is in progress.
- Reuse the Studio Dark palette and Arabic strings; the scaffold uses a temporary
  `AppStrings` map, then moves to ARB and `gen-l10n`.
- Do not carry over the Linux FFmpeg asset, Chaquopy runtime, dead services, or
  `MANAGE_EXTERNAL_STORAGE`.
- Import desktop config/history once, with a backup and a clear "imported" state.
