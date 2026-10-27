# MediaFlow Rebuild — Spec 001

Status: Phase 4 Android engine bridge implemented; device verification pending
Last updated: 2026-10-27

## Why this exists

MediaFlow is being rebuilt as one Flutter app for **Windows and Android**. The
current desktop app (`app.py`) and the rescued Android app (`MediaFlow_Mobile/`)
stay in the repo as references and fallbacks until the rebuild reaches parity.

The product target is a local-first, multi-source downloader: paste a link from
YouTube, TikTok, Facebook, Instagram, Kick, Twitch, SoundCloud, Google Drive, or
a direct file URL, then analyze, queue, download, and manage it in a polished
Studio Dark UI.

[anything.rip](https://anything.rip/) is a **UX reference**, not a code or asset
source. It demonstrates the core idea: one input, automatic host detection, many
supported sources, and a simple "rip" flow. MediaFlow runs locally and does not
proxy or host content.

## Locked decisions

| Decision | Choice |
|---|---|
| Client | One Flutter app, Windows + Android |
| Visual direction | Studio Dark |
| Windows engine | Bundled `yt-dlp.exe` + `ffmpeg.exe` subprocess |
| Android engine | `youtubedl-android` + FFmpeg; no new Chaquopy/Python runtime |
| Architecture | Local-first; no backend service; no telemetry by default |
| Google Drive | Link-shared files/folders; no Google account, OAuth, or API key |
| Batch behavior | Continue after an item fails; show a per-item error and an end-of-batch summary |
| Content scope | Link-shared/public content or content the user is authorized to access |
| Prohibited | DRM bypass, paywall bypass, unauthorized private content |

## Documents

1. [product-spec.md](product-spec.md) — users, scope, functional requirements,
   acceptance criteria, compliance boundaries.
2. [source-matrix.md](source-matrix.md) — source-by-source support plan for the
   links provided for this rebuild, auth needs, and failure behavior.
3. [architecture.md](architecture.md) — Flutter layers, adapter contracts,
   engines, queue, persistence, Drive, storage, security, testing.
4. [design-system.md](design-system.md) — Studio Dark tokens, PC/mobile layouts,
   components, RTL and accessibility.
5. [tasks.md](tasks.md) — phased backlog with acceptance criteria and dependency
   gates.
6. [decisions.md](decisions.md) — accepted and open architecture decisions.

## Baseline

- `app.py` is the working desktop reference. Do not rewrite or delete it during
  the rebuild.
- `MediaFlow_Mobile/` is the rescued Android baseline. It uses Chaquopy and will
  be replaced, not extended, by the rebuild.
- The rebuild lives in `apps/mediaflow/` so the references remain runnable.
  The app path and `com.mediaflow.app` application ID are used for the scaffold;
  confirm them before release. The Phase 2 fake-engine vertical slice and the
  Android `youtubedl-android` bridge are built; Android runtime verification is
  still pending. The Windows runner still needs a Visual Studio C++ toolchain on
  this machine.

## Hard boundaries

- **Google Drive:** link-shared files and folders ("anyone with the link") are
  supported without a Google account, OAuth, or an API key. A missing download
  button is a UI limitation, not a block; the app reads the shared listing and
  requests files directly. If an item truly requires sign-in, the owner disabled
  downloads, or Workspace policy blocks it, that item is a terminal error. It is
  skipped and reported; it is **not** bypassed.
- **Social sites:** cookies or a signed-in session may be used for content the
  user can already view. The app does not defeat age gates, region locks,
  private-account controls, or DRM.
- **No hosting/proxying:** MediaFlow downloads directly from the source to the
  user's device. It is not a debrid service.
- **No torrent client in v1.** Torrents are out of scope for the first release.
- **No sample URLs in automated tests.** The real links supplied for this
  rebuild are manual acceptance cases only and must not be committed as
  fixtures.

## Review checklist

- [x] Confirm the v1 source list and that Google Drive is link-shared only, with
  no OAuth.
- [x] Use `apps/mediaflow/` and `com.mediaflow.app` for the scaffold; confirm
  before release.
- [ ] Approve proposed dependencies before they are added. Phase 2, the ZIP
  step, and the platform-storage step added none.
- [ ] Confirm Android `minSdk` (scaffold uses 24) and storage behavior. The
  rebuild currently uses app-specific external Downloads/MediaFlow; MediaStore
  and SAF are still pending.
- [x] Confirm ZIP default (individual downloads), recursion (on), and
  skip-versus-stop (skip and report) behavior.
- [ ] Confirm whether Mega/Gofile/torrents are wanted later.
