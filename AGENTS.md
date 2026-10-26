# AGENTS.md

## Repo shape
- Root is **MediaFlow Pro v2.1**, a single-file PyQt5 desktop app (`app.py`). It is the working reference.
- `MediaFlow_Mobile/` is a Flutter Android app with a Python backend embedded via Chaquopy (`android/app/src/main/python/mediaflow_core.py`).
- The Flutter app is a regression from the pre-Flutter Java app. Do not assume desktop parity or trust its current behavior.
- Agreed rebuild direction (not scaffolded yet): one Flutter app, Windows + Android. Specs now live in `specs/001-rebuild/`; proposed app path is `apps/mediaflow/`. Do not move or rewrite `app.py` or `MediaFlow_Mobile/`.
- CI is `.github/workflows/release.yml`, triggered by `v*` tags. The Android leg now builds with Flutter on `MediaFlow_Mobile`; verify it on the next tag.

## Rebuild direction
- Product target: local-first multi-source downloader for Windows and Android. Read `specs/001-rebuild/README.md` first, then `product-spec.md`, `source-matrix.md`, `architecture.md`, `design-system.md`, `tasks.md`, and `decisions.md`.
- UX reference: [anything.rip](https://anything.rip/). Use it only to validate the interaction model; do not copy its code, branding, or assets.
- v1 sources: YouTube, TikTok, Facebook, Instagram, Kick, Twitch, SoundCloud, Google Drive public/authorized, direct HTTP, HLS/DASH, and generic yt-dlp hosts. Mega/Gofile are later; torrents and DRM services are out.
- Content boundary: public or user-authorized content only. Never bypass DRM, paywalls, private-account controls, owner-disabled downloads, or Workspace policy. Restricted Google Drive files are terminal errors, not a challenge.
- Sample URLs supplied for acceptance are private notes only. Do not commit them, downloaded media, cookies, or OAuth secrets. Automated tests use recorded JSON and fake engines.
- Locked stack: Windows `yt-dlp.exe` + `ffmpeg.exe` subprocess; Android `youtubedl-android` + FFmpeg. No new Chaquopy/Python runtime in the rebuild.
- Design: Studio Dark, one Flutter codebase, English/Arabic with RTL. See `design-system.md`.

## Commands

Desktop (Python 3.10+):
```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python app.py
```

Build the exe (after installing `requirements-dev.txt`):
```powershell
.\tools\build_exe.ps1
```

`MediaFlow.spec` bundles `tools\ffmpeg.exe`, `ffprobe.exe`, and `ffplay.exe` when present, otherwise whatever is on PATH. Those binaries are gitignored.

Android:
```powershell
cd MediaFlow_Mobile
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
# or, if script execution is blocked:
powershell -NoProfile -ExecutionPolicy Bypass -File .\build_debug_apk.ps1
```

APK output: `MediaFlow_Mobile\build\app\outputs\flutter-apk\app-debug.apk`.

The root `MediaFlow_Mobile/` has no `gradlew`; the Android wrapper lives at `android/gradlew`, and those wrapper files are gitignored. Flutter injects them from its cache during `flutter build`. Use `flutter build` from `MediaFlow_Mobile`, not `./gradlew` from the root. `test/` exists and `flutter test` runs 8 tests. `flutter analyze` is clean as of the Phase 0 rescue; keep it clean.

## Mobile contract (Phase 0 rescue)
- Python emits `percent` in `0..1`; `normalizePercent()` now accepts `0..1` and `0..100` and is covered by tests.
- Python returns `downloaded_files`; `extractDownloadedFiles()` reads it and falls back to `file_path`.
- Dart sends `concurrent`/`cookie_file`; the Python core also accepts the old `concurrent_fragments`/`cookiefile` aliases.
- Without FFmpeg, `_format_selector()` picks progressive `best[acodec!=none][vcodec!=none]` formats. Do not reintroduce `bestvideo` for the no-FFmpeg path; it produces silent video.
- `assets/ffmpeg` (a Linux ELF) and the dead `ffmpeg_service.dart`/`prefs_service.dart` were removed. Do not re-add a desktop FFmpeg binary to Android assets. The Android settings screen no longer exposes the FFmpeg toggle; the backend uses progressive formats.
- History share/open use `share_plus` and `open_filex`; delete removes the file from disk. No foreground service yet, so downloads stop when backgrounded.
- Do not overwrite `DownloadProvider.statusText` with backend progress messages: `ProgressCard` compares it to exact strings (`downloading`, `completed`, etc.) and hides the speed/percent/cancel UI otherwise. The contract test covers this.
- `MANAGE_EXTERNAL_STORAGE` is still declared; the default output is app-specific external storage. Plan MediaStore/SAF.

## Build and CI gotchas
- `android/app/build.gradle.kts` hardcodes Chaquopy `buildPython` to `C:/Users/coldw/AppData/Local/Python/bin/python.exe` and Python 3.14. That path currently exists (Python 3.14.8), but `where python` may find the WindowsApps alias first. CI sets `CHAQUOPY_BUILD_PYTHON`.
- `release.yml` now uses `working-directory: MediaFlow_Mobile`, Flutter 3.44.0, `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter build apk`. Do not switch back to `Videos_Downloader_Mobile` or root `./gradlew`.
- Kotlin plugin must be >= 2.2.20: `share_plus 12.0.2` ships Kotlin 2.2 metadata, and Kotlin 2.0.21 fails with "Module was compiled with an incompatible version". AGP 8.7.3 works locally, but Flutter warns to upgrade to >= 8.11.1. `share_plus` also warns that it applies KGP and future Flutter will require Built-in Kotlin.
- A clean Gradle build on Windows can still print Kotlin `Could not close incremental caches` / `different roots` errors; the APK builds anyway. If the build actually fails, run `flutter clean` or set `kotlin.incremental=false` in `android/gradle.properties`.
- Default PowerShell execution policy blocks `build_debug_apk.ps1`; run it with `-ExecutionPolicy Bypass`.
- The debug APK is ~188 MB because Chaquopy packages CPython for `arm64-v8a` and `x86_64` plus yt-dlp, and debug Flutter includes the kernel blob and validation layer. Narrow ABIs for release.
- `.gitignore` ignores `*.exe`, `tools/ffmpeg*.exe`, `dist/`, `build/`, and `.venv/`. `AGENTS.md` itself is not ignored; commit it so the guidance is shared.
- `.editorconfig` says 4-space indent, but Dart is formatted by `dart format` (2 spaces). Do not hand-indent Dart to 4.
- Root `README.md` has mojibake and stale details; `MediaFlow_Mobile/README.md` is the default Flutter template. Trust code and config.
- Desktop state lives outside the repo: `~/.ytflow2_config.json` and `~/.ytflow2_history.json`. Never commit them.
- `requirements.txt` uses `yt-dlp[default]`; mobile uses plain `yt-dlp` because Chaquopy cannot install the extra deps. Keep that split unless verified.

## Architecture notes
- Desktop: `build_ydl_opts()` is the single yt-dlp option builder; `DownloadPage._download_worker()` runs it on a thread and sends UI updates through `WorkerSignals`. `yt_dlp` is lazy-imported, so the first Analyse is slow by design.
- Mobile: `YtdlpService` wraps the MethodChannel/EventChannel; `PythonBridge.kt` starts Chaquopy and calls `mediaflow_core.py`. `l10n.dart` is a manual en/ar string map, not ARB/gen-l10n. `lib/services/download_contract.dart` holds the pure progress/result helpers and their tests.
- Correct pre-Flutter behavior is in git history: `git show 81008d4^:Videos_Downloader_Mobile/app/src/main/java/com/mediaflow/android/MainActivity.java`. It scales `percent*1000`, reads `downloaded_files`, and scans real files for play/share/delete.
- `hooks/hook_ffmpeg_path.py` puts bundled FFmpeg on PATH at runtime.

## Rules
- Do not rewrite or delete `app.py` during the rebuild; it is the reference. Keep rescue fixes separate from rebuild work.
- New Android work targets `youtubedl-android`; do not add another Chaquopy/Python runtime.
- Do not add `MANAGE_EXTERNAL_STORAGE`; plan MediaStore/SAF instead.
- No live URLs or real downloads in automated tests. Use recorded yt-dlp JSON and a fake executable.
- Never log cookies, signed URLs, or tokens; never commit `cookies.txt`.
- Keep user-facing strings localized; for the current app add them to `l10n.dart`; for the rebuild use ARB/gen-l10n.
- Ask before adding a dependency and record accepted/proposed decisions in `specs/001-rebuild/decisions.md`.
- Never add bypass logic for DRM, paywalls, private accounts, owner-disabled Google Drive downloads, or Workspace policy. Explain the restriction and offer an authorized path.
- Verify with the commands above and report the output. Do not claim a build or fix without running it.
- PyQt5 is GPL/commercial; check licensing before distributing a Python desktop build.

## Before finishing
- `flutter analyze` is clean.
- `flutter test` passes.
- `flutter build apk --debug` succeeds if Android code changed. The rescue build produced `build/app/outputs/flutter-apk/app-debug.apk` but has not been installed or run on a device/emulator.
- `python app.py` starts if desktop code changed, or state why it could not be run.
- Update this file if you discover a new trap.
