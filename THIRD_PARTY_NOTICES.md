# Third-party notices

MediaFlow's source code is available at:

https://github.com/Aws-Nassar/MediaFlow_Video_Downloader

Release source archives are attached automatically by GitHub Releases.

## yt-dlp

- Project: https://github.com/yt-dlp/yt-dlp
- Version bundled in Windows builds: 2026.10.26
- License: Unlicense
- Source for the bundled release: https://github.com/yt-dlp/yt-dlp/releases/tag/2026.10.26

## FFmpeg

- Project: https://ffmpeg.org/
- Windows binary source: https://github.com/BtbN/FFmpeg-Builds
- Build used: `ffmpeg-n8.1-latest-win64-gpl-8.1`
- License: GPL-3.0-or-later for this GPL build
- Source code: https://github.com/FFmpeg/FFmpeg

The Android build supplies FFmpeg through `youtubedl-android`.

## youtubedl-android

- Project: https://github.com/yausername/youtubedl-android
- Maven coordinates: `io.github.junkfood02.youtubedl-android:library:0.18.1`
  and `io.github.junkfood02.youtubedl-android:ffmpeg:0.18.1`
- License: GPL-3.0
- Source code: https://github.com/yausername/youtubedl-android

The Android APK includes this runtime and its FFmpeg payload. The corresponding
source is available from the project links above and from the release source
archive.

## Flutter and Dart packages

The rebuild uses Flutter and third-party Dart packages listed in
`apps/mediaflow/pubspec.lock`. Their license texts are available from their
respective package repositories.

## Content boundary

MediaFlow is intended for link-shared/public content or content the user is
authorized to download. It does not bypass DRM, paywalls, private-account
controls, owner-disabled downloads, or Workspace policy.
