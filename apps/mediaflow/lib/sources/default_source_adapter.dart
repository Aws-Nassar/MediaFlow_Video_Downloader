import 'dart:io';

import '../drive/drive_http.dart';
import '../drive/drive_source_adapter.dart';
import '../engine/ytdlp/android_engine_gateway.dart';
import '../engine/ytdlp/android_ytdlp_engine.dart';
import '../engine/ytdlp/engine_paths.dart';
import '../engine/ytdlp/ytdlp_engine.dart';
import '../engine/ytdlp/ytdlp_source_adapter.dart';
import 'composite_source_adapter.dart';
import 'fake_source_adapter.dart';
import 'source_adapter.dart';

/// Builds the adapter used by the running app.
///
/// The sample links stay on the offline demo adapter. Valid public Drive links
/// use the link-shared HTTP adapter. On Android, every other http(s) URL goes to
/// the bundled youtubedl-android engine; on desktop it goes to the yt-dlp
/// executable when one is discovered. If the engine is absent, unsupported URLs
/// fail honestly instead of being simulated as real downloads.
SourceAdapter createDefaultSourceAdapter({
  String outputDirectory = 'Downloads/MediaFlow',
  bool? android,
  AndroidEngineGateway? androidGateway,
}) {
  final adapters = <SourceAdapter>[
    FakeSourceAdapter(
      matcher: (uri) {
        if (uri.host == 'example.com') return true;
        return uri.host == 'drive.google.com' &&
            uri.path.contains('demo-mixed');
      },
    ),
    DriveSourceAdapter(
      transport: IoDriveHttpTransport(),
      outputDirectory: outputDirectory,
    ),
  ];

  final isAndroid = android ?? Platform.isAndroid;
  if (isAndroid) {
    adapters.add(
      YtDlpSourceAdapter(
        AndroidYtDlpEngine(
          outputDirectory: outputDirectory,
          gateway: androidGateway,
        ),
      ),
    );
    return CompositeSourceAdapter(adapters);
  }

  final executable = EnginePaths.findYtDlp();
  if (executable != null) {
    adapters.add(
      YtDlpSourceAdapter(
        YtDlpEngine(
          executablePath: executable,
          ffmpegPath: EnginePaths.findFfmpeg(),
          outputDirectory: outputDirectory,
        ),
      ),
    );
  }

  return CompositeSourceAdapter(adapters);
}
