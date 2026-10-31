# Project review and native migration

Review date: 2026-10-31. Local Git HEAD at the start: `9855eeb`. The migration retains the original history. The native beta release uses `release/native-v2.0.0-beta.1`, preserving the separate, newer Flutter rebuild on remote `main`.

## What the history showed

| Commit | Finding |
| --- | --- |
| `35567c2` | Earlier Windows and native Java Android work existed together. |
| `f08838b` (`v1.0.0`) | Last revision before Flutter; the older Android Activity was a large Java file. |
| `81008d4` | Replaced Android Java UI with Flutter, keeping a Python/Chaquopy bridge. Windows stayed Python/PyQt. |
| `9855eeb` | Renamed `Videos_Downloader_Mobile` to `MediaFlow_Mobile`; it contained no functional code changes. Release paths were not updated. |

The starting worktree already had Android edits and two deleted Windows helper files. Original Android working sources, including those edits, are preserved in ignored `local-backups/before-native-migration.zip`. The old deleted Windows helper files were not restored. A new Windows build helper has its own filename.

The provider source was intact. An initially truncated shell read made it appear incomplete; comparison with Git and direct file reads corrected that finding.

## Implemented architecture

- Windows retains PyQt and yt-dlp, with a simpler source area, original-file mode, dedicated Drive folder handling, saved final paths, safe persistence, and actionable error categories.
- Android replaces Flutter/Chaquopy with native Kotlin views and an Android yt-dlp wrapper. Its packaged Python/QuickJS/FFmpeg runtimes avoid executing an extracted FFmpeg asset from writable app storage.
- Android network and media operations run on workers. A foreground service owns queued downloads; the Activity observes persisted job state.
- Original-file transfers use partial files and finalize only after checking the response length when available. Existing completed files are preserved. Windows validates server identity/ranges before resuming.
- Drive folder enumeration uses the public embedded folder view and recurses into visible subfolders. Downloads retain folder structure and stable item IDs in names. In Video/Audio mode, a refused original can fall back to an available playback stream. Original file mode reports the refusal. Neither path saves an HTML error page as a file.
- Release paths, Gradle launchers and build scripts now target the native Android project. Windows bundles a JavaScript runtime and EJS scripts for current YouTube extraction.

Error categories include invalid input, network interruption, rate limits, login required, access denied, unavailable content, storage/permission failures, missing media formats, processing/runtime failures, DRM, and unsupported links. User-visible diagnostic URLs have query strings redacted. Original account cookies are never required in chat.

## Supplied-link checks

The 18 supplied URLs are preserved locally in ignored `tests/source_urls.txt`. Sharing links are not committed. Anonymous metadata checks and folder listings succeeded for **15/18**. This count verifies access/extraction/listing, not complete downloads of every item.

| Source | Supplied examples | Result |
| --- | --- | --- |
| TikTok | 1 video | Metadata OK; five-second video+audio download passed. |
| Facebook | Video, reel, live URL | All metadata OK; five-second reel video+audio download passed. |
| YouTube | Short, live URL, watch URL, shortened URL | All metadata OK; five-second Short video+audio download passed. |
| Instagram | 2 reels | Anonymous extraction requested account cookies/rate-limit recovery. Not claimed as working without login. |
| Google Drive | 1 file, 2 folders | File metadata OK. Dedicated folder handler listed 2 and 31 top-level entries respectively. Full folder contents were not downloaded. |
| Kick | Clip and VOD | Clip metadata OK. Supplied VOD returned HTTP 404. |
| Twitch | Clip and VOD | Both metadata OK. |
| SoundCloud | 1 track | Metadata OK. |

The initial yt-dlp Drive folder path failed internally. The dedicated public-folder handler fixed listing for both examples. The second folder refused an original MP4 but exposed 7 playable formats; this is the playback fallback case tested separately. Private folders, resource-key-only shares, restricted documents and very large folder listings may still require additional account/API integration. Missing a button is not enough to determine whether an original file is downloadable.

The media sample checks used the desktop download options and FFprobe. A five-second playback sample from the restricted-original Drive folder also passed with both video and audio (124404 bytes). YouTube: 5.03 seconds, 115186 bytes; Facebook: 5.04 seconds, 89766 bytes; TikTok: 5.05 seconds, 966216 bytes. All had video and audio. No full live stream or complete folder was downloaded during these checks.

The APK also downloaded the supplied YouTube Short at 360p while the Activity was in the background: 35.02 seconds, 803818 bytes, with both video and audio confirmed by FFprobe.

The APK was launched in a headless, read-only API 34 emulator session. Sharing a URL into the app, queuing a synthetic 1 MiB file, saving it and matching its SHA-256 checksum were verified. The test device's existing persistent data was not modified. The final native Drive folder preview, light mode, Arabic navigation, and preservation of Settings across theme/language recreation also passed. Twelve Python checks, three Android checks and Android lint passed. APK build, Android unit tests and lint are also run separately; final local reports live under `build/` and `MediaFlow_Mobile/android/app/build/reports/`.

## Still outside this release

- MEGA encrypted file/folder links and WeTransfer share pages.
- Full Dropbox folder traversal, GitHub directory browsing, and authenticated Drive OAuth / shared-drive pagination.
- A graceful live-recording Stop-and-finalize workflow; cancellation currently preserves partials, and Android background limits still apply.
- Equivalent batch queue UI on Windows, production APK signing, desktop in-app engine updates, and complete translation of technical diagnostics.
- Broad real-device coverage, including 16 KB page-size Android devices. An emulator check is not a substitute for installation on the user's phone.

No blanket guarantee is made for all extractors. Each additional file host needs its own handler and regression examples. The first priority remains YouTube, Facebook, Instagram and original file URLs, as selected by the user.

## References

- [yt-dlp supported extractors](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md)
- [yt-dlp JavaScript runtime setup](https://github.com/yt-dlp/yt-dlp/wiki/EJS)
- [Native Android engine](https://github.com/yausername/youtubedl-android)
- [Android restrictions on executing writable files](https://developer.android.com/about/versions/10/behavior-changes-10#execute-permission)
- [Android foreground service types and constraints](https://developer.android.com/develop/background-work/services/fgs/service-types#data-sync)
- [Google Drive download capabilities](https://developers.google.com/workspace/drive/api/guides/manage-downloads)
