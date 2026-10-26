import 'dart:convert';

import '../../models/media_models.dart';
import '../../sources/source_adapter.dart';
import 'ytdlp_markers.dart';

/// Parses one line of yt-dlp progress JSON.
///
/// The command asks yt-dlp for `--progress-template "download:MF_PROGRESS
/// %(progress)j"`, so the marker can appear after terminal escape codes or
/// other text. Lines without a marker are ignored.
DownloadProgress? parseYtDlpProgressLine(String line) {
  final payload = _markerPayload(line, YtDlpMarkers.progress);
  if (payload == null) return null;

  final data = _decodeObject(payload);
  if (data == null) return null;

  final status = _string(data['status'])?.toLowerCase();
  final downloaded = _int(data['downloaded_bytes']) ?? 0;
  final total =
      _int(data['total_bytes']) ?? _int(data['total_bytes_estimate']) ?? 0;
  final speed = _double(data['speed']);
  final etaSeconds = _double(data['eta']);

  final effectiveDownloaded = status == 'finished' && total > 0
      ? total
      : downloaded;
  final fraction = total > 0
      ? (effectiveDownloaded / total).clamp(0.0, 1.0)
      : (status == 'finished' ? 1.0 : 0.0);

  return DownloadProgress(
    fraction: fraction,
    downloadedBytes: effectiveDownloaded,
    totalBytes: total,
    bytesPerSecond: speed != null && speed > 0 ? speed : null,
    eta: etaSeconds != null && etaSeconds > 0
        ? Duration(seconds: etaSeconds.round())
        : null,
  );
}

/// Parses the final path printed by `--print after_move:MF_FILE %(filepath)s`.
String? parseYtDlpFileLine(String line) {
  final payload = _markerPayload(line, YtDlpMarkers.file);
  if (payload == null) return null;
  var path = payload.trim();
  if (path.length >= 2 && path.startsWith('"') && path.endsWith('"')) {
    path = path.substring(1, path.length - 1).trim();
  }
  return path.isEmpty ? null : path;
}

/// Parses `yt-dlp --dump-single-json` output into the app descriptor.
///
/// Playlist expansion is intentionally not enabled in the single-video slice:
/// returning a collection here would make the queue download the playlist URL
/// once per child. It is better to fail clearly until collection expansion lands.
MediaDescriptor parseYtDlpProbe(
  String stdout, {
  required Uri uri,
  required DownloadType downloadType,
  required bool ffmpegAvailable,
}) {
  final data = _decodeObject(stdout);
  if (data == null) {
    throw const MediaFlowException(
      MediaFlowError(
        code: MediaFlowErrorCode.unknown,
        technicalDetails: 'The engine returned unreadable metadata.',
      ),
    );
  }

  final type = _string(data['_type'])?.toLowerCase();
  final entries = data['entries'];
  if (type == 'playlist' || (entries is List && entries.isNotEmpty)) {
    throw const MediaFlowException(
      MediaFlowError(
        code: MediaFlowErrorCode.unsupportedUrl,
        technicalDetails:
            'Playlist expansion is not enabled in the single-video slice.',
      ),
    );
  }

  final title = _string(data['title'])?.trim();
  final author =
      _string(data['uploader'])?.trim() ?? _string(data['channel'])?.trim();
  final durationSeconds = _double(data['duration']);
  final duration = durationSeconds != null && durationSeconds > 0
      ? Duration(seconds: durationSeconds.round())
      : null;
  final formats = _formats(data['formats']);
  final totalBytes = _estimateTotalBytes(
    formats,
    duration,
    downloadType,
    ffmpegAvailable,
  );

  return MediaDescriptor(
    sourceId: SourceRegistry.sourceIdFor(uri),
    sourceLabel: SourceRegistry.labelFor(uri),
    canonicalUrl: _string(data['webpage_url']) ?? uri.toString(),
    title: title == null || title.isEmpty
        ? SourceRegistry.fallbackTitle(uri)
        : title,
    author: author == null || author.isEmpty ? null : author,
    duration: duration,
    kind: downloadType == DownloadType.audio
        ? MediaKind.audio
        : MediaKind.video,
    totalBytes: totalBytes,
  );
}

String? _markerPayload(String line, String marker) {
  final index = line.indexOf('$marker ');
  if (index < 0) return null;
  return line.substring(index + marker.length + 1).trim();
}

Map<String, dynamic>? _decodeObject(String value) {
  try {
    final decoded = jsonDecode(value);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return null;
  } on FormatException {
    return null;
  }
}

List<Map<String, dynamic>> _formats(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((format) => Map<String, dynamic>.from(format))
      .toList();
}

int? _estimateTotalBytes(
  List<Map<String, dynamic>> formats,
  Duration? duration,
  DownloadType downloadType,
  bool ffmpegAvailable,
) {
  if (formats.isEmpty) return null;

  if (downloadType == DownloadType.audio) {
    final audio = _bestFormat(
      formats.where(_isAudioOnly),
      (format) => _double(format['abr']) ?? _double(format['tbr']) ?? 0,
    );
    final progressive = _bestFormat(
      formats.where(_isProgressive),
      (format) => _double(format['height']) ?? 0,
    );
    final chosen = audio ?? progressive;
    return chosen == null ? null : _estimateFormatBytes(chosen, duration);
  }

  if (ffmpegAvailable) {
    final video = _bestFormat(
      formats.where(_isVideoOnly),
      (format) => _double(format['height']) ?? 0,
    );
    final audio = _bestFormat(
      formats.where(_isAudioOnly),
      (format) => _double(format['abr']) ?? _double(format['tbr']) ?? 0,
    );
    if (video != null && audio != null) {
      final videoBytes = _estimateFormatBytes(video, duration);
      final audioBytes = _estimateFormatBytes(audio, duration);
      if (videoBytes != null && audioBytes != null) {
        return videoBytes + audioBytes;
      }
      if (videoBytes != null) return videoBytes;
      if (audioBytes != null) return audioBytes;
    }
  }

  final progressive = _bestFormat(
    formats.where(_isProgressive),
    (format) => _double(format['height']) ?? 0,
  );
  return progressive == null
      ? null
      : _estimateFormatBytes(progressive, duration);
}

Map<String, dynamic>? _bestFormat(
  Iterable<Map<String, dynamic>> formats,
  double Function(Map<String, dynamic> format) score,
) {
  Map<String, dynamic>? best;
  var bestScore = double.negativeInfinity;
  for (final format in formats) {
    final value = score(format);
    if (value > bestScore) {
      best = format;
      bestScore = value;
    }
  }
  return best;
}

int? _estimateFormatBytes(Map<String, dynamic> format, Duration? duration) {
  final size = _int(format['filesize']) ?? _int(format['filesize_approx']);
  if (size != null && size > 0) return size;
  final bitrate = _double(format['tbr']);
  if (bitrate == null || bitrate <= 0 || duration == null) return null;
  if (duration.inMilliseconds <= 0) return null;
  return (bitrate * 1000 / 8 * duration.inMilliseconds / 1000).round();
}

bool _isProgressive(Map<String, dynamic> format) =>
    _hasVideo(format) && _hasAudio(format);

bool _isVideoOnly(Map<String, dynamic> format) =>
    _hasVideo(format) && !_hasAudio(format);

bool _isAudioOnly(Map<String, dynamic> format) =>
    !_hasVideo(format) && _hasAudio(format);

bool _hasVideo(Map<String, dynamic> format) {
  final codec = _string(format['vcodec'])?.toLowerCase();
  return codec != null && codec.isNotEmpty && codec != 'none';
}

bool _hasAudio(Map<String, dynamic> format) {
  final codec = _string(format['acodec'])?.toLowerCase();
  return codec != null && codec.isNotEmpty && codec != 'none';
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
    return double.tryParse(value)?.round();
  }
  return null;
}

double? _double(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String? _string(Object? value) {
  if (value is String) return value;
  if (value != null) return value.toString();
  return null;
}
