# Product Spec — MediaFlow Rebuild

## 1. Problem

Downloading media is fragmented. A user may need YouTube for one clip, TikTok for
another, a Facebook reel, an Instagram post, a Kick or Twitch VOD, SoundCloud for
audio, and a Google Drive folder for a batch of files. Existing tools are
single-site, ad-heavy, or desktop-only. Mobile users often have no good way to
send a link from another app into a downloader.

MediaFlow should make the common path obvious: paste or share a link, see what it
is, choose a format, and download it, with the same quality of experience on
Windows and Android.

## 2. Vision

A local-first media workbench that handles many sources without pretending they
are all the same. It is fast for the happy path, explicit about authentication
and restrictions, and good at recovering from the failures that real sites
produce.

## 3. Principles

1. **Local and private.** No account, no server, no telemetry by default.
2. **One obvious path.** Paste, analyze, choose, download. Advanced options stay
   out of the way.
3. **Honest failures.** Explain whether a link needs cookies, permission, a
   different format, or simply cannot be downloaded.
4. **Respect access controls.** Never bypass DRM, paywalls, owner-disabled
   downloads, or private-account restrictions.
5. **Same product, native feel.** One design language; Windows and Android each
   get platform-appropriate layouts and behaviors.
6. **Recoverable.** Queue state survives restarts; partial files can be retried;
   one failed item does not kill a batch.

## 4. Users and jobs

### Persona A — Desktop power user
Downloads several links a day, often playlists or folders, wants a queue,
concurrency control, cookies, and a clean library. Works on Windows.

### Persona B — Mobile sharer
Sees a clip in TikTok, Facebook, Instagram, YouTube, or Twitch, taps Share, picks
MediaFlow, and expects the download to start with minimal friction. Often
Arabic-speaking and uses RTL layout.

### Persona C — Drive batch user
Has a Google Drive file or folder link and wants everything locally. Sometimes
the folder is shared with their Google account; sometimes the owner has disabled
downloads.

### Core jobs
- Download one video/audio item at the best available quality.
- Download a YouTube playlist or a Drive folder as a batch.
- Record a live stream from the start if the source supports it, or from now.
- Find a previous download, open it, share it, or delete the file.
- Recover from a failed item without redoing the whole batch.

## 5. Scope

### v1.0 — usable multi-source release

**Intake**
- Paste one or many URLs (one per line).
- Windows: paste from clipboard; drag/drop URLs.
- Android: receive `ACTION_SEND` text from other apps.
- Detect duplicates and already-downloaded items.

**Sources**
- YouTube: videos, Shorts, live, playlists (single item and full playlist).
- TikTok: single video links.
- Facebook: videos, reels, live/VOD.
- Instagram: reels and posts.
- Kick: clips and VODs.
- Twitch: clips and VODs.
- SoundCloud: tracks and playlists.
- Google Drive: public files and folders; authorized files/folders via Google
  OAuth (see the Drive decision in `decisions.md`).
- Direct HTTP/HTTPS files, including HLS/DASH handled by the engine.
- A generic fallback for URLs the bundled yt-dlp build supports.

**Download**
- Metadata preview: title, author/channel, duration, thumbnail, source, media
  type.
- Format/quality selection with a sensible default.
- Audio-only extraction.
- Progress: percent, downloaded/total, speed, ETA, current stage.
- Cancel, retry, and remove.
- Queue with configurable concurrency.
- Live recording with an explicit stop control.
- Collection expansion (playlist/folder) with per-item selection.

**Library**
- Persistent history with file path, size, source, status, timestamp.
- Missing-file detection.
- Open, share, reveal in folder (Windows), delete history entry, delete file.

**Settings**
- Output folder (SAF on Android, native picker on Windows).
- Concurrency, retries, network timeout, proxy, rate limit.
- Cookie file/browser import; clear cookies.
- Theme (Dark/Light/OLED), language (English/Arabic/System), RTL.
- Filename template.
- Engine version and update check (Windows).
- Redacted diagnostic export.

**Mobile**
- Foreground service for active downloads with progress notification.
- Download continues when the app is backgrounded.
- MediaStore/SAF output; no `MANAGE_EXTERNAL_STORAGE`.
- Share target and "Open with" behavior.

### v1.1 — follow-up
- Mega and Gofile adapters.
- Browser bookmarklet / desktop browser companion.
- Playlist/channel browsing with search.
- Scheduled downloads.
- True pause/resume for active downloads where the engine supports it.
- Subtitles/thumbnail/SponsorBlock advanced options for YouTube.

### Later / not planned
- Torrents.
- iOS.
- Hosted service or debrid-style proxying.
- DRM-protected services (Netflix, Disney+, Spotify, etc.).
- Account sync or cloud backup.

## 6. Functional requirements

### FR-01 Intake
The app accepts a URL via paste, typed input, clipboard, drag/drop, or Android
share. It trims whitespace, ignores blank lines, and supports multiple URLs.

Acceptance:
- A single URL begins analysis automatically after paste or a short debounce.
- Multiple URLs produce a list of candidates; the user can analyze all.
- Invalid or unsupported URLs are marked before download starts.

### FR-02 Source resolution
A source registry maps URL patterns to adapters. The registry returns the most
specific adapter and never guesses a source from the page title.

Acceptance:
- Each URL pattern in `source-matrix.md` resolves to the expected adapter.
- Unknown http(s) URLs fall back to the generic/direct adapter.
- `file:`, `javascript:`, and malformed URLs are rejected.

### FR-03 Metadata probe
Before download, the app shows the best available metadata and capabilities:
single vs collection, live, audio available, subtitles, auth requirements.

Acceptance:
- Probe failure produces a classified error and a recovery action.
- A collection shows its item count before download.
- The UI never blocks on a thumbnail; a placeholder is shown instead.

### FR-04 Format selection
The app offers source-appropriate choices and defaults to the best combined
quality that will actually work on the platform.

Acceptance:
- Windows with FFmpeg can merge separate video/audio streams.
- Android uses the engine's FFmpeg build; the no-FFmpeg path is not used in the
  rebuild.
- Audio-only mode produces the selected container/codec or the closest supported
  one, with a note when conversion is impossible.
- "Best" never silently produces a silent video.

### FR-05 Download and progress
A job moves through `queued → probing → downloading → processing → completed`
or `failed/cancelled`. Progress is normalized to `0..1` at the boundary.

Acceptance:
- Percent never decreases within a job except after a retry/reset.
- Speed and ETA are hidden when unknown, not shown as zero.
- Cancellation stops the engine and removes partial artifacts.
- A completed job exposes the real file path(s).

### FR-06 Queue
The queue supports multiple jobs with a global concurrency limit, per-host
fairness, and retry.

Acceptance:
- Default concurrency is 2 on Windows and 1 on Android.
- Fragile hosts default to one active job.
- Retry uses backoff and does not retry auth/permission/DRM failures.
- Queue state survives app restart; interrupted jobs are recoverable.
- One failed item does not stop the queue.

### FR-07 Collections
Playlists and Drive folders expand into items. The user can select all, none, or
individual items.

Acceptance:
- A 100-item playlist does not freeze the UI.
- Folder recursion is bounded and cycle-safe.
- Skipped/unsupported items are reported, not silently dropped.

### FR-08 Live
Live streams show a LIVE state and record until the user stops or the stream
ends.

Acceptance:
- The app warns about disk usage and shows elapsed time/size.
- "From start" is offered only when the source/engine supports it.
- Stopping finalizes the file and adds it to the library.

### FR-09 Errors and recovery
Every failure maps to a stable error code, a localized message, and at least one
action.

Acceptance:
- `loginRequired` / `cookiesExpired` offer "Add cookies" or "Open in browser."
- `permissionDenied` and `downloadRestricted` explain the restriction and never
  retry with bypass techniques.
- `drmProtected` and `paywalled` are terminal.
- `diskFull` offers "Change folder" and "Remove partial file."
- `network` offers retry.

### FR-10 Library
History is persistent and searchable. It records enough to reopen or share the
file without re-probing the source.

Acceptance:
- Missing files are marked and can be removed from history.
- Deleting a file requires a confirmation that says the file will be removed
  from disk.
- Library can be filtered by source and status.

### FR-11 Settings
Settings are persisted and applied to new jobs immediately. Secrets are stored
separately from ordinary preferences.

Acceptance:
- Cookie files and OAuth tokens never appear in logs or history.
- Changing the output folder does not move existing files.
- Android never requests `MANAGE_EXTERNAL_STORAGE`.

### FR-12 Localization and RTL
All user-facing strings are localized in English and Arabic. Layout mirrors
correctly.

Acceptance:
- No hard-coded UI strings in widgets.
- Arabic layout flips navigation, icons with direction, and text alignment.
- Filenames and metadata in Arabic display correctly.
- Numbers use Western digits in Arabic UI.

### FR-13 Background downloads (Android)
Active downloads run in a foreground service with a notification. The service
stops cleanly when the queue empties.

Acceptance:
- A download continues when the app is backgrounded.
- The notification shows progress and a cancel action.
- The service respects battery/network constraints and does not leak.

### FR-14 Storage
Completed files go to a user-chosen location. Android uses MediaStore for the
public Downloads collection or SAF for a custom tree.

Acceptance:
- No broad storage permission is required on Android 11+.
- Files are visible to other apps after completion.
- Filename collisions are resolved deterministically.

### FR-15 Updates and diagnostics
The app shows engine versions and can export a redacted log bundle.

Acceptance:
- Windows can check for a newer yt-dlp build without breaking the bundled
  fallback.
- Android engine updates ship with app releases.
- Logs redact cookies, authorization headers, and signed query parameters.

## 7. UX flows

### Flow A — single link
1. Paste/share a URL.
2. App detects source and probes.
3. Media card shows thumbnail, title, author, duration, source badge.
4. Format/quality default to "Best."
5. Tap Download.
6. Job appears in Queue with progress.
7. On completion, a success state offers Open, Share, Show in folder.

### Flow B — batch
1. Paste multiple URLs.
2. App resolves each and shows a candidate list with per-item status.
3. User deselects unwanted items and taps "Download selected."
4. Queue groups the batch and reports completed/failed counts.

### Flow C — Drive folder
1. Paste a Drive folder link.
2. App detects public vs authorized access.
3. If public, folder listing loads; if private, app asks the user to sign in with
   Google.
4. User selects files, sees total size, starts the batch.
5. Restricted files are listed as skipped with a reason.

### Flow D — live
1. Paste a live URL.
2. App shows LIVE and (if supported) a "From start" option.
3. User starts recording; a persistent notification/indicator appears.
4. User stops; file is finalized and added to the library.

### Flow E — failure
1. Probe or download fails.
2. Error card states the cause and the action.
3. User fixes cookies/folder/network and retries only the failed item.

## 8. Non-functional requirements

- **Startup:** interactive in under 2 seconds on a mid-range Android device and
  a typical Windows laptop, with the library loaded lazily.
- **Responsiveness:** no main-thread I/O; large collections paginate.
- **Reliability:** queue and history survive crashes; partial files are cleaned
  or resumable.
- **Security:** no secrets in logs; OAuth tokens in secure storage; output paths
  constrained to the chosen folder.
- **Accessibility:** 48dp touch targets, contrast AA, screen-reader labels, RTL.
- **Privacy:** no analytics by default; diagnostics are opt-in and redacted.
- **Compatibility:** Windows 10/11; Android 7.0+ (proposed `minSdk 24`, revisit
  for MediaStore/foreground-service behavior).

## 9. Success criteria for v1

- All v1 source categories in `source-matrix.md` pass the manual acceptance
  checklist on Windows and Android, using public test content.
- Analyze → Download → Library works end-to-end on both platforms.
- A 20-item playlist/folder completes with per-item results and no UI freeze.
- An interrupted queue resumes after restart.
- Arabic RTL golden tests pass.
- `flutter analyze` is clean and all automated tests pass.
- No live URLs in automated tests.

## 10. Manual acceptance checklist

Use public, non-sensitive URLs. Do not commit the URLs or downloaded media.

| ID | Case | Expected |
|---|---|---|
| S-01 | YouTube video | metadata + best combined/merged download |
| S-02 | YouTube Shorts | same, vertical thumbnail handled |
| S-03 | YouTube live | LIVE state, stop finalizes file |
| S-04 | YouTube playlist | expand, select subset, batch completes |
| S-05 | TikTok video | metadata + video/audio download |
| S-06 | Facebook video | public video works; private asks for cookies |
| S-07 | Facebook reel | reel downloads |
| S-08 | Instagram reel | public/cookie path works |
| S-09 | Kick clip | clip downloads |
| S-10 | Kick VOD | VOD downloads; subscriber-only asks for cookies |
| S-11 | Twitch clip | clip downloads |
| S-12 | Twitch VOD | VOD downloads; expired/subscriber-only is explained |
| S-13 | SoundCloud track | audio downloads |
| S-14 | Google Drive public file | direct download, size/name correct |
| S-15 | Google Drive public folder | recursive listing, selection, batch |
| S-16 | Google Drive authorized folder | OAuth sign-in, permitted files download |
| S-17 | Google Drive restricted file | clear terminal error; no bypass attempt |
| S-18 | Direct MP4 | direct download with resume |
| S-19 | HLS URL | engine/FFmpeg path produces playable file |
| S-20 | Mixed batch | one failure does not stop others |

## 11. Risks

| Risk | Mitigation |
|---|---|
| Sites change and extractors break | Pin engine versions; update cadence; error classification; no hard-coded per-site parsing where yt-dlp works |
| Anti-bot / login walls | Cookie/browser import, clear guidance, no bypass claims |
| Drive restrictions | OAuth for authorized access; explicit terminal errors for owner-disabled downloads |
| Rate limits | Per-host concurrency, backoff, retry-after |
| Large folders / disk pressure | Size preview, limits, free-space check |
| Copyright / ToS | First-run notice, user-authorized scope, no hosting/proxying, no DRM |
| Android background limits | Foreground service, notification, battery optimization guidance |
| Windows path limits | Short sanitized names, collision handling, long-path awareness |

## 12. Open product questions

1. Should Google Drive OAuth ship in v1.0 or v1.1? Restricted folders require
   it, but it adds Google Cloud setup and mobile sign-in work.
2. Is Mega/Gofile needed in the first release, or is the list above enough?
3. Should the first release support image galleries (gallery-dl) or video/audio
   only?
4. Is a Windows bookmarklet/browser helper important, or is paste enough?
5. Which output template should be the default for Arabic titles?
