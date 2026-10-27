import '../../models/media_models.dart';
import '../../sources/source_adapter.dart';

/// The shared contract for a platform-specific yt-dlp engine.
///
/// The desktop implementation runs a child process. Android implements the
/// same operations over a platform channel backed by youtubedl-android.
abstract interface class DownloadEngine {
  bool get hasFfmpeg;

  String get engineLabel;

  void setOutputDirectory(String path);

  Future<MediaDescriptor> probe(Uri uri, {required DownloadType downloadType});

  Stream<DownloadEvent> download(DownloadJob job);

  Future<void> cancel(String jobId);
}
