import 'package:flutter_test/flutter_test.dart';
import 'package:mediaflow/models/media_models.dart';
import 'package:mediaflow/sources/fake_source_adapter.dart';
import 'package:mediaflow/sources/source_adapter.dart';
import 'package:mediaflow/state/app_state.dart';

Future<void> _waitForSummary(AppState state) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (DateTime.now().isBefore(deadline)) {
    if (state.lastSummary != null && state.activeJobs.isEmpty) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('Timed out waiting for the batch summary.');
}

void main() {
  test('a mixed batch isolates failures and summarizes them', () async {
    final state = AppState(
      adapter: FakeSourceAdapter(
        probeDelay: Duration.zero,
        stepDelay: Duration.zero,
      ),
      concurrency: 2,
    );
    addTearDown(state.dispose);

    await state.analyzeAndEnqueue(
      [
        'https://example.com/video/1',
        'https://example.com/cookies',
        'https://drive.google.com/drive/folders/demo-mixed',
      ].join('\n'),
    );
    await _waitForSummary(state);

    final summary = state.lastSummary!;
    expect(summary.total, 5);
    expect(summary.completed, 3);
    expect(summary.failed, 2);
    expect(summary.failures.length, 2);
    expect(
      summary.failures.any((failure) => failure.url.contains('cookies')),
      isTrue,
    );
    expect(
      summary.failures.any((failure) => failure.url.contains('demo-mixed')),
      isTrue,
    );
    expect(state.activeJobs, isEmpty);

    state.retryFailed();
    expect(state.lastSummary, isNull);
    await _waitForSummary(state);

    final retried = state.lastSummary!;
    expect(retried.total, 5);
    expect(retried.completed, 3);
    expect(retried.failed, 2);
  });

  test('invalid and duplicate links do not stop the rest', () async {
    final state = AppState(
      adapter: FakeSourceAdapter(
        probeDelay: Duration.zero,
        stepDelay: Duration.zero,
      ),
    );
    addTearDown(state.dispose);

    await state.analyzeAndEnqueue(
      [
        'not-a-link',
        'https://example.com/video/1',
        'https://example.com/video/1',
      ].join('\n'),
    );
    await _waitForSummary(state);

    final summary = state.lastSummary!;
    expect(state.jobs.length, 2);
    expect(summary.total, 2);
    expect(summary.completed, 1);
    expect(summary.failed, 1);
    expect(summary.failures.single.code, MediaFlowErrorCode.invalidUrl);
  });

  test('audio mode is applied to queued jobs', () async {
    final state = AppState(
      adapter: FakeSourceAdapter(
        probeDelay: Duration.zero,
        stepDelay: Duration.zero,
      ),
    );
    addTearDown(state.dispose);

    state.setDownloadType(DownloadType.audio);
    await state.analyzeAndEnqueue('https://example.com/video/1');
    await _waitForSummary(state);

    expect(state.jobs.single.downloadType, DownloadType.audio);
    expect(state.jobs.single.status, JobStatus.completed);
    expect(state.jobs.single.filePath, endsWith('.m4a'));
  });

  test('forwards output directory and exposes the real engine label', () {
    final adapter = _AwareStub();
    final state = AppState(adapter: adapter, outputDirectory: 'D:/MediaFlow');
    addTearDown(state.dispose);

    expect(adapter.outputDirectory, 'D:/MediaFlow');
    expect(state.engineLabel, 'yt-dlp + FFmpeg');

    state.setOutputDirectory('E:/Downloads');

    expect(adapter.outputDirectory, 'E:/Downloads');
    expect(state.outputDirectory, 'E:/Downloads');
  });
}

class _AwareStub implements SourceAdapter, OutputDirectoryAware, EngineInfo {
  String? outputDirectory;

  @override
  String get id => 'real';

  @override
  bool get isDemoEngine => false;

  @override
  String get engineLabel => 'yt-dlp + FFmpeg';

  @override
  bool canHandle(Uri uri) => true;

  @override
  void setOutputDirectory(String path) => outputDirectory = path;

  @override
  Future<MediaDescriptor> probe(Uri uri, {required DownloadType downloadType}) {
    throw UnimplementedError();
  }

  @override
  Stream<DownloadEvent> download(DownloadJob job) =>
      const Stream<DownloadEvent>.empty();

  @override
  Future<void> cancel(String jobId) async {}
}
