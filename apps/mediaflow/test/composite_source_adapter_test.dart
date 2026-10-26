import 'package:flutter_test/flutter_test.dart';
import 'package:mediaflow/models/media_models.dart';
import 'package:mediaflow/sources/composite_source_adapter.dart';
import 'package:mediaflow/sources/source_adapter.dart';

class _StubAdapter implements SourceAdapter, OutputDirectoryAware, EngineInfo {
  @override
  final String id;
  final bool Function(Uri uri) matches;
  final bool demo;
  final String label;
  final List<String> cancelled = [];
  String? outputDirectory;

  _StubAdapter({
    required this.id,
    required this.matches,
    required this.demo,
    required this.label,
  });

  @override
  bool get isDemoEngine => demo;

  @override
  String get engineLabel => label;

  @override
  bool canHandle(Uri uri) => matches(uri);

  @override
  void setOutputDirectory(String path) => outputDirectory = path;

  @override
  Future<MediaDescriptor> probe(
    Uri uri, {
    required DownloadType downloadType,
  }) async {
    return MediaDescriptor(
      sourceId: id,
      sourceLabel: label,
      canonicalUrl: uri.toString(),
      title: '$id item',
      kind: downloadType == DownloadType.audio
          ? MediaKind.audio
          : MediaKind.video,
    );
  }

  @override
  Stream<DownloadEvent> download(DownloadJob job) async* {
    yield DownloadCompleted(filePath: '$id/${job.id}.mp4', totalBytes: 1);
  }

  @override
  Future<void> cancel(String jobId) async {
    cancelled.add(jobId);
  }
}

DownloadJob _job(String url) {
  return DownloadJob(
    id: 'job-1',
    batchId: 'batch-1',
    url: url,
    sourceId: 'example.com',
    sourceLabel: 'example.com',
    title: 'Fixture',
    downloadType: DownloadType.video,
    status: JobStatus.queued,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late _StubAdapter demo;
  late _StubAdapter real;
  late CompositeSourceAdapter composite;

  setUp(() {
    demo = _StubAdapter(
      id: 'demo',
      matches: (uri) => uri.host == 'example.com',
      demo: true,
      label: 'Demo engine',
    );
    real = _StubAdapter(
      id: 'real',
      matches: (uri) => uri.host == 'video.example',
      demo: false,
      label: 'yt-dlp + FFmpeg',
    );
    composite = CompositeSourceAdapter([demo, real]);
  });

  test('routes to the first adapter that accepts the URL', () async {
    final demoDescriptor = await composite.probe(
      Uri.parse('https://example.com/video/1'),
      downloadType: DownloadType.video,
    );
    final realDescriptor = await composite.probe(
      Uri.parse('https://video.example/watch?v=1'),
      downloadType: DownloadType.video,
    );

    expect(demoDescriptor.title, 'demo item');
    expect(realDescriptor.title, 'real item');
    expect(composite.isDemoEngine, isFalse);
    expect(composite.engineLabel, 'yt-dlp + FFmpeg');
  });

  test('download follows the same route', () async {
    final events = await composite
        .download(_job('https://example.com/video/1'))
        .toList();

    expect(events.single, isA<DownloadCompleted>());
    expect((events.single as DownloadCompleted).filePath, 'demo/job-1.mp4');
  });

  test('forwards output directory changes to aware adapters', () {
    composite.setOutputDirectory('D:/MediaFlow');

    expect(demo.outputDirectory, 'D:/MediaFlow');
    expect(real.outputDirectory, 'D:/MediaFlow');
  });

  test('reports unsupported URLs before spawning an engine', () async {
    expect(
      () => composite.probe(
        Uri.parse('https://unknown.example/item'),
        downloadType: DownloadType.video,
      ),
      throwsA(
        isA<MediaFlowException>().having(
          (error) => error.error.code,
          'code',
          MediaFlowErrorCode.unsupportedUrl,
        ),
      ),
    );

    final events = await composite
        .download(_job('https://unknown.example/item'))
        .toList();
    expect(events.single, isA<DownloadFailed>());
    expect(
      (events.single as DownloadFailed).error.code,
      MediaFlowErrorCode.unsupportedUrl,
    );
  });

  test('rejects non-http download links', () async {
    final events = await composite
        .download(_job('ftp://example.com/file'))
        .toList();

    expect(events.single, isA<DownloadFailed>());
    expect(
      (events.single as DownloadFailed).error.code,
      MediaFlowErrorCode.invalidUrl,
    );
  });

  test('cancels through every adapter when no owner is known', () async {
    await composite.cancel('job-99');

    expect(demo.cancelled, ['job-99']);
    expect(real.cancelled, ['job-99']);
  });

  test('a demo-only composite reports the demo engine', () {
    final onlyDemo = CompositeSourceAdapter([demo]);

    expect(onlyDemo.isDemoEngine, isTrue);
    expect(onlyDemo.engineLabel, 'Demo engine');
  });

  test('prefers the yt-dlp label when Drive is first in routing order', () {
    final drive = _StubAdapter(
      id: 'drive',
      matches: (uri) => uri.host == 'drive.google.com',
      demo: false,
      label: 'Google Drive (public)',
    );
    final engine = _StubAdapter(
      id: 'yt-dlp',
      matches: (uri) => uri.host == 'video.example',
      demo: false,
      label: 'yt-dlp + FFmpeg',
    );

    final composite = CompositeSourceAdapter([demo, drive, engine]);

    expect(composite.engineLabel, 'yt-dlp + FFmpeg');
  });
}
