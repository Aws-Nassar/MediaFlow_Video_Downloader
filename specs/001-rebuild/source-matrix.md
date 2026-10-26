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
- **Link-shared**: readable by anyone with the URL; no account is required.
  A missing download button does not change this.
- **Cookie-authorized**: works with the user's own cookies for content the user
  can already view. It does not mean access controls are bypassed.
- **v1.0 / v1.1 / later**: release target.

## Matrix

| Source | URL shapes | Engine / adapter | v1 target | Access | Notes |
|---|---|---|---|---|---|
| YouTube video | `youtube.com/watch?v=…`, `youtu.be/…` | yt-dlp | v1.0 | Public; optional cookies for age/region/members | Best merged quality on both platforms; subtitles/thumbnail later |
| YouTube Shorts | `youtube.com/shorts/…` | yt-dlp | v1.0 | Public; optional cookies | Vertical thumbnail/title handling |
| YouTube live | `youtube.com/live/…` | yt-dlp | v1.0 | Public; optional cookies | "From start" only when available; otherwise record from now |
| YouTube playlist | `youtube.com/playlist?list=…` | yt-dlp | v1.0 | Public; optional cookies | Expand, select, batch |
| TikTok video | `tiktok.com/@user/video/…`, short links | yt-dlp | v1.0 | Public; cookies often needed for region/private | No watermark preference when the extractor provides it |
| Facebook video | `facebook.com/<page>/videos/…` | yt-dlp | v1.0 | Public; cookies for private/region | Public videos may work anonymously |
| Facebook reel | `facebook.com/reel/…` | yt-dlp | v1.0 | Public; cookies for private/region | Reels share the Facebook extractor path |
| Facebook live/VOD | `facebook.com/<page>/videos/…` | yt-dlp | v1.0 | Public; cookies for private/region | LIVE state; stop finalizes |
| Instagram reel | `instagram.com/reel/…` | yt-dlp | v1.0 | Public; cookies strongly recommended | Rate limits are common; backoff required |
| Instagram post | `instagram.com/p/…` | yt-dlp | v1.0 | Public; cookies | Carousels: first media or all items depending on extractor output |
| Kick clip | `kick.com/<channel>/clips/clip_…` | yt-dlp | v1.0 | Public | Clip URL is the primary case |
| Kick VOD | `kick.com/<channel>/videos/<uuid>` | yt-dlp | v1.0 | Public; cookies for subscriber-only | HLS path; FFmpeg in engine |
| Twitch clip | `twitch.tv/<channel>/clip/<slug>` | yt-dlp | v1.0 | Public | Short clips |
| Twitch VOD | `twitch.tv/videos/<id>` | yt-dlp | v1.0 | Public; cookies for subscriber-only | VODs expire; explain 404/expired |
| SoundCloud track | `soundcloud.com/<user>/<track>` | yt-dlp | v1.0 | Public; optional cookies for Go+ | Audio-only by default |
| SoundCloud playlist | `soundcloud.com/<user>/sets/<set>` | yt-dlp | v1.0 | Public; optional cookies | Expand like other collections |
| Google Drive file | `drive.google.com/file/d/<id>/view` | Drive adapter | v1.0 link-shared | None | Direct public download; large-file confirmation; no OAuth or API key |
| Google Drive folder | `drive.google.com/drive/folders/<id>` | Drive adapter | v1.0 link-shared | None | Public listing, recursion, selection, ZIP; no download button needed |
| Direct file | any `http(s)://…/file.ext` | HTTP adapter | v1.0 | None | Resume/Range, content-disposition filename |
| HLS / DASH | `.m3u8`, `.mpd` | yt-dlp/FFmpeg | v1.0 | None | Engine path; no custom parser |
| Generic supported host | other yt-dlp extractors | yt-dlp generic | v1.0 | Varies | Show "supported by engine", not a hardcoded 268+ claim |
| Mega | `mega.nz/…` | custom adapter | later | Mega session/key | Encrypted; not v1 |
| Gofile | `gofile.io/d/…` | custom adapter | later | Optional token | API-based; not v1 |
| Torrents | magnet/torrent | none | not planned | — | Out of scope for v1 |

## Access and cookie behavior

| Need | Windows | Android |
|---|---|---|
| Link-shared or public source | None | None |
| Social login/private/region | Import `cookies.txt` or read browser cookies (Chrome/Edge/Firefox) | Import a `cookies.txt` file into app storage |
| Google Drive link-shared | None | None |
| Google Drive truly restricted | Not supported without authorization; no OAuth in v1 | Same |
| Expired cookies | Detect, ask to re-import, retry only after user action | Same |
| Secrets in logs | Redact `Cookie`, `Authorization`, signed query strings | Same |

Rules:
- Never log or upload cookie contents.
- Never commit cookie files or account tokens.
- Never offer "try another endpoint" to defeat a permission or download
  restriction.
- Do not add Google Sign-In, OAuth clients, or `googleapis` to the rebuild.

## Google Drive specifics

### Link-shared file
- Resolve the file ID from `/file/d/<id>/view`, `/open?id=<id>`, or
  `uc?id=<id>`.
- Download via the public `uc?export=download` flow, including the large-file
  confirmation token. No API key or account is required.
- Use the response's `Content-Disposition` name and `Content-Length` when
  available.

### Link-shared folder
- Read the public folder listing (the `embeddedfolderview` view or equivalent
  public HTML). A missing download button is not a block.
- Parse file and subfolder IDs, names, and types. Recurse into subfolders with a
  depth limit (10) and item limit (10,000).
- Google Docs/Sheets/Slides have no binary media; export to a chosen format
  (PDF/DOCX/XLSX/PPTX) or skip with a clear reason.
- Shortcuts: resolve only if permitted; otherwise skip.
- Offer "Download all" and "Download as ZIP." A ZIP contains only successful
  files; skipped files are listed in the batch summary.

### Restricted / blocked
| Condition | Behavior |
|---|---|
| Folder/file needs sign-in | `permissionDenied`: terminal; offer "Open in browser" or "Request access." No OAuth in v1 |
| Owner disabled download/copy | `downloadRestricted`: terminal; explain that the owner disabled it; no bypass |
| Workspace admin policy | `policyBlocked`: terminal; contact admin |
| Download quota exceeded | `quotaExceeded`: retry later; no endpoint tricks |
| File removed | `notFound`: remove from queue |
| Large file / interrupted | Resume with Range where supported; verify final size |
| Public folder layout changed | `driveLayoutChanged`: clear error; parser fixture update needed |

## anything.rip parity notes

The reference site advertises one input, 268+ hosts, and support for YouTube,
TikTok, Instagram, SoundCloud, Mega, Google Drive, Gofile, and torrents. It also
states that hard-paywalled files are not accessible.

MediaFlow's v1 parity target:
- One input that accepts many hosts and multiple URLs.
- Automatic source detection and a simple download flow.
- YouTube, TikTok, Instagram, SoundCloud, Google Drive, plus the Facebook, Kick,
  and Twitch categories above.
- Link-shared Drive folder listing and ZIP without OAuth.
- No hard-paywall/DRM access.
- Mega, Gofile, and torrents are explicitly later/not planned.

## Failure behavior

Every source maps engine failures into the shared error model. The queue shows a
failure card with the item name, original link, localized reason, and actions.
The batch continues unless the user explicitly stops it.

| Source | Example failure | Behavior |
|---|---|---|
| yt-dlp sources | `loginRequired`, `cookiesExpired`, `rateLimited`, `notFound` | Classify; retry transient only; offer cookies/browser |
| Live | Stream ended or unavailable | Finalize or fail the item; never hang |
| Drive folder item | Owner disabled downloads | Skip item; continue; report in summary |
| Drive folder listing | Layout changed | Fail the folder with `driveLayoutChanged`; no partial silent drop |
| Direct HTTP | 404, 403, network reset | Retry 5xx/network; terminal for 4xx |
| ZIP | One file failed | Zip successful files; report skipped |

The end-of-batch summary is defined in `product-spec.md` FR-16.

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

The manual checklist in `product-spec.md` uses S-01…S-23. Each source row above
maps to at least one ID. Automated tests use recorded JSON and fake engines, not
live URLs.
