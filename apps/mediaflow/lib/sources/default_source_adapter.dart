import '../engine/ytdlp/engine_paths.dart';
import '../engine/ytdlp/ytdlp_engine.dart';
import '../engine/ytdlp/ytdlp_source_adapter.dart';
import 'composite_source_adapter.dart';
import 'fake_source_adapter.dart';
import 'source_adapter.dart';

/// Builds the adapter used by the running app.
///
/// The sample links stay on the offline demo adapter. Everything else goes to
/// the bundled yt-dlp engine when it is present; if it is absent, unsupported
/// URLs fail honestly instead of being simulated as real downloads.
SourceAdapter createDefaultSourceAdapter({
  String outputDirectory = 'Downloads/MediaFlow',
}) {
  final adapters = <SourceAdapter>[
    FakeSourceAdapter(
      matcher: (uri) {
        if (uri.host == 'example.com') return true;
        return uri.host == 'drive.google.com' &&
            uri.path.contains('demo-mixed');
      },
    ),
  ];

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
