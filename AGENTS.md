# AGENTS.md

## Repo shape
- Root is **MediaFlow Pro v2.1**, a single-file PyQt5 desktop app (`app.py`). It is the working reference.
- `MediaFlow_Mobile/` is a Flutter Android app with a Python backend embedded via Chaquopy (`android/app/src/main/python/mediaflow_core.py`).
- The Flutter app is a regression from the pre-Flutter Java app. Do not assume desktop parity or trust its current behavior.
- Agreed rebuild direction: one Flutter app, Windows + Android. Specs live in `specs/001-rebuild/`; the rebuild app is scaffolded in `apps/mediaflow/`. Do not move or rewrite `app.py` or `MediaFlow_Mobile/`.
- CI is `.github/workflows/release.yml`, triggered by `v*` tags. The Android leg now builds with Flutter on `MediaFlow_Mobile`; verify it on the next tag.

## Rebuild direction
- Product target: local-first multi-source downloader for Windows and Android. Read `specs/001-rebuild/README.md` first, then `product-spec.md`, `source-matrix.md`, `architecture.md`, `design-system.md`, `tasks.md`, and `decisions.md`.
- UX reference: [anything.rip](https://anything.rip/). Use it only to validate the interaction model; do not copy its code, branding, or assets.
- v1 sources: YouTube, TikTok, Facebook, Instagram, Kick, Twitch, SoundCloud, Google Drive link-shared, direct HTTP, HLS/DASH, and generic yt-dlp hosts. Mega/Gofile are later; torrents and DRM services are out.
- Content boundary: link-shared/public or user-authorized content only. Never bypass DRM, paywalls, private-account controls, owner-disabled downloads, or Workspace policy. A missing Drive download button is not a block; a sign-in-required, owner-disabled, or policy-blocked file is a terminal per-file error.
- Google Drive is link-shared only: no Google sign-in, OAuth, API key, or account token. Do not add `google_sign_in`, `googleapis`, or OAuth client setup.
- Batch failures are isolated: show the item name, original link, and localized reason, skip the item, continue the rest, and show an end-of-batch summary with retry-failed.
- Sample URLs supplied for acceptance are private notes only. Do not commit them, downloaded media, cookies, or account secrets. Automated tests use recorded JSON/HTML and fake engines.
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

Rebuild app (`apps/mediaflow`):
```powershell
cd apps\mediaflow
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
# Windows requires a Visual Studio C++ toolchain:
flutter build windows --debug
```
APK output: `apps\mediaflow\build\app\outputs\flutter-apk\app-debug.apk`.

The rebuild has the Phase 2 fake-engine vertical slice plus a Phase 3 Windows yt-dlp bridge and link-shared Drive HTTP support. `createDefaultSourceAdapter()` keeps the `example.com` and `demo-mixed` sample links on the offline fake adapter, routes valid public Drive links to `DriveSourceAdapter` (public folder HTML, recursive expansion, direct downloads, the confirmation form, and Docs/Sheets/Slides export), and uses the real engine for other URLs when `EnginePaths` finds `yt-dlp.exe`. Drive folders open a selection sheet with per-file checkboxes, Download selected, Download all, and blocked rows; unsupported native types and recursion-limit entries become skipped summary items. ZIP/ZIP64 is not implemented yet. Drive uses Dart `HttpClient`; no OAuth, account token, or Google API package. Automated tests use recorded HTML and a fake HTTP transport. The live `embeddedfolderview` endpoint has not been verified here (a research request returned 401), so test with an authorized public link before calling Drive acceptance complete. Search order for yt-dlp: `MEDIAFLOW_YTDLP`, the working directory, the app directory, then a `tools` folder beside either. FFmpeg uses `MEDIAFLOW_FFMPEG` and the same layout. Binaries are gitignored and currently absent here, so no real download has run. The Windows runner still cannot be built because this machine has no Visual Studio C++ toolchain; the Android debug APK builds. `MaterialApp.locale` is pinned to English until `flutter_localizations`/ARB is approved; the app strings and `Directionality` still switch to Arabic. Do not claim Windows runtime verification until the toolchain is installed and a manual download succeeds.

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
- `apps/mediaflow` uses `com.mediaflow.app`; if you change the Android namespace, keep `android/app/build.gradle.kts`, the `MainActivity.kt` package/path, and the manifest aligned. The scaffold's `MainActivity` lives at `android/app/src/main/kotlin/com/mediaflow/app/MainActivity.kt`.
- The rebuild Android debug build succeeds; the Windows runner cannot be built on this machine without the Visual Studio C++ toolchain. Do not mark the Windows leg verified until it builds and runs.
- The rebuild `MaterialApp.locale` is pinned to English because `flutter_localizations` is not added yet. Arabic UI text and `Directionality` work, but Material's own localization strings stay English until ARB/gen-l10n is approved.
- `.editorconfig` says 4-space indent, but Dart is formatted by `dart format` (2 spaces). Do not hand-indent Dart to 4.
- Root `README.md` has mojibake and stale details; `MediaFlow_Mobile/README.md` is the default Flutter template. Trust code and config.
- Desktop state lives outside the repo: `~/.ytflow2_config.json` and `~/.ytflow2_history.json`. Never commit them.
- `requirements.txt` uses `yt-dlp[default]`; mobile uses plain `yt-dlp` because Chaquopy cannot install the extra deps. Keep that split unless verified.

## Architecture notes
- Desktop: `build_ydl_opts()` is the single yt-dlp option builder; `DownloadPage._download_worker()` runs it on a thread and sends UI updates through `WorkerSignals`. `yt_dlp` is lazy-imported, so the first Analyse is slow by design.
- Mobile: `YtdlpService` wraps the MethodChannel/EventChannel; `PythonBridge.kt` starts Chaquopy and calls `mediaflow_core.py`. `l10n.dart` is a manual en/ar string map, not ARB/gen-l10n. `lib/services/download_contract.dart` holds the pure progress/result helpers and their tests.
- Correct pre-Flutter behavior is in git history: `git show 81008d4^:Videos_Downloader_Mobile/app/src/main/java/com/mediaflow/android/MainActivity.java`. It scales `percent*1000`, reads `downloaded_files`, and scans real files for play/share/delete.
- `hooks/hook_ffmpeg_path.py` puts bundled FFmpeg on PATH at runtime.
- Rebuild: `apps/mediaflow/lib/state/app_state.dart` owns the in-memory queue, scheduler, retries, and batch summaries. `CompositeSourceAdapter` routes the demo URLs to `FakeSourceAdapter` and other http(s) URLs to `YtDlpSourceAdapter` when the engine exists; `OutputDirectoryAware` forwards Settings changes into the engine. Tests inject zero-delay fakes or fake processes and never use live URLs. The app uses built-in `ChangeNotifier`/`InheritedNotifier`, not `provider`.
- Rebuild engine: `lib/engine/ytdlp/` holds the command builder, JSON/progress parser, error mapper/redaction, process abstraction, and `YtDlpEngine`. `--print` implies simulation, so the download args must keep `--no-simulate`; removing it turns downloads into metadata-only runs. YouTube playlists are rejected until collection expansion lands; do not return a fake collection from a single probe.

## Rules
- Commit and push each completed step to `origin/main`; do not leave finished work sitting only in the worktree.
- Do not rewrite or delete `app.py` during the rebuild; it is the reference. Keep rescue fixes separate from rebuild work.
- New Android work targets `youtubedl-android`; do not add another Chaquopy/Python runtime.
- Do not add `MANAGE_EXTERNAL_STORAGE`; plan MediaStore/SAF instead.
- No live URLs or real downloads in automated tests. Use recorded yt-dlp JSON and a fake executable.
- Never log cookies, signed URLs, or tokens; never commit `cookies.txt`.
- Keep user-facing strings localized; for the rescued app add them to `l10n.dart`; for the rebuild use `AppStrings` until ARB/gen-l10n is approved.
- Ask before adding a dependency and record accepted/proposed decisions in `specs/001-rebuild/decisions.md`.
- Never add bypass logic for DRM, paywalls, private accounts, owner-disabled Google Drive downloads, or Workspace policy. Explain the restriction and offer an authorized path. For link-shared Drive with no download button, use the public listing/file flow; do not add OAuth.
- Keep batch failures isolated and summarized. Do not let one failed item stop the rest.
- Verify with the commands above and report the output. Do not claim a build or fix without running it.
- PyQt5 is GPL/commercial; check licensing before distributing a Python desktop build.

## Before finishing
- `flutter analyze` is clean.
- `flutter test` passes.
- `flutter build apk --debug` succeeds if Android code changed. The rescue build produced `build/app/outputs/flutter-apk/app-debug.apk` but has not been installed or run on a device/emulator.
- Rebuild app: run `flutter analyze`, `flutter test`, and `flutter build apk --debug` from `apps/mediaflow`. A Windows build needs the Visual Studio C++ toolchain; state that it could not be run if it is missing.
- `python app.py` starts if desktop code changed, or state why it could not be run.
- Update this file if you discover a new trap.
