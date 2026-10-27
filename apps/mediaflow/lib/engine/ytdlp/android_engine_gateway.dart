import 'dart:async';

import 'package:flutter/services.dart';

const androidEngineChannelName = 'com.mediaflow.app/engine';

/// One stdout line emitted by the Android engine.
class AndroidEngineLine {
  final String jobId;
  final String line;

  const AndroidEngineLine({required this.jobId, required this.line});
}

/// The terminal result returned by the native download call.
class AndroidDownloadResult {
  final String status;
  final String? filePath;
  final int? totalBytes;
  final String? details;
  final int? exitCode;
  final String? code;

  const AndroidDownloadResult({
    required this.status,
    this.filePath,
    this.totalBytes,
    this.details,
    this.exitCode,
    this.code,
  });

  bool get isCompleted => status == 'completed';

  bool get isCancelled => status == 'cancelled';

  factory AndroidDownloadResult.fromMap(Map<Object?, Object?> map) {
    return AndroidDownloadResult(
      status: _string(map['status']) ?? 'failed',
      filePath: _string(map['filePath']),
      totalBytes: _int(map['totalBytes']),
      details: _string(map['details']),
      exitCode: _int(map['exitCode']),
      code: _string(map['code']),
    );
  }
}

/// The narrow platform boundary used by [AndroidYtDlpEngine].
///
/// Tests replace this with a fake; production uses the method channel backed by
/// [com.mediaflow.app.MainActivity].
abstract interface class AndroidEngineGateway {
  Stream<AndroidEngineLine> get lines;

  Future<String> probe({required String url, required List<String> args});

  Future<AndroidDownloadResult> download({
    required String jobId,
    required String url,
    required List<String> args,
  });

  Future<void> cancel(String jobId);

  void dispose();
}

/// Bridges Dart to the Kotlin `youtubedl-android` wrapper.
class MethodChannelAndroidEngineGateway implements AndroidEngineGateway {
  MethodChannelAndroidEngineGateway({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(androidEngineChannelName) {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  final MethodChannel _channel;
  final StreamController<AndroidEngineLine> _lines =
      StreamController<AndroidEngineLine>.broadcast();
  bool _disposed = false;

  @override
  Stream<AndroidEngineLine> get lines => _lines.stream;

  Future<Object?> _handleNativeCall(MethodCall call) async {
    if (call.method != 'line') return null;
    final arguments = call.arguments;
    if (arguments is! Map) return null;
    final jobId = arguments['jobId'];
    final line = arguments['line'];
    if (jobId is String && line is String && !_disposed) {
      _lines.add(AndroidEngineLine(jobId: jobId, line: line));
    }
    return null;
  }

  @override
  Future<String> probe({
    required String url,
    required List<String> args,
  }) async {
    final raw = await _channel.invokeMethod<String>('probe', {
      'url': url,
      'args': args,
    });
    if (raw == null || raw.trim().isEmpty) {
      throw PlatformException(
        code: 'probe_failed',
        message: 'The Android engine returned no metadata.',
      );
    }
    return raw;
  }

  @override
  Future<AndroidDownloadResult> download({
    required String jobId,
    required String url,
    required List<String> args,
  }) async {
    final raw = await _channel.invokeMethod<Object?>('download', {
      'jobId': jobId,
      'url': url,
      'args': args,
    });
    if (raw is! Map) {
      throw PlatformException(
        code: 'download_failed',
        message: 'The Android engine returned an invalid result.',
      );
    }
    return AndroidDownloadResult.fromMap(raw);
  }

  @override
  Future<void> cancel(String jobId) async {
    // The native side returns whether a live process was found; ignore it.
    await _channel.invokeMethod<Object?>('cancel', {'jobId': jobId});
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _channel.setMethodCallHandler(null);
    unawaited(_lines.close());
  }
}

String? _string(Object? value) {
  if (value is String) return value;
  if (value != null) return value.toString();
  return null;
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}
