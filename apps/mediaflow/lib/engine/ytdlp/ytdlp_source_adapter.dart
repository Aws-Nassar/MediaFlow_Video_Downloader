import '../../models/media_models.dart';
import '../../sources/source_adapter.dart';
import 'ytdlp_engine.dart';

class YtDlpSourceAdapter implements SourceAdapter {
  final YtDlpEngine engine;

  YtDlpSourceAdapter(this.engine);

  @override
  String get id => 'yt-dlp';

  @override
  bool canHandle(Uri uri) => uri.scheme == 'http' || uri.scheme == 'https';

  @override
  Future<MediaDescriptor> probe(Uri uri, {required DownloadType downloadType}) {
    return engine.probe(uri, downloadType: downloadType);
  }

  @override
  Stream<DownloadEvent> download(DownloadJob job) => engine.download(job);

  @override
  Future<void> cancel(String jobId) => engine.cancel(jobId);
}
