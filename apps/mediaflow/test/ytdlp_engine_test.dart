import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediaflow/engine/ytdlp/engine_process.dart';
import 'package:mediaflow/engine/ytdlp/ytdlp_engine.dart';
import 'package:mediaflow/models/media_models.dart';
import 'package:mediaflow/sources/source_adapter.dart';

class FakeEngineProcess implements EngineProcess {
  final StreamController<String> _stdout = StreamController<String>();
  final StreamController<String> _stderr = StreamController<String>();
  final Completer<int> _exit = Completer<int>();
  var _closed = false;

  @override
  int get pid => 4242;

  @override
  Stream<String> get stdoutLines => _stdout.stream;

  @override
  Stream<String> get stderrLines => _stderr.stream;

  @override
  Future<int> get exitCode => _exit.future;

  void stdout(String line) => _stdout.add(line);

  void stderr(String line) => _stderr.add(line);

  Future<void> close(int code) async {
    if (_closed) return;
    _closed = true;
    await _stdout.close();
    await _stderr.close();
    if (!_exit.isCompleted) _exit.complete(code);
  }

  @override
  Future<void> kill() => close(-1);
}

class FakeEngineProcessRunner implements EngineProcessRunner {
  final Future<void> Function(FakeEngineProcess process, List<String> args)
  handler;
  final List<List<String>> starts = [];
  FakeEngineProcess? lastProcess;

  FakeEngineProcessRunner(this.handler);

  @override
  Future<EngineProcess> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    starts.add(List<String>.from(arguments));
    final process = FakeEngineProcess();
    lastProcess = process;
    scheduleMicrotask(() async {
      try {
        await handler(process, arguments);
      } catch (_) {
        await process.close(1);
      }
    });
    return process;
  }
}

class MissingEngineRunner implements EngineProcessRunner {
  @override
  Future<EngineProcess> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) {
    throw ProcessException(
      executable,
      arguments,
      'The engine executable was not found.',
    );
  }
}

String get _fixture =>
    File('test/fixtures/ytdlp/single_video.json').readAsStringSync();

DownloadJob _job(DownloadType type, {String? url}) {
  return DownloadJob(
    id: 'job-1',
    batchId: 'batch-1',
    url: url ?? 'https://example.com/watch?v=fixture123',
    sourceId: 'example.com',
    sourceLabel: 'example.com',
    title: 'Fixture video',
    downloadType: type,
    status: JobStatus.queued,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('mediaflow_engine_test_');
  });

  tearDown(() async {
    if (await temp.exists()) {
      await temp.delete(recursive: true);
    }
  });

  test('probe parses fake engine metadata', () async {
    final runner = FakeEngineProcessRunner((process, args) async {
      for (final line in _fixture.split('\n')) {
        process.stdout(line);
      }
      await process.close(0);
    });
    final engine = YtDlpEngine(
      executablePath: 'yt-dlp.exe',
      ffmpegPath: 'ffmpeg.exe',
      outputDirectory: temp.path,
      runner: runner,
      probeTimeout: const Duration(seconds: 2),
    );

    final descriptor = await engine.probe(
      Uri.parse('https://example.com/watch?v=fixture123'),
      downloadType: DownloadType.video,
    );

    expect(descriptor.title, 'Fixture video');
    expect(descriptor.totalBytes, 54000000);
    expect(runner.starts.single, contains('--dump-single-json'));
  });

  test('probe classifies a login failure', () async {
    final runner = FakeEngineProcessRunner((process, args) async {
      process.stderr('ERROR: Sign in to confirm your age');
      await process.close(1);
    });
    final engine = YtDlpEngine(
      executablePath: 'yt-dlp.exe',
      ffmpegPath: 'ffmpeg.exe',
      outputDirectory: temp.path,
      runner: runner,
    );

    await expectLater(
      engine.probe(
        Uri.parse('https://example.com/watch?v=fixture123'),
        downloadType: DownloadType.video,
      ),
      throwsA(
        isA<MediaFlowException>().having(
          (error) => error.error.code,
          'code',
          MediaFlowErrorCode.loginRequired,
        ),
      ),
    );
  });

  test('download emits progress and the final file path', () async {
    final finalPath = '${temp.path}${Platform.pathSeparator}Fixture video.mp4';
    await File(finalPath).writeAsBytes(List<int>.filled(1024, 7));
    final runner = FakeEngineProcessRunner((process, args) async {
      process.stdout(
        'MF_PROGRESS {"status":"downloading","downloaded_bytes":512,'
        '"total_bytes":1024,"speed":100,"eta":1}',
      );
      process.stdout('MF_FILE $finalPath');
      await process.close(0);
    });
    final engine = YtDlpEngine(
      executablePath: 'yt-dlp.exe',
      ffmpegPath: 'ffmpeg.exe',
      outputDirectory: temp.path,
      runner: runner,
    );

    final events = await engine.download(_job(DownloadType.video)).toList();

    final progress = events.whereType<DownloadProgress>().single;
    expect(progress.fraction, 0.5);
    final completed = events.whereType<DownloadCompleted>().single;
    expect(completed.filePath, finalPath);
    expect(completed.totalBytes, 1024);
    expect(runner.starts.single, contains('--no-simulate'));
    expect(
      runner.starts.single[runner.starts.single.indexOf('-P') + 1],
      Directory(temp.path).absolute.path,
    );
  });

  test(
    'download failure is classified and partial files are removed',
    () async {
      final partial = '${temp.path}${Platform.pathSeparator}fixture.part';
      await File(partial).writeAsBytes([1, 2, 3]);
      final runner = FakeEngineProcessRunner((process, args) async {
        process.stdout(
          'MF_PROGRESS {"status":"downloading","downloaded_bytes":10,'
          '"total_bytes":100,"tmpfilename":${jsonEncode(partial)}}',
        );
        process.stderr('ERROR: The uploader has disabled downloads');
        await process.close(1);
      });
      final engine = YtDlpEngine(
        executablePath: 'yt-dlp.exe',
        ffmpegPath: 'ffmpeg.exe',
        outputDirectory: temp.path,
        runner: runner,
      );

      final events = await engine.download(_job(DownloadType.video)).toList();

      final failure = events.whereType<DownloadFailed>().single;
      expect(failure.error.code, MediaFlowErrorCode.downloadRestricted);
      expect(await File(partial).exists(), isFalse);
    },
  );

  test('audio without FFmpeg fails before spawning', () async {
    final runner = FakeEngineProcessRunner((process, args) async {
      await process.close(0);
    });
    final engine = YtDlpEngine(
      executablePath: 'yt-dlp.exe',
      ffmpegPath: null,
      outputDirectory: temp.path,
      runner: runner,
    );

    final events = await engine.download(_job(DownloadType.audio)).toList();

    expect(events.single, isA<DownloadFailed>());
    expect(
      (events.single as DownloadFailed).error.code,
      MediaFlowErrorCode.ffmpegMissing,
    );
    expect(runner.starts, isEmpty);
  });

  test('a missing engine executable becomes engineMissing', () async {
    final engine = YtDlpEngine(
      executablePath: 'yt-dlp.exe',
      ffmpegPath: 'ffmpeg.exe',
      outputDirectory: temp.path,
      runner: MissingEngineRunner(),
    );

    await expectLater(
      engine.probe(
        Uri.parse('https://example.com/watch?v=fixture123'),
        downloadType: DownloadType.video,
      ),
      throwsA(
        isA<MediaFlowException>().having(
          (error) => error.error.code,
          'code',
          MediaFlowErrorCode.engineMissing,
        ),
      ),
    );

    final events = await engine.download(_job(DownloadType.video)).toList();
    expect(events.single, isA<DownloadFailed>());
    expect(
      (events.single as DownloadFailed).error.code,
      MediaFlowErrorCode.engineMissing,
    );
  });

  test(
    'cancel kills the process, emits cancelled, and removes the partial',
    () async {
      final partial = '${temp.path}${Platform.pathSeparator}fixture.part';
      final runner = FakeEngineProcessRunner((process, args) async {
        process.stdout(
          'MF_PROGRESS {"status":"downloading","downloaded_bytes":10,'
          '"total_bytes":100,"tmpfilename":${jsonEncode(partial)}}',
        );
        await process.exitCode;
      });
      final engine = YtDlpEngine(
        executablePath: 'yt-dlp.exe',
        ffmpegPath: 'ffmpeg.exe',
        outputDirectory: temp.path,
        runner: runner,
      );

      final events = <DownloadEvent>[];
      final firstProgress = Completer<void>();
      final done = Completer<void>();
      final subscription = engine.download(_job(DownloadType.video)).listen((
        event,
      ) {
        events.add(event);
        if (event is DownloadProgress && !firstProgress.isCompleted) {
          firstProgress.complete();
        }
      }, onDone: done.complete);

      await firstProgress.future;
      await File(partial).writeAsBytes([1, 2, 3]);
      await engine.cancel('job-1');
      await done.future.timeout(const Duration(seconds: 2));
      await subscription.cancel();

      expect(events.whereType<DownloadCancelled>(), isNotEmpty);
      expect(await File(partial).exists(), isFalse);
    },
  );

  test('success without a reported path is a failure', () async {
    final runner = FakeEngineProcessRunner((process, args) async {
      process.stdout(
        'MF_PROGRESS {"status":"finished","downloaded_bytes":10,'
        '"total_bytes":10}',
      );
      await process.close(0);
    });
    final engine = YtDlpEngine(
      executablePath: 'yt-dlp.exe',
      ffmpegPath: 'ffmpeg.exe',
      outputDirectory: temp.path,
      runner: runner,
    );

    final events = await engine.download(_job(DownloadType.video)).toList();

    final failure = events.whereType<DownloadFailed>().single;
    expect(failure.error.code, MediaFlowErrorCode.unknown);
  });
}
