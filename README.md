# MediaFlow

Windows EXE and native Kotlin Android APK for media and file downloads. The Android build no longer requires Flutter, Dart, Chaquopy, or a machine-specific Python installation.

## Build outputs

| App | Build output |
| --- | --- |
| Windows | `dist/MediaFlow.exe` |
| Android | `MediaFlow_Mobile/android/app/build/outputs/apk/debug/app-debug.apk` |

The current Android APK is also available locally as `dist/MediaFlow-Android.apk`. The Android build script writes to the Gradle output above; it does not refresh this convenience copy. Built packages are ignored by Git. Installed apps do not require development tools.

## Current capabilities

- Video and audio links through yt-dlp: YouTube videos, Shorts and streams; Facebook videos and reels; Instagram with account cookies when required; TikTok, Twitch, Kick, SoundCloud, and other extractors.
- Original HTTP/HTTPS files, including archives, documents and images. Select **Original file** for links that do not look like ordinary media URLs.
- GitHub raw files and release assets; GitHub blob links and Dropbox shared files in Original file mode.
- Public Google Drive folders, including nested folders, original files, and PDF/XLSX/PPTX exports of supported Google documents. When an original video is refused but a playback stream is available, Video/Audio mode can save that stream. Original file mode does not substitute playback copies. Access restrictions still apply.
- Clean dark and light interfaces. Android retains English and Arabic navigation, RTL, a background download queue, share-to-app, cookie import, Open/Share/Export, and recovery of interrupted jobs.
- Actionable error categories, bounded retries, cancellation, safe filenames, atomic history storage, and redacted diagnostic details.

Support depends on the source and the link. An extractor existing is not a guarantee that every post is downloadable. MEGA encrypted shares, WeTransfer share pages, full Dropbox folder traversal, and account-based Drive OAuth are **not implemented** in this first native release.

See [the project review and validation report](docs/project-review.md) for Git history findings, verified examples, and remaining work. Your local test URLs are in ignored `tests/source_urls.txt`; sharing links are not committed.

## Windows

Run these commands from the repository root. On a new checkout, create the virtual environment first; reuse `.venv` if it already exists:

```powershell
py -3 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements-dev.txt
python app.py
```

Activation is optional when using the virtual environment's Python directly:

```powershell
.\.venv\Scripts\python.exe -m pip install -r requirements-dev.txt
.\.venv\Scripts\python.exe app.py
```

FFmpeg and FFprobe must be available in `tools/`, on PATH, or configured in Settings. YouTube challenge solving also uses Deno; the build helper can obtain it from its official GitHub release.

```powershell
.\tools\build_windows.ps1 -InstallDependencies -DownloadRuntime
```

Output: `dist/MediaFlow.exe`. FFmpeg, FFprobe, Deno, and yt-dlp EJS data are bundled. The build helper checks required runtimes; portable end users do not install Python.

Once the dependencies and runtimes are available, PyInstaller can also be invoked directly:

```powershell
.\.venv\Scripts\python.exe -m PyInstaller --noconfirm MediaFlow.spec
```

The direct command does not download or check required runtimes; use the helper for those checks.

Source runs use `tools/deno.exe` when present. On Linux, install FFmpeg/FFprobe and Deno, install Python requirements, and run `python app.py` or `python -m PyInstaller MediaFlow.spec`.

Desktop preferences and history remain in `~/.ytflow2_config.json` and `~/.ytflow2_history.json`. They are personal state and are not committed. Updating the engine in a packaged EXE currently requires a rebuild.

## Android

Open **MediaFlow_Mobile/android/** in Android Studio, or run:

```powershell
cd MediaFlow_Mobile
.\build_debug_apk.ps1
```

Or use Gradle directly:

```powershell
cd MediaFlow_Mobile/android
.\gradlew.bat :app:assembleDebug :app:testDebugUnitTest :app:lintDebug
```

Output: `MediaFlow_Mobile/android/app/build/outputs/apk/debug/app-debug.apk`.

Build prerequisites: JDK 17 or newer, Android SDK platform 36, and internet access for Maven/Gradle dependencies. `JAVA_HOME` and `ANDROID_HOME` can override local discovery. Gradle 8.14, AGP 8.10.1 and Kotlin 2.1.21 are pinned. ARM64 phones and x86_64 emulators are supported; minimum Android is 7.0/API 24. yt-dlp, Python, QuickJS, FFmpeg and FFprobe are supplied by the native Android engine libraries.

The APK is a directly installable **debug** build. A stable private signing key must be configured separately before publishing production updates. APK signing must match the previous installation to preserve its data during an upgrade.

Downloads stay in app-specific storage, which is removed on uninstall. Use **History > Export** to save copies elsewhere. Cookies stay in private storage, are excluded from Android backup, and can be removed in Settings. Android tries to import the previous Flutter app's history, theme, language and cookie file when upgraded under the same package and signing key.

Background jobs use a foreground notification and run outside the UI thread. Android may stop jobs for system resource or background-time limits; interrupted jobs can be retried. Media partials resume where the source permits. Direct files currently restart on Android retry; Windows direct files resume only when server validators and byte ranges match. Cancellation leaves partial files and does not promise a finalized playable live recording.

## Verification

Offline transfer and error checks:

```powershell
.\.venv\Scripts\python.exe -m unittest discover -s tests -v
```

Create a local `tests/source_urls.txt` with one URL per line (or pass `--input`). Anonymous metadata/folder checks do not download full videos:

```powershell
.\.venv\Scripts\python.exe tools/check_sources.py
```

Five-second YouTube/Facebook/TikTok downloads, with FFprobe checking for video and audio:

```powershell
.\.venv\Scripts\python.exe tools/check_media_downloads.py
```

Use `tools/check_media_downloads.py --drive-only` to check a playback sample from the last Drive folder in the local input file. These media checks require FFmpeg and FFprobe on PATH and make network requests.

The Android verification helpers require an installed APK on an **isolated emulator** and an ADB executable supplied with `--adb`:

| Helper | Check |
| --- | --- |
| `tools/check_native_apk.py` | Synthetic file download with SHA-256 verification |
| `tools/check_native_media.py` | Short video download while the app is in the background |
| `tools/check_native_ui.py` | Drive folder preview, light mode, and Arabic navigation |

Reports and sample files are written under ignored `build/`. Automated CI validates local transfers and the Android build. Tag releases continue to build Windows, Linux and Android artifacts using the new native Android paths.

## Project layout and local files

| Path | Purpose |
| --- | --- |
| `app.py` | Desktop UI and media download options |
| `download_support.py` | Direct-file transfers and error classification |
| `drive_folders.py` | Drive folder discovery and playback fallback |
| `MediaFlow.spec`, `hooks/` | Desktop packaging and runtime discovery |
| `MediaFlow_Mobile/android/` | Native Android Gradle project |
| `tests/`, `tools/` | Offline checks, build helpers, and optional source checks |
| `docs/project-review.md` | Migration review, validation results, and remaining work |

Keep source, resources, tests, and Gradle wrapper scripts/JAR/properties in version control. Build outputs, downloaded runtimes, caches, machine-specific `local.properties`, signing keys/properties, login cookies, personal app state, migration backups, and the local test URL file are ignored.

Some Gradle cache files were tracked in older commits. Adding ignore rules does not untrack those files or rewrite Git history.
