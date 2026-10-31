# MediaFlow Android

Native Kotlin Android application. Open `android/` in Android Studio. Flutter and Dart are no longer used. Run the helper from `MediaFlow_Mobile/`:

```powershell
.\build_debug_apk.ps1
```

Alternatively, build and verify directly from the native Gradle project:

```powershell
cd android
.\gradlew.bat :app:assembleDebug :app:testDebugUnitTest :app:lintDebug
```

Installable debug APK, relative to `MediaFlow_Mobile/`: `android/app/build/outputs/apk/debug/app-debug.apk`. The helper also accepts `-Clean`. A convenience copy at `../dist/MediaFlow-Android.apk` is separate and must be refreshed after rebuilding.

The UI is a native Activity with dark/light themes, English/Arabic resources, a sequential queue, preview, settings and history. `DownloadService` owns background transfers and cancellation. `DownloadEngine` wraps the packaged yt-dlp runtime for media and streams original files directly. `DriveFolders` handles public folder enumeration. `DownloadStore` persists jobs atomically and attempts migration of old Flutter preferences without deleting them.

The native engine dependencies include Python, yt-dlp, QuickJS, FFmpeg and FFprobe. There is no Chaquopy build-Python path. SDK 36, JDK 17+, Gradle 8.14, AGP 8.10.1, Kotlin 2.1.21; ARM64 and x86_64; minimum API 24.

Set `JAVA_HOME` and `ANDROID_HOME` if automatic SDK/JDK discovery does not match your machine. Keep any local SDK path in ignored `android/local.properties`. On Linux, run `chmod +x gradlew` and use `./gradlew` from `android/`.

Files are stored in app-specific storage. History provides Open, Share and Export. Export files before uninstalling. Import Netscape-format cookies through Settings for account-required links. Some explanatory/technical diagnostic messages remain in English in Arabic mode.

This output uses debug signing. Production updates need a stable private signing key matching the installed app. Keystores, signing properties, APKs/AABs, and build caches stay out of version control; the Gradle wrapper scripts, JAR, and properties belong in the repository.

[Repository documentation](../README.md) includes source capabilities, installation, verification and known limitations. [Project review](../docs/project-review.md) records the migration and supplied-link checks.
