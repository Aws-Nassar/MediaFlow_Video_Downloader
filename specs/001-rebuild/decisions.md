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
- Support public content and content the user is authorized to access.
- Use cookies or OAuth only to access what the user can already view.
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

**Status:** Proposed

**Options:**
- `provider` / `ChangeNotifier`: already used in the rescue app; low migration
  cost.
- `riverpod`: better testability and async composition; new dependency and
  learning curve.

**Recommendation:** Keep `provider` for v1 if the team is small; revisit if the
queue/collection state becomes hard to test.

## ADR-007 — Persistence

**Status:** Proposed

**Options:**
- `drift` + `sqlite3_flutter_libs`: typed schema, migrations, good tests.
- `sqflite` + `sqflite_common_ffi`: less codegen, two platform paths.
- JSON files: not acceptable for queue state and 10k history rows.

**Recommendation:** `drift` for typed jobs/collections/files and migrations.
Requires dependency approval.

## ADR-008 — Google Drive scope and timing

**Status:** Open

**Context:** The user needs files/folders that may be private or restricted.

**Options:**
- A. v1.0 public Drive only; authorized Drive in v1.1.
- B. v1.0 includes OAuth for authorized Drive on both platforms.
- C. Public Drive only; authorized users use Drive for desktop and a local
  folder.

**Recommendation:** B if restricted folders are a must-have for the first
release; otherwise A. In all cases, owner-disabled downloads are terminal and
not bypassed. B requires a Google Cloud project, OAuth consent screen, desktop
loopback flow, Android sign-in, and secure token storage.

## ADR-009 — Android storage

**Status:** Proposed

**Context:** The rescue app declares `MANAGE_EXTERNAL_STORAGE`; the rebuild must
not.

**Decision:** Default to MediaStore `Downloads` on API 29+; custom folders via
SAF. For API 24–28, use app-specific external storage + FileProvider, or a
legacy write permission if a public folder is mandatory.

**Open:** `minSdk` 24 vs 26. Recommendation: 26 if it simplifies storage and
foreground-service behavior; confirm device coverage.

## ADR-010 — App location and identity

**Status:** Open

**Proposal:**
- Code: `apps/mediaflow/`.
- Application ID: `com.mediaflow.app` (Android) / `com.mediaflow.app` (Windows
  package identity if MSIX).
- Display name: `MediaFlow`.

**Consequences:** A new app can be installed alongside the rescue app during
testing. The final ID must be chosen before signing/release.

## ADR-011 — Localization

**Status:** Accepted

**Context:** The rescue app uses a manual string map; it works but is easy to
drift.

**Decision:** Move to Flutter `gen-l10n` with ARB files for English and Arabic.
Use Western digits in Arabic UI.

**Consequences:** One more build step; better placeholder safety and RTL
coverage. Keep the existing Arabic copy where it is good.

## ADR-012 — Multi-source scope

**Status:** Proposed

**v1.0 sources:** YouTube, TikTok, Facebook, Instagram, Kick, Twitch,
SoundCloud, Google Drive (public; authorized per ADR-008), direct HTTP, HLS/DASH,
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
