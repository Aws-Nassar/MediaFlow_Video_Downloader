import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../models/media_models.dart';
import '../../sources/source_adapter.dart';
import 'android_engine_gateway.dart';
import 'download_engine.dart';
import 'ytdlp_command_builder.dart';
import 'ytdlp_error_mapper.dart';
import 'ytdlp_parser.dart';

/// Android implementation of the shared yt-dlp engine contract.
///
/// Kotlin owns the bundled Python/yt-dlp/FFmpeg runtime. Dart builds the same
/// argument list as the desktop bridge, parses the same progress markers, and
/// maps the same errors. The native layer only adds its own library-owned flags
/// (cache, JS runtime, FFmpeg location) and runs the request.
class AndroidYtDlpEngine implements DownloadEngine {
  AndroidYtDlpEngine({
    required this.outputDirectory,
    AndroidEngineGateway? gateway,
    this.probeTimeout = const Duration(seconds: 90),
    this.retries = 3,
  }) : _gateway = gateway ?? MethodChannelAndroidEngineGateway() {
    _lineSubscription = _gateway.lines.listen(_handleLine);
  }

  String outputDirectory;
  final AndroidEngineGateway _gateway;
  final Duration probeTimeout;
  final int retries;

  final Map<String, _ActiveDownload> _downloads = {};
  late final StreamSubscription<AndroidEngineLine> _lineSubscription;
  bool _disposed = false;

  @override
  bool get hasFfmpeg => true;

  @override
  String get engineLabel => 'yt-dlp + FFmpeg (Android)';

  @override
  void setOutputDirectory(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    outputDirectory = trimmed;
  }

  @override
  Future<MediaDescriptor> probe(
    Uri uri, {
    required DownloadType downloadType,
  }) async {
    final args = YtDlpCommandBuilder.probeArgs(uri);
    // The native bridge appends the URL after the shared arguments.
    final wireArgs = args.sublist(0, args.length - 1);

    try {
      final raw = await _gateway
          .probe(url: uri.toString(), args: wireArgs)
          .timeout(probeTimeout);
      final trimmed = raw.replaceFirst('\uFEFF', '').trim();
      if (trimmed.isEmpty) {
        throw const MediaFlowException(
          MediaFlowError(
            code: MediaFlowErrorCode.unknown,
            technicalDetails: 'The Android engine returned no metadata.',
          ),
        );
      }
      return parseYtDlpProbe(
        trimmed,
        uri: uri,
        downloadType: downloadType,
        ffmpegAvailable: hasFfmpeg,
      );
    } on TimeoutException {
      throw const MediaFlowException(
        MediaFlowError(
          code: MediaFlowErrorCode.network,
          technicalDetails: 'The Android metadata probe timed out.',
          retryable: true,
        ),
      );
    } on MediaFlowException {
      rethrow;
    } on PlatformException catch (error) {
      throw MediaFlowException(_platformError(error));
    } on MissingPluginException catch (error) {
      throw MediaFlowException(_missingPluginError(error));
    } catch (error) {
      throw MediaFlowException(
        MediaFlowError(
          code: MediaFlowErrorCode.unknown,
          technicalDetails: redactEngineDetails(error.toString()),
        ),
      );
    }
  }

  @override
  Stream<DownloadEvent> download(DownloadJob job) {
    final controller = StreamController<DownloadEvent>();
    final active = _ActiveDownload(job.id, controller);
    _downloads[job.id] = active;
    unawaited(_runDownload(job, active));
    return controller.stream;
  }

  Future<void> _runDownload(DownloadJob job, _ActiveDownload active) async {
    try {
      if (job.downloadType == DownloadType.audio && !hasFfmpeg) {
        _finish(
          active,
          const DownloadFailed(
            MediaFlowError(code: MediaFlowErrorCode.ffmpegMissing),
          ),
        );
        return;
      }

      final uri = Uri.tryParse(job.url);
      if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
        _finish(
          active,
          const DownloadFailed(
            MediaFlowError(code: MediaFlowErrorCode.invalidUrl),
          ),
        );
        return;
      }

      final outputDir = Directory(outputDirectory).absolute.path;
      try {
        await Directory(outputDir).create(recursive: true);
      } on FileSystemException catch (error) {
        _finish(
          active,
          DownloadFailed(
            MediaFlowError(
              code: MediaFlowErrorCode.permissionDenied,
              technicalDetails: redactEngineDetails(
                'Could not create the output folder: ${error.message}',
              ),
            ),
          ),
        );
        return;
      }

      final args = YtDlpCommandBuilder.downloadArgs(
        uri: uri,
        downloadType: job.downloadType,
        outputDirectory: outputDir,
        ffmpegAvailable: hasFfmpeg,
        retries: retries,
      );
      // The native bridge appends the URL after the shared arguments.
      final wireArgs = args.sublist(0, args.length - 1);
      final result = await _gateway.download(
        jobId: job.id,
        url: uri.toString(),
        args: wireArgs,
      );

      if (active.terminal) return;

      if (result.isCompleted) {
        final path = result.filePath ?? active.finalPath;
        if (path == null || path.isEmpty) {
          _finish(
            active,
            const DownloadFailed(
              MediaFlowError(
                code: MediaFlowErrorCode.unknown,
                technicalDetails:
                    'The Android engine finished without reporting the output file.',
              ),
            ),
          );
          return;
        }

        var totalBytes = result.totalBytes ?? 0;
        try {
          final file = File(path);
          if (await file.exists()) totalBytes = await file.length();
        } on FileSystemException {
          // The path was reported; keep the native total as a fallback.
        }
        _finish(
          active,
          DownloadCompleted(filePath: path, totalBytes: totalBytes),
        );
        return;
      }

      if (result.isCancelled) {
        await _deletePartial(active.partialPath);
        _finish(active, const DownloadCancelled());
        return;
      }

      await _deletePartial(active.partialPath);
      _finish(active, DownloadFailed(_errorFromResult(result)));
    } on PlatformException catch (error) {
      await _deletePartial(active.partialPath);
      _finish(active, DownloadFailed(_platformError(error)));
    } on MissingPluginException catch (error) {
      await _deletePartial(active.partialPath);
      _finish(active, DownloadFailed(_missingPluginError(error)));
    } catch (error) {
      await _deletePartial(active.partialPath);
      _finish(active, DownloadFailed(_errorFrom(error)));
    } finally {
      if (!active.terminal) {
        await _deletePartial(active.partialPath);
        _finish(
          active,
          const DownloadFailed(
            MediaFlowError(
              code: MediaFlowErrorCode.unknown,
              technicalDetails:
                  'The Android engine ended without a terminal event.',
            ),
          ),
        );
      }
    }
  }

  void _handleLine(AndroidEngineLine event) {
    if (_disposed) return;
    final active = _downloads[event.jobId];
    if (active == null || active.terminal || active.controller.isClosed) {
      return;
    }

    final progress = parseYtDlpProgressLine(event.line);
    if (progress != null) {
      final partialPath = progress.partialPath;
      if (partialPath != null && partialPath.isNotEmpty) {
        active.partialPath = partialPath;
      }
      active.controller.add(progress);
      return;
    }

    final path = parseYtDlpFileLine(event.line);
    if (path != null) active.finalPath = path;
  }

  void _finish(_ActiveDownload active, DownloadEvent event) {
    if (active.terminal) return;
    active.terminal = true;
    if (!active.controller.isClosed) {
      active.controller.add(event);
      unawaited(active.controller.close());
    }
    _downloads.remove(active.jobId);
  }

  @override
  Future<void> cancel(String jobId) async {
    final active = _downloads[jobId];
    if (active == null) return;
    try {
      await _gateway.cancel(jobId);
    } on PlatformException {
      // The process may have finished between the UI action and this call.
    } on MissingPluginException {
      // The engine will report its own terminal failure.
    }
  }

  /// Releases the channel listener. The app keeps one engine for its lifetime;
  /// tests use this to avoid leaking their fake stream subscription.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_lineSubscription.cancel());
    for (final active in _downloads.values.toList()) {
      _finish(active, const DownloadCancelled());
    }
    _gateway.dispose();
  }

  MediaFlowError _platformError(PlatformException error) {
    final details = redactEngineDetails(
      (error.message == null || error.message!.trim().isEmpty)
          ? error.toString()
          : error.message!,
    );
    switch (error.code) {
      case 'engine_init_failed':
        return MediaFlowError(
          code: MediaFlowErrorCode.engineMissing,
          technicalDetails: details,
        );
      case 'ffmpeg_init_failed':
        return MediaFlowError(
          code: MediaFlowErrorCode.ffmpegMissing,
          technicalDetails: details,
        );
      default:
        return mapYtDlpProcessFailure(
          details: error.message ?? error.code,
          exitCode: 1,
        );
    }
  }

  MediaFlowError _missingPluginError(MissingPluginException error) {
    final message = error.message?.trim();
    return MediaFlowError(
      code: MediaFlowErrorCode.engineMissing,
      technicalDetails: redactEngineDetails(
        message == null || message.isEmpty
            ? 'The Android engine channel is unavailable.'
            : message,
      ),
    );
  }

  MediaFlowError _errorFromResult(AndroidDownloadResult result) {
    final details = redactEngineDetails(result.details ?? '');
    switch (result.code) {
      case 'engine_init_failed':
        return MediaFlowError(
          code: MediaFlowErrorCode.engineMissing,
          technicalDetails: details,
        );
      case 'ffmpeg_init_failed':
        return MediaFlowError(
          code: MediaFlowErrorCode.ffmpegMissing,
          technicalDetails: details,
        );
      default:
        return mapYtDlpProcessFailure(
          details: result.details ?? '',
          exitCode: result.exitCode ?? 1,
        );
    }
  }

  MediaFlowError _errorFrom(Object error) {
    if (error is MediaFlowException) return error.error;
    if (error is TimeoutException) {
      return const MediaFlowError(
        code: MediaFlowErrorCode.network,
        technicalDetails: 'The Android engine timed out.',
        retryable: true,
      );
    }
    if (error is FileSystemException) {
      final details = redactEngineDetails(error.message);
      final lower = details.toLowerCase();
      if (lower.contains('space') || lower.contains('enospc')) {
        return MediaFlowError(
          code: MediaFlowErrorCode.diskFull,
          technicalDetails: details,
        );
      }
      return MediaFlowError(
        code: MediaFlowErrorCode.unknown,
        technicalDetails: details,
      );
    }
    return MediaFlowError(
      code: MediaFlowErrorCode.unknown,
      technicalDetails: redactEngineDetails(error.toString()),
    );
  }

  Future<void> _deletePartial(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Best effort: a partial artifact that cannot be removed must not hide
      // the original download result.
    }
  }
}

class _ActiveDownload {
  final String jobId;
  final StreamController<DownloadEvent> controller;
  bool terminal = false;
  String? partialPath;
  String? finalPath;

  _ActiveDownload(this.jobId, this.controller);
}
