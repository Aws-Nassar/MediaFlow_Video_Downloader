import '../../models/media_models.dart';
import 'ytdlp_markers.dart';

/// Builds deterministic yt-dlp command lines.
///
/// The app always passes `--ignore-config` so a user's global yt-dlp config
/// cannot inject unexpected flags into a download.
abstract final class YtDlpCommandBuilder {
  static const outputTemplate = '%(title).120B [%(id)s].%(ext)s';

  static List<String> probeArgs(
    Uri uri, {
    Duration socketTimeout = const Duration(seconds: 20),
  }) {
    return [
      '--ignore-config',
      '--dump-single-json',
      '--no-warnings',
      '--no-playlist',
      '--socket-timeout',
      '${socketTimeout.inSeconds}',
      '--',
      uri.toString(),
    ];
  }

  static List<String> downloadArgs({
    required Uri uri,
    required DownloadType downloadType,
    required String outputDirectory,
    String? ffmpegPath,
    bool? ffmpegAvailable,
    int retries = 3,
    Duration socketTimeout = const Duration(seconds: 20),
  }) {
    final safeRetries = retries.clamp(0, 10);
    final hasFfmpeg =
        ffmpegAvailable ?? (ffmpegPath != null && ffmpegPath.trim().isNotEmpty);
    final hasLocation = ffmpegPath != null && ffmpegPath.trim().isNotEmpty;

    return [
      '--ignore-config',
      '--newline',
      '--no-warnings',
      '--progress',
      '--no-simulate',
      '--no-playlist',
      '--windows-filenames',
      '--socket-timeout',
      '${socketTimeout.inSeconds}',
      '--retries',
      '$safeRetries',
      '--fragment-retries',
      '$safeRetries',
      '--progress-template',
      'download:${YtDlpMarkers.progress} %(progress)j',
      '--print',
      'after_move:${YtDlpMarkers.file} %(filepath)s',
      '-P',
      outputDirectory,
      '-o',
      outputTemplate,
      if (hasLocation) ...['--ffmpeg-location', ffmpegPath],
      if (downloadType == DownloadType.audio) ...[
        '-f',
        'ba/b',
        '--extract-audio',
        '--audio-format',
        'm4a',
        '--audio-quality',
        '0',
      ] else ...[
        '-f',
        hasFfmpeg ? 'bv*+ba/b' : 'best[acodec!=none][vcodec!=none]',
      ],
      '--',
      uri.toString(),
    ];
  }
}
