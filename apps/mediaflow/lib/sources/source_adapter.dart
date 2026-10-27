import '../models/media_models.dart';

abstract interface class SourceAdapter {
  String get id;

  bool canHandle(Uri uri);

  Future<MediaDescriptor> probe(Uri uri, {required DownloadType downloadType});

  Stream<DownloadEvent> download(DownloadJob job);

  Future<void> cancel(String jobId);
}

abstract interface class OutputDirectoryAware {
  void setOutputDirectory(String path);
}

abstract interface class EngineInfo {
  bool get isDemoEngine;

  String get engineLabel;
}

sealed class DownloadEvent {
  const DownloadEvent();
}

class DownloadProgress extends DownloadEvent {
  final double fraction;
  final int downloadedBytes;
  final int totalBytes;
  final double? bytesPerSecond;
  final Duration? eta;
  final String? partialPath;

  const DownloadProgress({
    required this.fraction,
    required this.downloadedBytes,
    required this.totalBytes,
    this.bytesPerSecond,
    this.eta,
    this.partialPath,
  });
}

class DownloadCompleted extends DownloadEvent {
  final String filePath;
  final int totalBytes;
  final List<BatchFailure> skipped;

  const DownloadCompleted({
    required this.filePath,
    required this.totalBytes,
    this.skipped = const [],
  });
}

class DownloadFailed extends DownloadEvent {
  final MediaFlowError error;
  final List<BatchFailure> skipped;

  const DownloadFailed(this.error, {this.skipped = const []});
}

class DownloadCancelled extends DownloadEvent {
  const DownloadCancelled();
}

class SourceRegistry {
  final List<SourceAdapter> adapters;

  const SourceRegistry(this.adapters);

  SourceAdapter resolve(Uri uri) {
    for (final adapter in adapters) {
      if (adapter.canHandle(uri)) return adapter;
    }
    throw const MediaFlowException(
      MediaFlowError(code: MediaFlowErrorCode.unsupportedUrl),
    );
  }

  static String sourceIdFor(Uri uri) {
    final host = uri.host.toLowerCase();
    return host.isEmpty ? 'unknown' : host.replaceFirst(RegExp(r'^www\.'), '');
  }

  static String labelFor(Uri uri) {
    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    if (host == 'youtu.be' || host.endsWith('youtube.com')) return 'YouTube';
    if (host.endsWith('tiktok.com')) return 'TikTok';
    if (host == 'fb.watch' || host.endsWith('facebook.com')) return 'Facebook';
    if (host.endsWith('instagram.com')) return 'Instagram';
    if (host.endsWith('kick.com')) return 'Kick';
    if (host.endsWith('twitch.tv')) return 'Twitch';
    if (host.endsWith('soundcloud.com')) return 'SoundCloud';
    if (host == 'drive.google.com' || host == 'docs.google.com') {
      return 'Google Drive';
    }
    if (host.isEmpty) return 'Unknown';
    return host;
  }

  static String fallbackTitle(Uri uri) {
    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    final segments = uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (host == 'youtu.be' && segments.isNotEmpty) {
      return 'YouTube ${segments.first}';
    }
    final queryId = uri.queryParameters['v'];
    if (queryId != null && queryId.isNotEmpty) {
      return '${labelFor(uri)} $queryId';
    }
    if (segments.isNotEmpty) {
      final last = Uri.decodeComponent(segments.last);
      if (last.length > 2) return last;
    }
    final label = labelFor(uri);
    return '$label link';
  }
}
