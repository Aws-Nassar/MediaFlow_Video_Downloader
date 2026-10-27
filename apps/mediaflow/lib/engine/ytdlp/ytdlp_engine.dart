import 'dart:async';
import 'dart:io';

import '../../models/media_models.dart';
import '../../sources/source_adapter.dart';
import 'download_engine.dart';
import 'engine_process.dart';
import 'ytdlp_command_builder.dart';
import 'ytdlp_error_mapper.dart';
import 'ytdlp_parser.dart';

class YtDlpEngine implements DownloadEngine {
  YtDlpEngine({
    required this.executablePath,
    required this.ffmpegPath,
    required this.outputDirectory,
    this.runner = const SystemEngineProcessRunner(),
    this.probeTimeout = const Duration(seconds: 45),
    this.retries = 3,
  });

  final String executablePath;
  final String? ffmpegPath;
  String outputDirectory;
  final EngineProcessRunner runner;
  final Duration probeTimeout;
  final int retries;

  final Map<String, _RunningDownload> _running = {};

  @override
  bool get hasFfmpeg => ffmpegPath != null && ffmpegPath!.trim().isNotEmpty;

  @override
  String get engineLabel => hasFfmpeg ? 'yt-dlp + FFmpeg' : 'yt-dlp';

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
    final EngineProcess process;
    try {
      process = await runner.start(executablePath, args);
    } on ProcessException catch (error) {
      throw MediaFlowException(_engineStartError(error));
    } catch (error) {
      throw MediaFlowException(_errorFrom(error));
    }

    final stdout = StringBuffer();
    final stderr = _BoundedDetails();
    final stdoutDone = _collect(
      process.stdoutLines,
      (line) => stdout.writeln(line),
    );
    final stderrDone = _collect(process.stderrLines, stderr.add);

    var timedOut = false;
    int exitCode;
    try {
      exitCode = await process.exitCode.timeout(probeTimeout);
    } on TimeoutException {
      timedOut = true;
      exitCode = -1;
      await process.kill();
    }

    try {
      await Future.wait([stdoutDone, stderrDone]);
    } catch (error) {
      throw MediaFlowException(_errorFrom(error));
    }

    if (timedOut) {
      throw const MediaFlowException(
        MediaFlowError(
          code: MediaFlowErrorCode.network,
          technicalDetails: 'The metadata probe timed out.',
          retryable: true,
        ),
      );
    }

    if (exitCode != 0) {
      throw MediaFlowException(
        mapYtDlpProcessFailure(details: stderr.value, exitCode: exitCode),
      );
    }

    final raw = stdout.toString().replaceFirst('\uFEFF', '').trim();
    if (raw.isEmpty) {
      throw const MediaFlowException(
        MediaFlowError(
          code: MediaFlowErrorCode.unknown,
          technicalDetails: 'The engine returned no metadata.',
        ),
      );
    }

    try {
      return parseYtDlpProbe(
        raw,
        uri: uri,
        downloadType: downloadType,
        ffmpegAvailable: hasFfmpeg,
      );
    } on MediaFlowException {
      rethrow;
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
  Stream<DownloadEvent> download(DownloadJob job) async* {
    if (job.downloadType == DownloadType.audio && !hasFfmpeg) {
      yield const DownloadFailed(
        MediaFlowError(code: MediaFlowErrorCode.ffmpegMissing),
      );
      return;
    }

    final outputDir = Directory(outputDirectory).absolute.path;
    try {
      await Directory(outputDir).create(recursive: true);
    } on FileSystemException catch (error) {
      yield DownloadFailed(
        MediaFlowError(
          code: MediaFlowErrorCode.permissionDenied,
          technicalDetails: redactEngineDetails(
            'Could not create the output folder: ${error.message}',
          ),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(job.url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      yield const DownloadFailed(
        MediaFlowError(code: MediaFlowErrorCode.invalidUrl),
      );
      return;
    }

    final args = YtDlpCommandBuilder.downloadArgs(
      uri: uri,
      downloadType: job.downloadType,
      outputDirectory: outputDir,
      ffmpegPath: hasFfmpeg ? ffmpegPath : null,
      retries: retries,
    );

    final EngineProcess process;
    try {
      process = await runner.start(
        executablePath,
        args,
        workingDirectory: outputDir,
      );
    } on ProcessException catch (error) {
      yield DownloadFailed(_engineStartError(error));
      return;
    } catch (error) {
      yield DownloadFailed(_errorFrom(error));
      return;
    }

    final running = _RunningDownload(process);
    _running[job.id] = running;
    final stderr = _BoundedDetails();
    final stderrDone = _collect(process.stderrLines, stderr.add);
    String? finalPath;
    int? lastTotal;

    try {
      await for (final line in process.stdoutLines) {
        final progress = parseYtDlpProgressLine(line);
        if (progress != null) {
          running.partialPath = progress.partialPath ?? running.partialPath;
          if (progress.totalBytes > 0) lastTotal = progress.totalBytes;
          yield progress;
          continue;
        }

        final path = parseYtDlpFileLine(line);
        if (path != null) finalPath = path;
      }

      await stderrDone;
      final exitCode = await process.exitCode;

      if (running.cancelled) {
        await _deletePartial(running.partialPath);
        yield const DownloadCancelled();
        return;
      }

      if (exitCode != 0) {
        await _deletePartial(running.partialPath);
        yield DownloadFailed(
          mapYtDlpProcessFailure(details: stderr.value, exitCode: exitCode),
        );
        return;
      }

      if (finalPath == null || finalPath.isEmpty) {
        await _deletePartial(running.partialPath);
        yield const DownloadFailed(
          MediaFlowError(
            code: MediaFlowErrorCode.unknown,
            technicalDetails:
                'The engine finished without reporting the output file.',
          ),
        );
        return;
      }

      var totalBytes = lastTotal ?? 0;
      try {
        final file = File(finalPath);
        if (await file.exists()) totalBytes = await file.length();
      } on FileSystemException {
        // The path was reported; keep the progress total as a fallback.
      }

      yield DownloadCompleted(filePath: finalPath, totalBytes: totalBytes);
    } catch (error) {
      try {
        await process.kill();
      } catch (_) {
        // The process may already be gone.
      }
      await _deletePartial(running.partialPath);
      if (running.cancelled) {
        yield const DownloadCancelled();
        return;
      }
      yield DownloadFailed(_errorFrom(error));
    } finally {
      _running.remove(job.id);
    }
  }

  @override
  Future<void> cancel(String jobId) async {
    final running = _running[jobId];
    if (running == null) return;
    running.cancelled = true;
    await running.process.kill();
    await _deletePartial(running.partialPath);
  }

  MediaFlowError _engineStartError(ProcessException error) {
    final message = error.message.trim();
    return MediaFlowError(
      code: MediaFlowErrorCode.engineMissing,
      technicalDetails: redactEngineDetails(
        message.isEmpty ? error.toString() : message,
      ),
    );
  }

  MediaFlowError _errorFrom(Object error) {
    if (error is MediaFlowException) return error.error;
    if (error is ProcessException) return _engineStartError(error);
    if (error is TimeoutException) {
      return const MediaFlowError(
        code: MediaFlowErrorCode.network,
        technicalDetails: 'The engine timed out.',
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

  Future<void> _collect(
    Stream<String> stream,
    void Function(String) onLine,
  ) async {
    await for (final line in stream) {
      onLine(line);
    }
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

class _RunningDownload {
  final EngineProcess process;
  bool cancelled = false;
  String? partialPath;

  _RunningDownload(this.process);
}

class _BoundedDetails {
  static const _maxLength = 64 * 1024;
  final StringBuffer _buffer = StringBuffer();
  var _length = 0;

  void add(String line) {
    if (_length >= _maxLength) return;
    final text = '$line\n';
    final remaining = _maxLength - _length;
    if (text.length <= remaining) {
      _buffer.write(text);
      _length += text.length;
    } else {
      _buffer.write(text.substring(0, remaining));
      _length = _maxLength;
    }
  }

  String get value => _buffer.toString();
}
