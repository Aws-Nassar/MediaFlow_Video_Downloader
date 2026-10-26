/// Pure helpers for the Python <-> Flutter download contract.
///
/// Keep these free of platform channels so they can be unit tested without a
/// device or a running backend.
library;

/// Normalizes backend progress to a `0.0..1.0` fraction.
///
/// The Python backend emits `0..1` (yt-dlp's native scale), but older callers
/// may emit `0..100`. Accept both and clamp invalid values.
double normalizePercent(dynamic value) {
  final raw = switch (value) {
    num n => n.toDouble(),
    String s => double.tryParse(s) ?? 0.0,
    _ => 0.0,
  };
  if (raw.isNaN || raw.isInfinite) return 0.0;
  final fraction = raw > 1.0 ? raw / 100.0 : raw;
  return fraction.clamp(0.0, 1.0);
}

/// Extracts downloaded file paths from a backend result.
///
/// The current backend returns `downloaded_files` (a list). `file_path` is
/// accepted as a compatibility alias for older or partial responses.
List<String> extractDownloadedFiles(Map<String, dynamic> result) {
  final files = <String>[];

  final rawFiles = result['downloaded_files'];
  if (rawFiles is List) {
    for (final item in rawFiles) {
      if (item is String && item.trim().isNotEmpty) {
        files.add(item);
      }
    }
  }

  if (files.isEmpty) {
    final single = result['file_path'] ?? result['filepath'];
    if (single is String && single.trim().isNotEmpty) {
      files.add(single);
    }
  }

  return files;
}
