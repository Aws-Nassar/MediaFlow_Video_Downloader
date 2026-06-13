import 'dart:convert';
import 'package:flutter/services.dart';

class YtdlpService {
  static const _channel = MethodChannel('com.mediaflow.android/python');
  static const _progressChannel =
      EventChannel('com.mediaflow.android/python/progress');

  Stream<Map<String, dynamic>> get onProgress =>
      _progressChannel
          .receiveBroadcastStream()
          .where((event) => event is String)
          .map((event) => jsonDecode(event as String) as Map<String, dynamic>);

  Future<Map<String, dynamic>> getOptions() async {
    try {
      final raw = await _channel.invokeMethod<String>('getOptions');
      if (raw == null) return {};
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> fetchInfo(String url,
      {bool playlist = false, String cookieFile = ''}) async {
    try {
      final raw = await _channel.invokeMethod<String>('fetchInfo', {
        'url': url,
        'playlist': playlist,
        'cookieFile': cookieFile,
      });
      if (raw == null) return {'ok': false, 'error': 'Null response'};
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> download(
    String url,
    String outputDir,
    String ext,
    String quality,
    bool isAudio,
    Map<String, dynamic> options,
  ) async {
    try {
      final raw = await _channel.invokeMethod<String>('download', {
        'url': url,
        'outputDir': outputDir,
        'ext': ext,
        'quality': quality,
        'isAudio': isAudio,
        'optionsJson': jsonEncode(options),
      });
      if (raw == null) return {'ok': false, 'error': 'Null response'};
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<void> cancelDownload() async {
    try {
      await _channel.invokeMethod('cancelDownload');
    } catch (_) {}
  }
}
