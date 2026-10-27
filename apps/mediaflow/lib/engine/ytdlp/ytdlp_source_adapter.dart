import '../../models/media_models.dart';
import '../../sources/source_adapter.dart';
import 'download_engine.dart';

class YtDlpSourceAdapter
    implements SourceAdapter, OutputDirectoryAware, EngineInfo {
  final DownloadEngine engine;

  YtDlpSourceAdapter(this.engine);

  @override
  String get id => 'yt-dlp';

  @override
  bool get isDemoEngine => false;

  @override
  String get engineLabel => engine.engineLabel;

  @override
  bool canHandle(Uri uri) => uri.scheme == 'http' || uri.scheme == 'https';

  @override
  void setOutputDirectory(String path) => engine.setOutputDirectory(path);

  @override
  Future<MediaDescriptor> probe(Uri uri, {required DownloadType downloadType}) {
    return engine.probe(uri, downloadType: downloadType);
  }

  @override
  Stream<DownloadEvent> download(DownloadJob job) => engine.download(job);

  @override
  Future<void> cancel(String jobId) => engine.cancel(jobId);
}
