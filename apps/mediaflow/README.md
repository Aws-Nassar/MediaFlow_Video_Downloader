# MediaFlow (Flutter rebuild)

One local-first multi-source downloader for Windows and Android. This is the
rebuild app; the PyQt5 root app and the rescued `MediaFlow_Mobile/` app remain
as references.

## Current state

Phase 2 vertical slice with a fake engine:

- Analyze → Queue → Library → Settings shell.
- Studio Dark, Light, and OLED themes.
- English/Arabic UI with an RTL toggle.
- Batch intake (one link per line), Video/Audio for the whole batch.
- Per-item failure cards, continue-on-error, and an end-of-batch summary with
  retry-failed and copy-failed-links.
- In-memory state only. No network, no real downloads, no persistence.
- No new packages beyond the Flutter SDK and the generated lint/test tooling.

The real Windows `yt-dlp.exe` bridge, link-shared Google Drive listing/ZIP, and
SQLite history are next. There is no Google sign-in, OAuth, or API key.

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
- `lib/state/app_state.dart` — in-memory queue, retry, batch summary.
- `lib/screens/` — Analyze, Queue, Library, Settings.
- `lib/widgets/` — shared cards, job tiles, batch summary.

## Known scaffold notes

- Material's own localizations stay on English until `flutter_localizations` and
  ARB/gen-l10n are approved. The app strings and `Directionality` still switch to
  Arabic; Material widgets such as text-field context menus remain English.
- Tests use only the fake adapter and zero-delay timers.
- The app ID is `com.mediaflow.app`; Android `minSdk` is 24.
