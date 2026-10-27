# MediaFlow (Flutter rebuild)

One local-first multi-source downloader for Windows and Android. This is the
rebuild app; the PyQt5 root app and the rescued `MediaFlow_Mobile/` app remain
as references.

## Current state

Phase 2 vertical slice plus the Windows and Android yt-dlp bridges and
link-shared Google Drive HTTP support:

- Analyze → Queue → Library → Settings shell.
- Studio Dark, Light, and OLED themes.
- English/Arabic UI with an RTL toggle.
- Batch intake (one link per line), Video/Audio for the whole batch.
- Per-item failure cards, continue-on-error, and an end-of-batch summary with
  retry-failed and copy-failed-links.
- Windows yt-dlp.exe + FFmpeg support when the binaries are present.
- Android yt-dlp + FFmpeg through the pinned `youtubedl-android` runtime, with
  probe/download/cancel, shared progress and error parsing, and app-specific
  output storage.
- Link-shared Google Drive file/folder listing over public HTML, recursive
  folder expansion, direct downloads, the public confirmation form, and
  Docs/Sheets/Slides export as PDF/XLSX/PPTX.
- Drive folder selection sheet with per-file checkboxes, select all/none,
  Download selected, Download all, Download as ZIP, and blocked rows that cannot
  be selected.
- Known selection totals and free space are shown in the sheet. A low-space
  confirmation appears when the selected payload (or roughly twice that for ZIP
  staging) exceeds free space.
- Android defaults to the app-specific external downloads folder
  (`Android/data/com.mediaflow.app/files/Download/MediaFlow`) through a native
  method channel; Windows uses `%USERPROFILE%\Downloads\MediaFlow`. No broad
  storage permission is requested.
- Folder ZIP/ZIP64 archives built from successful files only. Failed or skipped
  entries keep their item name, link, and localized reason in the batch summary.
- Unsupported native types and recursion-limit skips are reported in the batch
  summary instead of being silently dropped.
- SQLite persistence through Drift for the queue, completed file paths, per-item
  errors, ZIP entry/skip lists, and batch summaries. The database lives in
  application-support storage, not the output folder.
- On startup, interrupted downloads return to the queue and auto-start; probing
  rows are discarded. Progress writes are throttled to about once per second.
- No Google sign-in, OAuth, API key, or Google API package.

The Android engine bridge compiles and is covered by fake-gateway tests, but it
has not been installed or run on a device/emulator. The foreground service,
progress notification, cookies, and MediaStore/SAF are still pending. The ZIP
writer was opened successfully with Windows .NET `ZipFile` in this environment;
Android extraction is still unverified. The Windows runner and live endpoints
have not been manually verified here because the Visual Studio C++ toolchain,
engine binaries, and an authorized live sample are unavailable.

## Run

```powershell
cd apps/mediaflow
flutter pub get
# only after changing a Drift table; the generated file is committed
dart run build_runner build
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
  recursive expansion, ZIP staging/download, and download adapter.
- `lib/zip/` — dependency-free Store-method ZIP/ZIP64 writer with CRC-32,
  progress, and cancellation.
- `lib/platform/` — default output directory, free-space probe, and the Android
  `com.mediaflow.app/platform` method-channel bridge.
- `lib/engine/ytdlp/` — shared `DownloadEngine` contract, yt-dlp command
  builder, parser, process bridge, desktop engine, and Android method-channel
  engine/gateway.
- `lib/storage/` — Drift database, repository, and JSON codecs for queue/history.
- `lib/state/app_state.dart` — queue scheduler, retry, batch summary, and
  persistence integration.
- `lib/screens/` — Analyze, Queue, Library, Settings.
- `lib/widgets/` — shared cards, job tiles, batch summary.

## Known scaffold notes

- Material's own localizations stay on English until `flutter_localizations` and
  ARB/gen-l10n are approved. The app strings and `Directionality` still switch to
  Arabic; Material widgets such as text-field context menus remain English.
- Tests use only the fake adapter, a fake Drive HTTP transport, recorded HTML,
  and zero-delay timers. They never use live URLs.
- The current public folder parser does not obtain per-file sizes, so real
  folder totals remain unavailable and low-space confirmation only applies when
  an adapter supplies every selected `sizeBytes`.
- The Android default-output, free-space channel, and SQLite database compile
  into the debug APK but have not been run on a device or emulator. MediaStore/SAF
  output and a restart on a real device are still pending.
- The Android engine adds `youtubedl-android` 0.18.1 and its FFmpeg artifact.
  The debug APK carries three ABIs plus zipped Python/FFmpeg payloads, so it is
  large; release ABI splits are pending. First use extracts the runtime, and the
  first download also extracts FFmpeg. No foreground service/notification is
  implemented yet, so backgrounding can stop a download. Cancellation kills the
  tracked yt-dlp process; child-process cleanup is not verified.
- The database is `mediaflow.sqlite` in application-support storage. Schema v1
  has `jobs` and `batch_summaries`; future schema changes need a Drift migration.
- A ZIP job interrupted by an app kill requeues, but its hidden
  `.mediaflow_zip_*` staging folder is not cleaned on the next startup. Add
  startup cleanup before calling ZIP restart acceptance complete.
- The app ID is `com.mediaflow.app`; Android `minSdk` is 24.
