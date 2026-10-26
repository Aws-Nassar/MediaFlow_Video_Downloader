# MediaFlow (Flutter rebuild)

One local-first multi-source downloader for Windows and Android. This is the
rebuild app; the PyQt5 root app and the rescued `MediaFlow_Mobile/` app remain
as references.

## Current state

Phase 2 vertical slice plus the Windows yt-dlp bridge and link-shared Google
Drive HTTP support:

- Analyze → Queue → Library → Settings shell.
- Studio Dark, Light, and OLED themes.
- English/Arabic UI with an RTL toggle.
- Batch intake (one link per line), Video/Audio for the whole batch.
- Per-item failure cards, continue-on-error, and an end-of-batch summary with
  retry-failed and copy-failed-links.
- Windows yt-dlp.exe + FFmpeg support when the binaries are present.
- Link-shared Google Drive file/folder listing over public HTML, recursive
  folder expansion, direct downloads, the public confirmation form, and
  Docs/Sheets/Slides export as PDF/XLSX/PPTX.
- In-memory state only. No persistence.
- No new packages beyond the Flutter SDK and the generated lint/test tooling.
- No Google sign-in, OAuth, API key, or Google API package.

The Drive selection sheet, ZIP/skipped-file report, SQLite history, and the
Android engine bridge are next. The Windows runner and live endpoints have not
been manually verified here because the Visual Studio C++ toolchain, engine
binaries, and an authorized live sample are unavailable.

## Run

```powershell
cd apps/mediaflow
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

APK: `build/app/outputs/flutter-apk/app-debug.apk`.

Windows requires a Visual Studio C++ toolchain:

```powershell
flutter build windows --debug
```

It is not available in the current environment, so the Windows runner has not
been built yet.

## Demo behavior

The fake adapter accepts `http(s)` links. In debug builds the Analyze screen
shows a demo-batch button:

- `https://example.com/video/1` succeeds.
- `https://example.com/cookies` simulates a login-required failure.
- `https://drive.google.com/drive/folders/demo-mixed` simulates a 3-item folder;
  item 2 is owner-disabled.

These are fake URLs for the scaffold; they are not live test cases. Automated
tests inject zero-delay fakes and never download anything.

## Layout

- `lib/theme/studio_theme.dart` — palette, Material theme, OLED variant.
- `lib/models/media_models.dart` — jobs, descriptors, errors, summaries.
- `lib/sources/` — adapter contract, registry, fake adapter.
- `lib/drive/` — public Drive link parsing, folder HTML, HTTP transport,
  recursive expansion, and download adapter.
- `lib/engine/ytdlp/` — yt-dlp command, parser, process, and engine bridge.
- `lib/state/app_state.dart` — in-memory queue, retry, batch summary.
- `lib/screens/` — Analyze, Queue, Library, Settings.
- `lib/widgets/` — shared cards, job tiles, batch summary.

## Known scaffold notes

- Material's own localizations stay on English until `flutter_localizations` and
  ARB/gen-l10n are approved. The app strings and `Directionality` still switch to
  Arabic; Material widgets such as text-field context menus remain English.
- Tests use only the fake adapter, a fake Drive HTTP transport, recorded HTML,
  and zero-delay timers. They never use live URLs.
- The app ID is `com.mediaflow.app`; Android `minSdk` is 24.
