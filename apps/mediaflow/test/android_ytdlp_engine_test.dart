import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediaflow/engine/ytdlp/android_engine_gateway.dart';
import 'package:mediaflow/engine/ytdlp/android_ytdlp_engine.dart';
import 'package:mediaflow/models/media_models.dart';
import 'package:mediaflow/sources/default_source_adapter.dart';
import 'package:mediaflow/sources/source_adapter.dart';

class FakeAndroidEngineGateway implements AndroidEngineGateway {
  final StreamController<AndroidEngineLine> _lines =
      StreamController<AndroidEngineLine>.broadcast(sync: true);
  final List<ProbeCall> probes = [];
  final List<DownloadCall> downloads = [];
  final List<String> cancelled = [];
  Future<String> Function()? onProbe;
  Future<AndroidDownloadResult> Function(String jobId)? onDownload;
  Completer<void>? cancelSignal;
  bool disposed = false;

  @override
  Stream<AndroidEngineLine> get lines => _lines.stream;

  @override
  Future<String> probe({required String url, required List<String> args}) {
    probes.add(ProbeCall(url, List<String>.of(args)));
    final handler = onProbe;
    if (handler == null) throw StateError('No fake probe handler.');
    return handler();
  }

  @override
  Future<AndroidDownloadResult> download({
    required String jobId,
    required String url,
    required List<String> args,
  }) {
    downloads.add(DownloadCall(jobId, url, List<String>.of(args)));
    final handler = onDownload;
    if (handler == null) throw StateError('No fake download handler.');
    return handler(jobId);
  }

  @override
  Future<void> cancel(String jobId) async {
    cancelled.add(jobId);
    final signal = cancelSignal;
    if (signal != null && !signal.isCompleted) signal.complete();
  }

  @override
  void dispose() {
    disposed = true;
    unawaited(_lines.close());
  }

  void emit(String jobId, String line) {
    _lines.add(AndroidEngineLine(jobId: jobId, line: line));
  }
}

class ProbeCall {
  final String url;
  final List<String> args;

  const ProbeCall(this.url, this.args);
}

class DownloadCall {
  final String jobId;
  final String url;
  final List<String> args;

  const DownloadCall(this.jobId, this.url, this.args);
}

const _url = 'https://video.example/watch?v=fixture123';

DownloadJob _job(DownloadType type) {
  return DownloadJob(
    id: 'job-1',
    batchId: 'batch-1',
    url: _url,
    sourceId: 'video.example',
    sourceLabel: 'video.example',
    title: 'Fixture video',
    downloadType: type,
    status: JobStatus.queued,
    createdAt: DateTime(2026, 1, 1),
  );
}

String get _fixture =>
    File('test/fixtures/ytdlp/single_video.json').readAsStringSync();

void main() {
  late Directory temp;
  late FakeAndroidEngineGateway gateway;
  late AndroidYtDlpEngine engine;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('mediaflow_android_engine_');
    gateway = FakeAndroidEngineGateway();
    engine = AndroidYtDlpEngine(
      outputDirectory: temp.path,
      gateway: gateway,
      probeTimeout: const Duration(seconds: 2),
    );
  });

  tearDown(() async {
    engine.dispose();
    if (await temp.exists()) {
      await temp.delete(recursive: true);
    }
  });

  test('probe reuses the desktop JSON parser and shared arguments', () async {
    gateway.onProbe = () async => _fixture;

    final descriptor = await engine.probe(
      Uri.parse(_url),
      downloadType: DownloadType.video,
    );

    expect(descriptor.title, 'Fixture video');
    expect(descriptor.totalBytes, 54000000);
    expect(descriptor.sourceId, 'video.example');
    final call = gateway.probes.single;
    expect(call.url, _url);
    expect(call.args, contains('--dump-single-json'));
    expect(call.args, contains('--no-playlist'));
    expect(call.args.last, '--');
    expect(call.args, isNot(contains(_url)));
  });

  test('probe maps native failures with the shared classifier', () async {
    gateway.onProbe = () async {
      throw PlatformException(
        code: 'probe_failed',
        message: 'ERROR: Sign in to confirm your age',
      );
    };

    await expectLater(
      engine.probe(Uri.parse(_url), downloadType: DownloadType.video),
      throwsA(
        isA<MediaFlowException>().having(
          (error) => error.error.code,
          'code',
          MediaFlowErrorCode.loginRequired,
        ),
      ),
    );
  });

  test('probe maps a missing channel to engineMissing', () async {
    gateway.onProbe = () async {
      throw MissingPluginException('No implementation found.');
    };

    await expectLater(
      engine.probe(Uri.parse(_url), downloadType: DownloadType.video),
      throwsA(
        isA<MediaFlowException>().having(
          (error) => error.error.code,
          'code',
          MediaFlowErrorCode.engineMissing,
        ),
      ),
    );
  });

  test('download emits progress and the native final path', () async {
    final finalPath = '${temp.path}${Platform.pathSeparator}Fixture video.mp4';
    await File(finalPath).writeAsBytes(List<int>.filled(1024, 7));
    gateway.onDownload = (jobId) async {
      gateway.emit(
        jobId,
        'MF_PROGRESS {"status":"downloading","downloaded_bytes":512,'
        '"total_bytes":1024,"speed":100,"eta":1}',
      );
      gateway.emit(jobId, 'MF_FILE $finalPath');
      return AndroidDownloadResult(
        status: 'completed',
        filePath: finalPath,
        totalBytes: 1024,
      );
    };

    final events = await engine.download(_job(DownloadType.video)).toList();

    final progress = events.whereType<DownloadProgress>().single;
    expect(progress.fraction, 0.5);
    final completed = events.whereType<DownloadCompleted>().single;
    expect(completed.filePath, finalPath);
    expect(completed.totalBytes, 1024);

    final call = gateway.downloads.single;
    expect(call.url, _url);
    expect(call.args, contains('--no-simulate'));
    expect(call.args, contains('--progress'));
    expect(
      call.args[call.args.indexOf('--progress-template') + 1],
      contains('MF_PROGRESS'),
    );
    expect(
      call.args[call.args.indexOf('--print') + 1],
      startsWith('after_move:MF_FILE '),
    );
    expect(
      call.args[call.args.indexOf('-P') + 1],
      Directory(temp.path).absolute.path,
    );
    expect(call.args[call.args.indexOf('-f') + 1], 'bv*+ba/b');
    expect(call.args, isNot(contains('--ffmpeg-location')));
    expect(call.args, isNot(contains(_url)));
    expect(call.args.last, '--');
  });

  test('audio download uses FFmpeg extraction on Android', () async {
    final finalPath = '${temp.path}${Platform.pathSeparator}Fixture audio.m4a';
    await File(finalPath).writeAsBytes(List<int>.filled(64, 1));
    gateway.onDownload = (jobId) async {
      return AndroidDownloadResult(
        status: 'completed',
        filePath: finalPath,
        totalBytes: 64,
      );
    };

    final events = await engine.download(_job(DownloadType.audio)).toList();

    expect(events.single, isA<DownloadCompleted>());
    final args = gateway.downloads.single.args;
    expect(args, contains('--extract-audio'));
    expect(args[args.indexOf('-f') + 1], 'ba/b');
    expect(args, isNot(contains('--ffmpeg-location')));
  });

  test('download failure is classified and the partial is removed', () async {
    final partial = '${temp.path}${Platform.pathSeparator}fixture.part';
    await File(partial).writeAsBytes([1, 2, 3]);
    gateway.onDownload = (jobId) async {
      gateway.emit(
        jobId,
        'MF_PROGRESS {"status":"downloading","downloaded_bytes":10,'
        '"total_bytes":100,"tmpfilename":${jsonEncode(partial)}}',
      );
      return const AndroidDownloadResult(
        status: 'failed',
        details: 'ERROR: The uploader has disabled downloads',
        exitCode: 1,
      );
    };

    final events = await engine.download(_job(DownloadType.video)).toList();

    final failure = events.whereType<DownloadFailed>().single;
    expect(failure.error.code, MediaFlowErrorCode.downloadRestricted);
    expect(await File(partial).exists(), isFalse);
  });

  test('cancel forwards the job id, emits cancelled, and cleans up', () async {
    final partial = '${temp.path}${Platform.pathSeparator}fixture.part';
    await File(partial).writeAsBytes([1, 2, 3]);
    gateway.cancelSignal = Completer<void>();
    gateway.onDownload = (jobId) async {
      gateway.emit(
        jobId,
        'MF_PROGRESS {"status":"downloading","downloaded_bytes":10,'
        '"total_bytes":100,"tmpfilename":${jsonEncode(partial)}}',
      );
      await gateway.cancelSignal!.future;
      return const AndroidDownloadResult(status: 'cancelled');
    };

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
    await engine.cancel('job-1');
    await done.future.timeout(const Duration(seconds: 2));
    await subscription.cancel();

    expect(gateway.cancelled, ['job-1']);
    expect(events.whereType<DownloadCancelled>(), isNotEmpty);
    expect(await File(partial).exists(), isFalse);
  });

  test('method channel gateway uses the native contract', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel(androidEngineChannelName);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'probe':
          return '{"id":"fixture"}';
        case 'download':
          return <String, Object?>{
            'status': 'completed',
            'filePath': '/tmp/fixture.mp4',
            'totalBytes': 12,
          };
        case 'cancel':
          return true;
      }
      return null;
    });

    final channelGateway = MethodChannelAndroidEngineGateway(channel: channel);
    final lineFuture = channelGateway.lines.first;
    await messenger.handlePlatformMessage(
      androidEngineChannelName,
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('line', {
          'jobId': 'job-1',
          'line': 'MF_FILE /tmp/fixture.mp4',
        }),
      ),
      (_) {},
    );

    final line = await lineFuture;
    expect(line.jobId, 'job-1');
    expect(line.line, 'MF_FILE /tmp/fixture.mp4');

    final raw = await channelGateway.probe(
      url: _url,
      args: const ['--dump-single-json', '--'],
    );
    expect(raw, '{"id":"fixture"}');

    final result = await channelGateway.download(
      jobId: 'job-1',
      url: _url,
      args: const ['--no-simulate', '--'],
    );
    expect(result.isCompleted, isTrue);
    expect(result.filePath, '/tmp/fixture.mp4');
    expect(result.totalBytes, 12);

    await channelGateway.cancel('job-1');
    expect(
      calls.map((call) => call.method),
      containsAll(<String>['probe', 'download', 'cancel']),
    );
    final downloadCall = calls.firstWhere((call) => call.method == 'download');
    expect((downloadCall.arguments as Map)['jobId'], 'job-1');

    channelGateway.dispose();
    messenger.setMockMethodCallHandler(channel, null);
  });

  test(
    'the default Android adapter routes non-Drive URLs to the engine',
    () async {
      gateway.onProbe = () async => _fixture;
      final adapter = createDefaultSourceAdapter(
        outputDirectory: temp.path,
        android: true,
        androidGateway: gateway,
      );

      expect(adapter, isA<EngineInfo>());
      final info = adapter as EngineInfo;
      expect(info.isDemoEngine, isFalse);
      expect(info.engineLabel, 'yt-dlp + FFmpeg (Android)');

      final descriptor = await adapter.probe(
        Uri.parse(_url),
        downloadType: DownloadType.video,
      );
      expect(descriptor.title, 'Fixture video');
      expect(gateway.probes.single.url, _url);
    },
  );
}
