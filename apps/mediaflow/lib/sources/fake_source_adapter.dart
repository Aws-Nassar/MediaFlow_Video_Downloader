import '../models/media_models.dart';
import 'source_adapter.dart';

class FakeSourceAdapter implements SourceAdapter {
  final Duration probeDelay;
  final Duration stepDelay;
  final int steps;
  final Set<String> _cancelled = <String>{};

  FakeSourceAdapter({
    this.probeDelay = const Duration(milliseconds: 280),
    this.stepDelay = const Duration(milliseconds: 90),
    this.steps = 18,
  });

  @override
  String get id => 'fake';

  @override
  bool canHandle(Uri uri) => uri.scheme == 'http' || uri.scheme == 'https';

  @override
  Future<MediaDescriptor> probe(
    Uri uri, {
    required DownloadType downloadType,
  }) async {
    await Future<void>.delayed(probeDelay);

    final lower = uri.toString().toLowerCase();
    if (lower.contains('fail')) {
      throw const MediaFlowException(
        MediaFlowError(
          code: MediaFlowErrorCode.permissionDenied,
          technicalDetails: 'Simulated permission error from the fake engine.',
        ),
      );
    }
    if (lower.contains('cookies')) {
      throw const MediaFlowException(
        MediaFlowError(
          code: MediaFlowErrorCode.loginRequired,
          technicalDetails: 'Simulated login requirement from the fake engine.',
        ),
      );
    }
    if (lower.contains('missing')) {
      throw const MediaFlowException(
        MediaFlowError(
          code: MediaFlowErrorCode.notFound,
          technicalDetails: 'Simulated missing item from the fake engine.',
        ),
      );
    }

    final isFolder =
        (uri.host == 'drive.google.com' && uri.path.contains('/folders/')) ||
        lower.contains('folder');
    final sourceLabel = SourceRegistry.labelFor(uri);
    final fallback = SourceRegistry.fallbackTitle(uri);
    final itemBytes = 8 * 1024 * 1024;

    if (isFolder) {
      return MediaDescriptor(
        sourceId: SourceRegistry.sourceIdFor(uri),
        sourceLabel: sourceLabel,
        canonicalUrl: uri.toString(),
        title: '$sourceLabel folder',
        kind: MediaKind.collection,
        isCollection: true,
        itemCount: 3,
        totalBytes: itemBytes * 3,
      );
    }

    return MediaDescriptor(
      sourceId: SourceRegistry.sourceIdFor(uri),
      sourceLabel: sourceLabel,
      canonicalUrl: uri.toString(),
      title: fallback,
      author: 'Demo channel',
      duration: const Duration(minutes: 4, seconds: 12),
      kind: downloadType == DownloadType.audio
          ? MediaKind.audio
          : MediaKind.video,
      totalBytes: 12 * 1024 * 1024,
    );
  }

  @override
  Stream<DownloadEvent> download(DownloadJob job) async* {
    _cancelled.remove(job.id);
    final lower = job.url.toLowerCase();
    if (lower.contains('cookies')) {
      yield const DownloadFailed(
        MediaFlowError(
          code: MediaFlowErrorCode.loginRequired,
          technicalDetails: 'Simulated login requirement from the fake engine.',
        ),
      );
      return;
    }
    if (lower.contains('missing')) {
      yield const DownloadFailed(
        MediaFlowError(
          code: MediaFlowErrorCode.notFound,
          technicalDetails: 'Simulated missing item from the fake engine.',
        ),
      );
      return;
    }
    if (lower.contains('fail')) {
      yield const DownloadFailed(
        MediaFlowError(
          code: MediaFlowErrorCode.permissionDenied,
          technicalDetails: 'Simulated permission error from the fake engine.',
        ),
      );
      return;
    }
    final failForFolderItem = lower.contains('mixed') && job.itemIndex == 2;
    final shouldFail = lower.contains('interrupt') || failForFolderItem;
    final total = job.totalBytes ?? 12 * 1024 * 1024;
    final failAt = (steps / 2).floor();

    for (var i = 1; i <= steps; i++) {
      if (_cancelled.contains(job.id)) {
        yield const DownloadCancelled();
        return;
      }
      await Future<void>.delayed(stepDelay);
      if (_cancelled.contains(job.id)) {
        yield const DownloadCancelled();
        return;
      }
      if (shouldFail && i == failAt) {
        yield DownloadFailed(
          MediaFlowError(
            code: failForFolderItem
                ? MediaFlowErrorCode.downloadRestricted
                : MediaFlowErrorCode.network,
            technicalDetails: failForFolderItem
                ? 'Simulated owner-disabled download in the fake Drive folder.'
                : 'Simulated network failure from the fake engine.',
            retryable: !failForFolderItem,
          ),
        );
        return;
      }

      final fraction = i / steps;
      yield DownloadProgress(
        fraction: fraction,
        downloadedBytes: (total * fraction).round(),
        totalBytes: total,
        bytesPerSecond: 1.6 * 1024 * 1024,
        eta: Duration(milliseconds: (steps - i) * stepDelay.inMilliseconds),
      );
    }

    final extension = job.downloadType == DownloadType.audio ? 'm4a' : 'mp4';
    yield DownloadCompleted(
      filePath: 'Downloads/MediaFlow/${safeFileName(job.title)}.$extension',
      totalBytes: total,
    );
  }

  @override
  Future<void> cancel(String jobId) async {
    _cancelled.add(jobId);
  }
}
