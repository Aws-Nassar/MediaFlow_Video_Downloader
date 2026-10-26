# Source Support Matrix

This matrix covers the source categories supplied for the rebuild. The raw URLs
are manual acceptance cases only; they are intentionally not stored in this
repository. Use public, non-sensitive examples when testing.

## How support is defined

- **Engine-supported**: the bundled yt-dlp build has an extractor for the host.
  Extractors can break when a site changes; the app classifies the failure and
  offers recovery.
- **Adapter-supported**: MediaFlow implements the source directly (Google Drive,
  direct HTTP).
- **Authorized**: works with the user's own cookies/session or Google account.
  It does not mean access controls are bypassed.
- **v1.0 / v1.1 / later**: release target.

## Matrix

| Source | URL shapes | Engine / adapter | v1 target | Auth | Notes |
|---|---|---|---|---|---|
| YouTube video | `youtube.com/watch?v=…`, `youtu.be/…` | yt-dlp | v1.0 | Optional cookies for age/region/members | Best merged quality on both platforms; subtitles/thumbnail later |
| YouTube Shorts | `youtube.com/shorts/…` | yt-dlp | v1.0 | Optional | Vertical thumbnail/title handling |
| YouTube live | `youtube.com/live/…` | yt-dlp | v1.0 | Optional | "From start" only when available; otherwise record from now |
| YouTube playlist | `youtube.com/playlist?list=…` | yt-dlp | v1.0 | Optional | Expand, select, batch |
| TikTok video | `tiktok.com/@user/video/…`, short links | yt-dlp | v1.0 | Cookies often needed for region/private | No watermark preference when the extractor provides it |
| Facebook video | `facebook.com/<page>/videos/…` | yt-dlp | v1.0 | Cookies for private/region | Public videos may work anonymously |
| Facebook reel | `facebook.com/reel/…` | yt-dlp | v1.0 | Same | Reels share the Facebook extractor path |
| Facebook live/VOD | `facebook.com/<page>/videos/…` | yt-dlp | v1.0 | Same | LIVE state; stop finalizes |
| Instagram reel | `instagram.com/reel/…` | yt-dlp | v1.0 | Cookies strongly recommended | Rate limits are common; backoff required |
| Instagram post | `instagram.com/p/…` | yt-dlp | v1.0 | Cookies | Carousels: first media or all items depending on extractor output |
| Kick clip | `kick.com/<channel>/clips/clip_…` | yt-dlp | v1.0 | Public | Clip URL is the primary case |
| Kick VOD | `kick.com/<channel>/videos/<uuid>` | yt-dlp | v1.0 | Optional for subscriber-only | HLS path; FFmpeg in engine |
| Twitch clip | `twitch.tv/<channel>/clip/<slug>` | yt-dlp | v1.0 | Public | Short clips |
| Twitch VOD | `twitch.tv/videos/<id>` | yt-dlp | v1.0 | Cookies for subscriber-only | VODs expire; explain 404/expired |
| SoundCloud track | `soundcloud.com/<user>/<track>` | yt-dlp | v1.0 | Optional for Go+ | Audio-only by default |
| SoundCloud playlist | `soundcloud.com/<user>/sets/<set>` | yt-dlp | v1.0 | Optional | Expand like other collections |
| Google Drive file | `drive.google.com/file/d/<id>/view` | Drive adapter | v1.0 public; authorized per ADR-008 | Google OAuth for private | Direct/API download; large files supported |
| Google Drive folder | `drive.google.com/drive/folders/<id>` | Drive adapter | v1.0 public; authorized per ADR-008 | Google OAuth for private | Recursive listing, selection, size preview |
| Direct file | any `http(s)://…/file.ext` | HTTP adapter | v1.0 | None | Resume/Range, content-disposition filename |
| HLS / DASH | `.m3u8`, `.mpd` | yt-dlp/FFmpeg | v1.0 | None | Engine path; no custom parser |
| Generic supported host | other yt-dlp extractors | yt-dlp generic | v1.0 | Varies | Show "supported by engine", not a hardcoded 268+ claim |
| Mega | `mega.nz/…` | custom adapter | later | Mega session/key | Encrypted; not v1 |
| Gofile | `gofile.io/d/…` | custom adapter | later | Optional token | API-based; not v1 |
| Torrents | magnet/torrent | none | not planned | — | Out of scope for v1 |

\* Drive OAuth timing is an open decision. If restricted/private Drive folders
are a must-have for the first release, OAuth moves into v1.0. Public Drive can
ship earlier.

## Auth and cookie behavior

| Need | Windows | Android |
|---|---|---|
| Public source | None | None |
| Login/private/region | Import `cookies.txt` or read browser cookies (Chrome/Edge/Firefox) | Import a `cookies.txt` file into app storage |
| Google Drive authorized | OAuth 2.0 PKCE via browser + loopback; refresh token in secure storage | Google Sign-In with Drive read scope; token in secure storage |
| Expired cookies | Detect, ask to re-import, retry only after user action | Same |
| Secrets in logs | Redact `Cookie`, `Authorization`, signed query strings | Same |

Rules:
- Never log or upload cookie contents.
- Never commit cookie files or OAuth client secrets.
- Never offer "try another endpoint" to defeat a permission or download
  restriction.

## Google Drive specifics

### Public file
- Resolve the file ID from `/file/d/<id>/view`, `/open?id=<id>`, or
  `uc?id=<id>`.
- Download via the Drive API `files.get?alt=media` with an API key, or the
  public `uc?export=download` flow with the large-file confirmation token.
- Prefer the API path for consistent filenames and range support.

### Public folder
- `files.list` with `q="<folderId>" in parents and trashed=false`.
- Fields: `nextPageToken, files(id,name,mimeType,size,modifiedTime,shortcutDetails,exportLinks)`.
- Recurse into subfolders with a depth limit (10) and item limit (10,000).
- Google Docs/Sheets/Slides have no binary media; export to a chosen format
  (PDF/DOCX/XLSX/PPTX) or skip with a clear reason.
- Shortcuts: resolve only if permitted; otherwise skip.

### Authorized/private
- OAuth scope: `https://www.googleapis.com/auth/drive.readonly`.
- Desktop: system browser + loopback redirect on `127.0.0.1` with PKCE.
- Android: Google Sign-In / Credential Manager, then Drive API calls.
- Access is limited to what the signed-in account can already read.
- The user must be able to revoke access from their Google account.

### Restricted / blocked
| Condition | Behavior |
|---|---|
| Not shared with the user | `permissionDenied`: sign in, request access, or open in browser |
| Owner disabled download/copy | `downloadRestricted`: terminal; explain that the owner disabled it; no bypass |
| Workspace admin policy | `policyBlocked`: terminal; contact admin |
| Download quota exceeded | `quotaExceeded`: retry later; signing in may help; no endpoint tricks |
| File removed | `notFound`: remove from queue |
| Large file / interrupted | Resume with Range; verify final size |

## anything.rip parity notes

The reference site advertises one input, 268+ hosts, and support for YouTube,
TikTok, Instagram, SoundCloud, Mega, Google Drive, Gofile, and torrents. It also
states that hard-paywalled files are not accessible.

MediaFlow's v1 parity target:
- One input that accepts many hosts and multiple URLs.
- Automatic source detection and a simple download flow.
- YouTube, TikTok, Instagram, SoundCloud, Google Drive, plus the Facebook, Kick,
  and Twitch categories above.
- No hard-paywall/DRM access.
- Mega, Gofile, and torrents are explicitly later/not planned.

Do not copy anything.rip's code, branding, or assets. Use it only to validate
the interaction model.

## Engine update strategy

- **Windows:** bundle a known-good `yt-dlp.exe`; show its version; optional
  "check for updates" downloads a new binary into app data with a rollback to the
  bundled version.
- **Android:** the yt-dlp version is pinned by `youtubedl-android`; update it with
  app releases.
- Record the engine version in diagnostics and history metadata so a failure can
  be tied to an extractor change.
- Add a source smoke test that checks extractor availability without network
  access.

## Source acceptance IDs

The manual checklist in `product-spec.md` uses S-01…S-20. Each source row above
maps to at least one ID. Automated tests use recorded JSON and fake engines, not
live URLs.
