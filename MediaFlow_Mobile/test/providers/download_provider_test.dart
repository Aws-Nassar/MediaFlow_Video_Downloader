import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediaflow_android/providers/download_provider.dart';
import 'package:mediaflow_android/providers/history_provider.dart';
import 'package:mediaflow_android/providers/settings_provider.dart';
import 'package:mediaflow_android/services/ytdlp_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeYtdlpService extends YtdlpService {
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  Map<String, dynamic> downloadResult = const {};
  Map<String, dynamic> infoResult = const {'ok': true, 'title': 'Test clip'};
  Completer<Map<String, dynamic>>? downloadCompleter;

  @override
  Stream<Map<String, dynamic>> get onProgress => _controller.stream;

  @override
  Future<Map<String, dynamic>> getOptions() async => {};

  @override
  Future<Map<String, dynamic>> fetchInfo(
    String url, {
    bool playlist = false,
    String cookieFile = '',
  }) async => infoResult;

  @override
  Future<Map<String, dynamic>> download(
    String url,
    String outputDir,
    String ext,
    String quality,
    bool isAudio,
    Map<String, dynamic> options,
  ) {
    final completer = downloadCompleter;
    if (completer != null) return completer.future;
    return Future.value(downloadResult);
  }

  @override
  Future<void> cancelDownload() async {}

  void emit(Map<String, dynamic> event) => _controller.add(event);

  Future<void> close() => _controller.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('mediaflow_test');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('normalizes progress and records downloaded file paths', () async {
    final settings = SettingsProvider();
    await settings.init();
    settings.setDownloadPath(tempDir.path);

    final history = HistoryProvider();
    await history.init();

    final fake = FakeYtdlpService();
    final completer = Completer<Map<String, dynamic>>();
    fake.downloadCompleter = completer;
    final provider = DownloadProvider(settings, history, ytdlp: fake);
    addTearDown(provider.dispose);
    addTearDown(fake.close);

    final download = provider.startDownload('https://example.com/clip');
    await pumpEventQueue();
    expect(provider.statusText, 'downloading');

    fake.emit({'percent': 42, 'message': 'Downloading 42%'});
    await pumpEventQueue();
    expect(provider.progress, closeTo(0.42, 1e-9));
    expect(provider.statusText, 'downloading');

    fake.emit({'percent': 0.75});
    await pumpEventQueue();
    expect(provider.progress, closeTo(0.75, 1e-9));

    completer.complete({
      'ok': true,
      'title': 'Clip',
      'downloaded_files': ['${tempDir.path}/clip.mp4'],
    });
    await download;

    expect(provider.statusText, 'completed');
    expect(history.items, hasLength(1));
    expect(history.items.first.filePath, '${tempDir.path}/clip.mp4');
  });
}
