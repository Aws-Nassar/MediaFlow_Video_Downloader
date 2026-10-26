# MediaFlow Rebuild — Spec 001

Status: Draft for review
Last updated: 2026-10-26

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
| Content scope | Public content or content the user is authorized to access |
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
- The rebuild will live in a new app directory (proposed: `apps/mediaflow/`) so
  the references remain runnable.

## Hard boundaries

- **Google Drive:** public files/folders and files/folders the signed-in user can
  access are supported. Files where the owner disabled downloads, Workspace
  policy blocks access, or the user lacks permission are **not** bypassed. The
  app explains the restriction and offers "open in browser" or "request access."
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

- [ ] Confirm the v1 source list and the Drive OAuth timing.
- [ ] Confirm the new app directory and application ID.
- [ ] Approve proposed dependencies before they are added.
- [ ] Confirm Android `minSdk` and storage behavior.
- [ ] Confirm whether Mega/Gofile/torrents are wanted later.
