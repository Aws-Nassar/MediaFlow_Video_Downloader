import '../models/media_models.dart';
import 'source_adapter.dart';

/// Routes each URL to the first adapter that accepts it.
///
/// The demo adapter intentionally sits before the real engine so the shipped
/// sample links keep their offline behavior. Production URLs fall through to
/// the real engine when it is available.
class CompositeSourceAdapter
    implements SourceAdapter, OutputDirectoryAware, EngineInfo {
  final List<SourceAdapter> adapters;
  final Map<String, SourceAdapter> _owners = {};

  CompositeSourceAdapter(List<SourceAdapter> adapters)
    : adapters = List<SourceAdapter>.unmodifiable(adapters);

  @override
  String get id => 'composite';

  @override
  bool canHandle(Uri uri) => adapters.any((adapter) => adapter.canHandle(uri));

  @override
  bool get isDemoEngine => !adapters.any(
    (adapter) => adapter is EngineInfo && !(adapter as EngineInfo).isDemoEngine,
  );

  @override
  String get engineLabel {
    // A non-engine source such as Drive may sit before yt-dlp in routing
    // order. Prefer the actual download engine label when it exists.
    for (final adapter in adapters) {
      if (adapter.id == 'yt-dlp' &&
          adapter is EngineInfo &&
          !(adapter as EngineInfo).isDemoEngine) {
        return (adapter as EngineInfo).engineLabel;
      }
    }
    for (final adapter in adapters) {
      if (adapter is EngineInfo && !(adapter as EngineInfo).isDemoEngine) {
        return (adapter as EngineInfo).engineLabel;
      }
    }
    return 'Demo engine';
  }

  @override
  void setOutputDirectory(String path) {
    for (final adapter in adapters) {
      if (adapter is OutputDirectoryAware) {
        (adapter as OutputDirectoryAware).setOutputDirectory(path);
      }
    }
  }

  SourceAdapter _resolve(Uri uri) {
    for (final adapter in adapters) {
      if (adapter.canHandle(uri)) return adapter;
    }
    throw const MediaFlowException(
      MediaFlowError(code: MediaFlowErrorCode.unsupportedUrl),
    );
  }

  @override
  Future<MediaDescriptor> probe(Uri uri, {required DownloadType downloadType}) {
    return _resolve(uri).probe(uri, downloadType: downloadType);
  }

  @override
  Stream<DownloadEvent> download(DownloadJob job) async* {
    final uri = Uri.tryParse(job.url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      yield const DownloadFailed(
        MediaFlowError(code: MediaFlowErrorCode.invalidUrl),
      );
      return;
    }

    final SourceAdapter selected;
    try {
      selected = _resolve(uri);
    } on MediaFlowException catch (error) {
      yield DownloadFailed(error.error);
      return;
    }

    _owners[job.id] = selected;
    try {
      yield* selected.download(job);
    } catch (error) {
      yield DownloadFailed(_errorFrom(error));
    } finally {
      _owners.remove(job.id);
    }
  }

  @override
  Future<void> cancel(String jobId) async {
    final owner = _owners.remove(jobId);
    if (owner != null) {
      await owner.cancel(jobId);
      return;
    }
    for (final adapter in adapters) {
      await adapter.cancel(jobId);
    }
  }

  MediaFlowError _errorFrom(Object error) {
    if (error is MediaFlowException) return error.error;
    return const MediaFlowError(
      code: MediaFlowErrorCode.unknown,
      technicalDetails: 'The selected source adapter failed.',
    );
  }
}
