import 'package:flutter/foundation.dart';

enum MediaKind { video, audio, file, collection }

enum DownloadType { video, audio }

enum JobStatus {
  queued,
  probing,
  downloading,
  processing,
  completed,
  failed,
  skipped,
  cancelled,
}

extension JobStatusX on JobStatus {
  bool get isTerminal =>
      this == JobStatus.completed ||
      this == JobStatus.failed ||
      this == JobStatus.skipped ||
      this == JobStatus.cancelled;

  bool get isActive => !isTerminal;
}

enum MediaFlowErrorCode {
  invalidUrl,
  unsupportedUrl,
  loginRequired,
  cookiesExpired,
  permissionDenied,
  downloadRestricted,
  policyBlocked,
  drmProtected,
  paywalled,
  geoBlocked,
  rateLimited,
  quotaExceeded,
  notFound,
  emptyCollection,
  formatUnavailable,
  liveUnavailable,
  driveLayoutChanged,
  zipFailed,
  diskFull,
  network,
  engineMissing,
  ffmpegMissing,
  cancelled,
  unknown,
}

@immutable
class MediaFlowError {
  final MediaFlowErrorCode code;
  final String? technicalDetails;
  final bool retryable;

  const MediaFlowError({
    required this.code,
    this.technicalDetails,
    this.retryable = false,
  });

  bool get isRetryable =>
      retryable ||
      code == MediaFlowErrorCode.network ||
      code == MediaFlowErrorCode.rateLimited ||
      code == MediaFlowErrorCode.quotaExceeded;
}

class MediaFlowException implements Exception {
  final MediaFlowError error;
  const MediaFlowException(this.error);

  @override
  String toString() => 'MediaFlowException(${error.code.name})';
}

@immutable
class MediaEntry {
  final String title;
  final String url;
  final int? sizeBytes;
  final MediaKind kind;
  final String? id;
  final String? relativePath;

  const MediaEntry({
    required this.title,
    required this.url,
    this.sizeBytes,
    this.kind = MediaKind.file,
    this.id,
    this.relativePath,
  });
}

@immutable
class MediaDescriptor {
  final String sourceId;
  final String sourceLabel;
  final String canonicalUrl;
  final String title;
  final String? author;
  final Duration? duration;
  final MediaKind kind;
  final bool isCollection;
  final int itemCount;
  final int? totalBytes;
  final List<MediaEntry> entries;

  const MediaDescriptor({
    required this.sourceId,
    required this.sourceLabel,
    required this.canonicalUrl,
    required this.title,
    required this.kind,
    this.author,
    this.duration,
    this.isCollection = false,
    this.itemCount = 1,
    this.totalBytes,
    this.entries = const [],
  });
}

class DownloadJob {
  final String id;
  final String batchId;
  final String url;
  String sourceId;
  String sourceLabel;
  final String createdAtLabel;
  final DateTime createdAt;

  String title;
  DownloadType downloadType;
  JobStatus status;
  double progress;
  int? downloadedBytes;
  int? totalBytes;
  double? bytesPerSecond;
  Duration? eta;
  MediaFlowError? error;
  String? filePath;
  String? relativePath;
  DateTime? completedAt;
  int itemIndex;
  int itemCount;

  DownloadJob({
    required this.id,
    required this.batchId,
    required this.url,
    required this.sourceId,
    required this.sourceLabel,
    required this.title,
    required this.downloadType,
    required this.status,
    required this.createdAt,
    this.progress = 0,
    this.downloadedBytes,
    this.totalBytes,
    this.bytesPerSecond,
    this.eta,
    this.error,
    this.filePath,
    this.relativePath,
    this.completedAt,
    this.itemIndex = 1,
    this.itemCount = 1,
  }) : createdAtLabel = formatShortDate(createdAt);

  bool get isTerminal => status.isTerminal;

  bool get isFailed => status == JobStatus.failed;

  double get safeProgress => progress.clamp(0, 1).toDouble();
}

@immutable
class BatchFailure {
  final String jobId;
  final String title;
  final String url;
  final MediaFlowErrorCode code;

  const BatchFailure({
    required this.jobId,
    required this.title,
    required this.url,
    required this.code,
  });
}

@immutable
class BatchSummary {
  final String batchId;
  final int total;
  final int completed;
  final int failed;
  final int skipped;
  final int cancelled;
  final int totalBytes;
  final Duration elapsed;
  final List<BatchFailure> failures;

  const BatchSummary({
    required this.batchId,
    required this.total,
    required this.completed,
    required this.failed,
    required this.skipped,
    required this.cancelled,
    required this.totalBytes,
    required this.elapsed,
    required this.failures,
  });

  bool get hasFailures => failures.isNotEmpty;

  bool get isSingleSuccess => total == 1 && completed == 1 && !hasFailures;

  int get failedCount => failed;
}

String formatBytes(int? bytes) {
  if (bytes == null || bytes <= 0) return '—';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final digits = value >= 100 || unit == 0 ? 0 : 1;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}

String formatSpeed(double? bytesPerSecond) {
  if (bytesPerSecond == null || bytesPerSecond <= 0) return '';
  return '${formatBytes(bytesPerSecond.round())}/s';
}

String formatDuration(Duration? duration) {
  if (duration == null) return '';
  final seconds = duration.inSeconds;
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  return '$minutes:${secs.toString().padLeft(2, '0')}';
}

String formatEta(Duration? eta) {
  if (eta == null || eta.inSeconds <= 0) return '';
  return '${formatDuration(eta)} left';
}

String formatPercent(double value) => '${(value.clamp(0, 1) * 100).round()}%';

String formatShortDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}

String formatDateTime(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${formatShortDate(date)} ${two(date.hour)}:${two(date.minute)}';
}

String shortUrl(String url, {int max = 68}) {
  if (url.length <= max) return url;
  return '${url.substring(0, max - 1)}…';
}

String safeFileName(String value) {
  final cleaned = value
      .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
      .replaceAll(RegExp(r'[. ]+$'), '')
      .trim();
  final safe = cleaned.isEmpty ? 'mediaflow-download' : cleaned;
  return safe.length > 160 ? safe.substring(0, 160) : safe;
}
