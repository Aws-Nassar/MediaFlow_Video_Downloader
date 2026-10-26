import 'dart:io';

/// Finds the bundled engine binaries without relying on the user's PATH.
///
/// Release packaging should place `yt-dlp.exe` and `ffmpeg.exe` next to the
/// application executable or in a `tools` folder beside it. Development runs
/// can use the repository root or `tools`. Environment overrides make manual
/// testing possible without changing the build layout.
abstract final class EnginePaths {
  static String? findYtDlp() =>
      _find('MEDIAFLOW_YTDLP', Platform.isWindows ? 'yt-dlp.exe' : 'yt-dlp');

  static String? findFfmpeg() =>
      _find('MEDIAFLOW_FFMPEG', Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg');

  static String? _find(String environmentName, String fileName) {
    final override = Platform.environment[environmentName]?.trim();
    if (override != null && override.isNotEmpty) {
      final file = File(override);
      if (file.existsSync()) return file.absolute.path;
      final directory = Directory(override);
      if (directory.existsSync()) {
        final candidate = File(
          '${directory.path}${Platform.pathSeparator}$fileName',
        );
        if (candidate.existsSync()) return candidate.absolute.path;
      }
    }

    final roots = <String>{
      Directory.current.absolute.path,
      File(Platform.resolvedExecutable).parent.absolute.path,
    };
    for (final root in roots) {
      final candidates = [
        File('$root${Platform.pathSeparator}$fileName'),
        File(
          '$root${Platform.pathSeparator}tools'
          '${Platform.pathSeparator}$fileName',
        ),
      ];
      for (final candidate in candidates) {
        if (candidate.existsSync()) return candidate.absolute.path;
      }
    }
    return null;
  }
}
