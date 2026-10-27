import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../models/media_models.dart';
import '../sources/source_adapter.dart';
import '../zip/zip_archive_writer.dart';
import 'drive_folder_expander.dart';
import 'drive_folder_parser.dart';
import 'drive_folder_repository.dart';
import 'drive_html.dart';
import 'drive_http.dart';
import 'drive_link.dart';

/// Downloads link-shared Google Drive files and folders over public HTTP.
///
/// No Google account, OAuth token, API key, or cookie jar is used.
class DriveSourceAdapter
    implements SourceAdapter, OutputDirectoryAware, EngineInfo {
  static const _maxHtmlBytes = 4 * 1024 * 1024;

  final DriveHttpTransport transport;
  final DriveFolderRepository repository;
  final int maxDepth;
  final int maxItems;
  String outputDirectory;

  final Map<String, _RunningDriveDownload> _running = {};
  final Set<String> _cancelled = <String>{};

  DriveSourceAdapter({
    required this.transport,
    this.outputDirectory = 'Downloads/MediaFlow',
    this.maxDepth = 10,
    this.maxItems = 10000,
  }) : repository = DriveFolderRepository(transport);

  @override
  String get id => 'drive';

  @override
  bool get isDemoEngine => false;

  @override
  String get engineLabel => 'Google Drive (public)';

  @override
  bool canHandle(Uri uri) => DriveLinks.parse(uri) != null;

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
    final link = DriveLinks.parse(uri);
    if (link == null) {
      throw const MediaFlowException(
        MediaFlowError(code: MediaFlowErrorCode.unsupportedUrl),
      );
    }

    try {
      if (link.isFolder) return await _probeFolder(link);
      if (link.isNative && _nativeExportFor(link) == null) {
        throw const MediaFlowException(
          MediaFlowError(
            code: MediaFlowErrorCode.unsupportedUrl,
            technicalDetails:
                'This Google-native file type has no public export path.',
          ),
        );
      }

      var title = _fallbackFileTitle(link);
      final fetched = await repository.fileTitle(link);
      if (fetched != null && fetched.trim().isNotEmpty) {
        title = fetched.trim();
      }
      return MediaDescriptor(
        sourceId: 'drive.google.com',
        sourceLabel: 'Google Drive',
        canonicalUrl: link.canonicalUrl,
        title: title,
        kind: MediaKind.file,
      );
    } on MediaFlowException {
      rethrow;
    } on DriveFolderParseException catch (error) {
      throw _fromParseError(error);
    } catch (error) {
      throw _probeError(error);
    }
  }

  Future<MediaDescriptor> _probeFolder(DriveLink link) async {
    final expansion = await DriveFolderExpander(
      loadFolder: repository.load,
      maxDepth: maxDepth,
      maxItems: maxItems,
    ).expand(link.id);

    final entries = <MediaEntry>[
      for (final file in expansion.files)
        MediaEntry(
          title: file.relativePath,
          url: file.url,
          kind: MediaKind.file,
          id: file.id,
          relativePath: file.relativePath,
          blockedCode: file.isNative && !_isSupportedNativeKind(file.nativeKind)
              ? MediaFlowErrorCode.unsupportedUrl
              : null,
        ),
      for (final skipped in expansion.skipped)
        MediaEntry(
          title: skipped.name,
          url: link.canonicalUrl,
          kind: MediaKind.file,
          id: skipped.id,
          blockedCode: MediaFlowErrorCode.collectionLimitReached,
        ),
    ];

    if (entries.isEmpty) {
      throw const MediaFlowException(
        MediaFlowError(
          code: MediaFlowErrorCode.emptyCollection,
          technicalDetails: 'The Drive folder has no downloadable files.',
        ),
      );
    }
    if (entries.every((entry) => entry.isBlocked)) {
      throw const MediaFlowException(
        MediaFlowError(
          code: MediaFlowErrorCode.unsupportedUrl,
          technicalDetails:
              'The Drive folder only contains entries this app cannot download.',
        ),
      );
    }

    return MediaDescriptor(
      sourceId: 'drive.google.com',
      sourceLabel: 'Google Drive',
      canonicalUrl: link.canonicalUrl,
      title: expansion.name,
      kind: MediaKind.collection,
      isCollection: true,
      itemCount: entries.length,
      entries: entries,
    );
  }

  static bool _isSupportedNativeKind(String? nativeKind) {
    return nativeKind == 'document' ||
        nativeKind == 'spreadsheet' ||
        nativeKind == 'presentation';
  }

  @override
  Stream<DownloadEvent> download(DownloadJob job) async* {
    if (_cancelled.remove(job.id)) {
      yield const DownloadCancelled();
      return;
    }

    if (job.isArchive) {
      yield* _archiveStream(job);
      return;
    }

    final uri = Uri.tryParse(job.url);
    final link = uri == null ? null : DriveLinks.parse(uri);
    if (link == null) {
      yield const DownloadFailed(
        MediaFlowError(code: MediaFlowErrorCode.invalidUrl),
      );
      return;
    }
    if (link.isFolder) {
      yield const DownloadFailed(
        MediaFlowError(code: MediaFlowErrorCode.unsupportedUrl),
      );
      return;
    }

    final running = _RunningDriveDownload();
    _running[job.id] = running;
    try {
      if (link.isNative) {
        final export = _nativeExportFor(link);
        if (export == null) {
          throw const MediaFlowException(
            MediaFlowError(
              code: MediaFlowErrorCode.unsupportedUrl,
              technicalDetails:
                  'This Google-native file type has no public export path.',
            ),
          );
        }
        await for (final event in _downloadFile(
          job: job,
          running: running,
          initialUri: export.uri,
          exportExtension: export.extension,
        )) {
          yield event;
        }
      } else {
        await for (final event in _downloadFile(
          job: job,
          running: running,
          initialUri: _downloadUri(link),
        )) {
          yield event;
        }
      }
    } on _DriveCancelled {
      yield const DownloadCancelled();
    } catch (error) {
      if (running.cancelled) {
        yield const DownloadCancelled();
      } else {
        yield DownloadFailed(_downloadError(error));
      }
    } finally {
      _running.remove(job.id);
    }
  }

  Stream<DownloadEvent> _archiveStream(DownloadJob job) async* {
    final running = _RunningDriveDownload();
    _running[job.id] = running;
    try {
      await for (final event in _downloadArchive(job, running)) {
        yield event;
      }
    } on _DriveCancelled {
      yield const DownloadCancelled();
    } catch (error) {
      if (running.cancelled) {
        yield const DownloadCancelled();
      } else {
        yield DownloadFailed(_downloadError(error));
      }
    } finally {
      _running.remove(job.id);
    }
  }

  Stream<DownloadEvent> _downloadArchive(
    DownloadJob job,
    _RunningDriveDownload running,
  ) async* {
    final entries = job.zipEntries;
    final skipped = <BatchFailure>[];
    final reportedEntries = <int>{};
    final files = <ZipArchiveEntry>[];
    Directory? staging;
    MediaFlowError? firstError;
    var processed = 0;
    var downloadedBytes = 0;

    try {
      if (entries.isEmpty) {
        yield const DownloadFailed(
          MediaFlowError(
            code: MediaFlowErrorCode.zipFailed,
            technicalDetails: 'The folder selection is empty.',
          ),
        );
        return;
      }

      staging = await _createStagingDirectory(job);
      for (var index = 0; index < entries.length; index++) {
        final entry = entries[index];
        if (running.cancelled) throw const _DriveCancelled();
        final blocked = entry.blockedCode;
        if (blocked != null) {
          skipped.add(_archiveIssue(job, entry, blocked));
          reportedEntries.add(index);
          processed++;
          yield _archiveProgress(
            processed: processed,
            entryCount: entries.length,
            downloadedBytes: downloadedBytes,
          );
          continue;
        }

        String? stagedPath;
        try {
          final source = _entrySource(entry);
          final child = DownloadJob(
            id: job.id,
            batchId: job.batchId,
            url: entry.url,
            sourceId: job.sourceId,
            sourceLabel: job.sourceLabel,
            title: entry.title,
            downloadType: job.downloadType,
            status: JobStatus.downloading,
            createdAt: DateTime.now(),
            relativePath: entry.relativePath,
          );

          await for (final event in _downloadFile(
            job: child,
            running: running,
            initialUri: source.uri,
            exportExtension: source.extension,
            baseDirectory: staging.path,
          )) {
            switch (event) {
              case DownloadProgress():
                yield _archiveProgress(
                  processed: processed,
                  entryCount: entries.length,
                  downloadedBytes: downloadedBytes + event.downloadedBytes,
                  currentFraction: event.fraction,
                  bytesPerSecond: event.bytesPerSecond,
                  eta: event.eta,
                );
              case DownloadCompleted():
                stagedPath = event.filePath;
                downloadedBytes += event.totalBytes;
              case DownloadFailed():
                throw MediaFlowException(event.error);
              case DownloadCancelled():
                throw const _DriveCancelled();
            }
          }
        } on _DriveCancelled {
          rethrow;
        } catch (error) {
          if (running.cancelled) throw const _DriveCancelled();
          final mapped = _downloadError(error);
          firstError ??= mapped;
          skipped.add(_archiveIssue(job, entry, mapped.code));
          reportedEntries.add(index);
          stagedPath = null;
        }

        if (stagedPath != null) {
          final file = File(stagedPath);
          files.add(
            ZipArchiveEntry(name: _relativeTo(staging, file), file: file),
          );
        }
        processed++;
        yield _archiveProgress(
          processed: processed,
          entryCount: entries.length,
          downloadedBytes: downloadedBytes,
        );
      }

      if (files.isEmpty) {
        yield DownloadFailed(
          firstError ??
              const MediaFlowError(
                code: MediaFlowErrorCode.zipFailed,
                technicalDetails: 'No files could be added to the ZIP archive.',
              ),
          skipped: skipped,
        );
        return;
      }

      final target = await _zipTarget(job.title);
      final part = File('${target.path}.part');
      await _deleteFile(part);
      var finalTarget = target;
      int zipBytes;
      try {
        final progressController = StreamController<DownloadEvent>();
        final write = const ZipArchiveWriter().write(
          target: part,
          entries: files,
          isCancelled: () => running.cancelled,
          onProgress: (progress) {
            progressController.add(
              DownloadProgress(
                fraction: (0.85 + progress.fraction * 0.15).clamp(0.0, 1.0),
                downloadedBytes: downloadedBytes + progress.bytesWritten,
                totalBytes: 0,
                partialPath: part.path,
              ),
            );
          },
        );
        unawaited(write.whenComplete(progressController.close));
        await for (final event in progressController.stream) {
          yield event;
        }
        zipBytes = await write;

        if (running.cancelled) throw const _DriveCancelled();
        try {
          await part.rename(finalTarget.path);
        } on FileSystemException {
          finalTarget = await _availableFile(finalTarget);
          await part.rename(finalTarget.path);
        }
      } on ZipArchiveCancelled {
        await _deleteFile(part);
        throw const _DriveCancelled();
      } catch (_) {
        await _deleteFile(part);
        rethrow;
      }

      yield DownloadCompleted(
        filePath: finalTarget.path,
        totalBytes: zipBytes,
        skipped: skipped,
      );
    } on _DriveCancelled {
      rethrow;
    } catch (error) {
      final mapped = _downloadError(error);
      for (var index = 0; index < entries.length; index++) {
        if (!reportedEntries.contains(index)) {
          skipped.add(_archiveIssue(job, entries[index], mapped.code));
        }
      }
      yield DownloadFailed(mapped, skipped: skipped);
    } finally {
      if (staging != null) {
        try {
          if (await staging.exists()) await staging.delete(recursive: true);
        } on FileSystemException {
          // A staging folder left behind is less important than the result.
        }
      }
    }
  }

  DownloadProgress _archiveProgress({
    required int processed,
    required int entryCount,
    required int downloadedBytes,
    double currentFraction = 0,
    double? bytesPerSecond,
    Duration? eta,
  }) {
    final fraction = ((processed + currentFraction) / entryCount * 0.85).clamp(
      0.0,
      1.0,
    );
    return DownloadProgress(
      fraction: fraction,
      downloadedBytes: downloadedBytes,
      totalBytes: 0,
      bytesPerSecond: bytesPerSecond,
      eta: eta,
    );
  }

  BatchFailure _archiveIssue(
    DownloadJob job,
    MediaEntry entry,
    MediaFlowErrorCode code,
  ) {
    return BatchFailure(
      jobId: job.id,
      title: entry.title,
      url: entry.url,
      code: code,
    );
  }

  _EntrySource _entrySource(MediaEntry entry) {
    final uri = Uri.tryParse(entry.url);
    final link = uri == null ? null : DriveLinks.parse(uri);
    if (link == null || link.isFolder) {
      throw const MediaFlowException(
        MediaFlowError(
          code: MediaFlowErrorCode.invalidUrl,
          technicalDetails: 'The folder entry is not a Drive file link.',
        ),
      );
    }
    if (link.isNative) {
      final export = _nativeExportFor(link);
      if (export == null) {
        throw const MediaFlowException(
          MediaFlowError(
            code: MediaFlowErrorCode.unsupportedUrl,
            technicalDetails:
                'This Google-native file type has no public export path.',
          ),
        );
      }
      return _EntrySource(uri: export.uri, extension: export.extension);
    }
    return _EntrySource(uri: _downloadUri(link));
  }

  Future<Directory> _createStagingDirectory(DownloadJob job) async {
    final base = Directory(outputDirectory).absolute;
    await base.create(recursive: true);
    final directory = Directory(
      [
        base.path,
        '.mediaflow_zip_${safeFileName(job.id)}_${DateTime.now().microsecondsSinceEpoch}',
      ].join(Platform.pathSeparator),
    );
    await directory.create(recursive: true);
    return directory;
  }

  Future<File> _zipTarget(String title) async {
    final base = Directory(outputDirectory).absolute;
    await base.create(recursive: true);
    var name = safeFileName(title);
    if (!name.toLowerCase().endsWith('.zip')) name = '$name.zip';
    return _availableFile(File([base.path, name].join(Platform.pathSeparator)));
  }

  String _relativeTo(Directory base, File file) {
    final basePath = base.path.endsWith(Platform.pathSeparator)
        ? base.path
        : '${base.path}${Platform.pathSeparator}';
    final path = file.absolute.path;
    final inside = Platform.isWindows
        ? path.toLowerCase().startsWith(basePath.toLowerCase())
        : path.startsWith(basePath);
    if (inside) {
      return path.substring(basePath.length).replaceAll('\\', '/');
    }
    return file.uri.pathSegments.isEmpty
        ? safeFileName(file.path)
        : file.uri.pathSegments.last;
  }

  Stream<DownloadEvent> _downloadFile({
    required DownloadJob job,
    required _RunningDriveDownload running,
    required Uri initialUri,
    String? exportExtension,
    String? baseDirectory,
  }) async* {
    var requestUri = initialUri;
    var attempts = 0;

    while (true) {
      if (running.cancelled) throw const _DriveCancelled();
      attempts++;
      final response = await transport.open(requestUri);
      running.response = response;

      if (running.cancelled) {
        response.abort();
        throw const _DriveCancelled();
      }
      if (!_isGoogleHost(response.finalUri.host)) {
        response.abort();
        throw const MediaFlowException(
          MediaFlowError(
            code: MediaFlowErrorCode.driveLayoutChanged,
            technicalDetails: 'Drive redirected to an unexpected host.',
          ),
        );
      }

      final statusError = driveErrorForStatus(response.statusCode);
      if (statusError != null) {
        var effective = statusError;
        if ((response.statusCode == 401 || response.statusCode == 403) &&
            mediaType(response.headers) == 'text/html') {
          try {
            final body = await _readLimited(response, running, _maxHtmlBytes);
            final access = DriveFolderParser.detectAccessError(body);
            if (access != null) {
              effective = MediaFlowError(
                code: access,
                technicalDetails: 'Drive returned a restricted HTML page.',
              );
            }
          } on _DriveCancelled {
            rethrow;
          } catch (_) {
            // Keep the status-based error if the body cannot be read.
          }
        }
        response.abort();
        throw MediaFlowException(effective);
      }

      final disposition = fileNameFromDisposition(
        response.header('content-disposition'),
      );
      final contentType = mediaType(response.headers);
      final isHtml =
          disposition == null &&
          (contentType == 'text/html' ||
              contentType == 'application/xhtml+xml');

      if (isHtml) {
        final body = await _readLimited(response, running, _maxHtmlBytes);
        if (running.cancelled) throw const _DriveCancelled();
        final access = DriveFolderParser.detectAccessError(body);
        if (access != null) {
          throw MediaFlowException(
            MediaFlowError(
              code: access,
              technicalDetails: 'Drive returned a restricted HTML page.',
            ),
          );
        }
        final next = DriveConfirmationForm.parse(body, response.finalUri);
        if (next == null || attempts >= 4) {
          throw const MediaFlowException(
            MediaFlowError(
              code: MediaFlowErrorCode.driveLayoutChanged,
              technicalDetails:
                  'Drive returned an HTML page instead of a file.',
            ),
          );
        }
        requestUri = next;
        continue;
      }

      await for (final event in _saveResponse(
        job: job,
        response: response,
        running: running,
        disposition: disposition,
        exportExtension: exportExtension,
        baseDirectory: baseDirectory,
      )) {
        yield event;
      }
      return;
    }
  }

  Stream<DownloadEvent> _saveResponse({
    required DownloadJob job,
    required DriveDownloadResponse response,
    required _RunningDriveDownload running,
    required String? disposition,
    required String? exportExtension,
    String? baseDirectory,
  }) async* {
    final target = await _resolveTarget(
      job: job,
      disposition: disposition,
      exportExtension: exportExtension,
      baseDirectory: baseDirectory,
    );
    final part = File('${target.path}.part');
    try {
      if (await part.exists()) await part.delete();
    } on FileSystemException {
      // openWrite truncates the partial file if it is still there.
    }

    final total = contentLength(response.headers) ?? 0;
    final sink = part.openWrite();
    var sinkClosed = false;
    var finished = false;
    var received = 0;
    final stopwatch = Stopwatch()..start();
    var lastReport = -1000;

    Future<void> closeSink({bool swallowErrors = false}) async {
      if (sinkClosed) return;
      sinkClosed = true;
      try {
        await sink.close();
      } catch (_) {
        if (!swallowErrors) rethrow;
        // The original download error is more useful than a close error.
      }
    }

    try {
      await for (final chunk in response.body) {
        if (running.cancelled) {
          response.abort();
          throw const _DriveCancelled();
        }
        sink.add(chunk);
        received += chunk.length;
        final elapsedMs = stopwatch.elapsedMilliseconds;
        if (received == chunk.length ||
            elapsedMs - lastReport >= 150 ||
            (total > 0 && received >= total)) {
          lastReport = elapsedMs;
          yield DownloadProgress(
            fraction: total > 0 ? (received / total).clamp(0.0, 1.0) : 0,
            downloadedBytes: received,
            totalBytes: total,
            bytesPerSecond: elapsedMs > 0 ? received * 1000 / elapsedMs : null,
            eta: _eta(received, total, elapsedMs),
            partialPath: part.path,
          );
        }
      }

      if (running.cancelled) throw const _DriveCancelled();
      final encoded =
          response.header('content-encoding') != null &&
          response.header('content-encoding')!.toLowerCase() != 'identity';
      if (!encoded && total > 0 && received != total) {
        throw const MediaFlowException(
          MediaFlowError(
            code: MediaFlowErrorCode.network,
            technicalDetails:
                'The Drive download ended before it was complete.',
            retryable: true,
          ),
        );
      }

      await closeSink();
      if (running.cancelled) throw const _DriveCancelled();
      await part.rename(target.path);
      if (running.cancelled) {
        await _deleteFile(target);
        throw const _DriveCancelled();
      }
      finished = true;
      yield DownloadCompleted(filePath: target.path, totalBytes: received);
    } catch (_) {
      await closeSink(swallowErrors: true);
      await _deleteFile(part);
      rethrow;
    } finally {
      if (!finished) {
        await closeSink(swallowErrors: true);
        await _deleteFile(part);
      }
    }
  }

  Future<String> _readLimited(
    DriveDownloadResponse response,
    _RunningDriveDownload running,
    int limit,
  ) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in response.body) {
      if (running.cancelled) {
        response.abort();
        throw const _DriveCancelled();
      }
      if (builder.length + chunk.length > limit) {
        response.abort();
        throw const MediaFlowException(
          MediaFlowError(
            code: MediaFlowErrorCode.driveLayoutChanged,
            technicalDetails: 'The Drive HTML page was too large to read.',
          ),
        );
      }
      builder.add(chunk);
    }
    return decodeUtf8(builder.takeBytes());
  }

  Future<File> _resolveTarget({
    required DownloadJob job,
    required String? disposition,
    required String? exportExtension,
    String? baseDirectory,
  }) async {
    final relative = job.relativePath?.trim();
    var candidate = relative == null || relative.isEmpty
        ? (disposition?.trim().isNotEmpty == true ? disposition! : job.title)
        : relative;
    if (exportExtension != null) {
      candidate = _replaceExtension(candidate, exportExtension);
    } else if (!_hasExtension(candidate)) {
      final extension = _extensionOf(disposition) ?? _extensionOf(job.title);
      if (extension != null) candidate = '$candidate.$extension';
    }

    final rawSegments = candidate.replaceAll('\\', '/').split('/');
    final segments = <String>[];
    for (final raw in rawSegments) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty || trimmed == '.' || trimmed == '..') continue;
      segments.add(safeFileName(trimmed));
    }
    if (segments.isEmpty) segments.add(safeFileName(job.title));

    final base = Directory(baseDirectory ?? outputDirectory).absolute;
    await base.create(recursive: true);
    var target = File([base.path, ...segments].join(Platform.pathSeparator));
    final basePath = base.path.endsWith(Platform.pathSeparator)
        ? base.path
        : '${base.path}${Platform.pathSeparator}';
    final targetPath = target.absolute.path;
    final inside = Platform.isWindows
        ? targetPath.toLowerCase().startsWith(basePath.toLowerCase())
        : targetPath.startsWith(basePath);
    if (!inside) {
      throw const MediaFlowException(
        MediaFlowError(
          code: MediaFlowErrorCode.invalidUrl,
          technicalDetails: 'The Drive file name escapes the output folder.',
        ),
      );
    }

    await target.parent.create(recursive: true);
    target = await _availableFile(target);
    return target;
  }

  Future<File> _availableFile(File file) async {
    if (!await file.exists()) return file;
    final separator = _lastSeparator(file.path);
    final dot = file.path.lastIndexOf('.');
    final hasExtension = dot > separator + 1;
    final stem = hasExtension ? file.path.substring(0, dot) : file.path;
    final extension = hasExtension ? file.path.substring(dot) : '';
    var counter = 1;
    while (true) {
      final candidate = File('$stem ($counter)$extension');
      if (!await candidate.exists()) return candidate;
      counter++;
    }
  }

  Future<void> _deleteFile(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // A locked partial file must not hide the original result.
    }
  }

  @override
  Future<void> cancel(String jobId) async {
    final running = _running[jobId];
    if (running == null) {
      _cancelled.add(jobId);
      return;
    }
    running.cancelled = true;
    running.response?.abort();
  }

  MediaFlowException _fromParseError(DriveFolderParseException error) {
    return MediaFlowException(
      MediaFlowError(code: error.code, technicalDetails: error.details),
    );
  }

  MediaFlowException _probeError(Object error) {
    if (error is MediaFlowException) return error;
    if (error is DriveFolderParseException) return _fromParseError(error);
    if (error is SocketException ||
        error is HttpException ||
        error is TimeoutException) {
      return const MediaFlowException(
        MediaFlowError(
          code: MediaFlowErrorCode.network,
          technicalDetails: 'Could not reach Google Drive.',
          retryable: true,
        ),
      );
    }
    return const MediaFlowException(
      MediaFlowError(
        code: MediaFlowErrorCode.unknown,
        technicalDetails: 'The Drive link could not be analyzed.',
      ),
    );
  }

  MediaFlowError _downloadError(Object error) {
    if (error is MediaFlowException) return error.error;
    if (error is DriveFolderParseException) {
      return MediaFlowError(code: error.code, technicalDetails: error.details);
    }
    if (error is FileSystemException) {
      return MediaFlowError(
        code: _fileSystemCode(error),
        technicalDetails: error.message,
      );
    }
    if (error is SocketException ||
        error is HttpException ||
        error is TimeoutException) {
      return const MediaFlowError(
        code: MediaFlowErrorCode.network,
        technicalDetails: 'The Drive download was interrupted.',
        retryable: true,
      );
    }
    return const MediaFlowError(
      code: MediaFlowErrorCode.unknown,
      technicalDetails: 'The Drive download failed.',
    );
  }

  static MediaFlowErrorCode _fileSystemCode(FileSystemException error) {
    final osCode = error.osError?.errorCode;
    if (osCode == 28 || osCode == 112) {
      return MediaFlowErrorCode.diskFull;
    }
    if (osCode == 13 || osCode == 1 || osCode == 5) {
      return MediaFlowErrorCode.permissionDenied;
    }
    final lower = error.message.toLowerCase();
    if (lower.contains('space') || lower.contains('enospc')) {
      return MediaFlowErrorCode.diskFull;
    }
    return MediaFlowErrorCode.unknown;
  }

  static Uri _downloadUri(DriveLink link) {
    return Uri.https('drive.google.com', '/uc', {
      'export': 'download',
      'id': link.id,
    });
  }

  static _NativeExport? _nativeExportFor(DriveLink link) {
    switch (link.nativeKind) {
      case 'document':
        return _NativeExport(
          extension: 'pdf',
          uri: Uri.https('docs.google.com', '/document/d/${link.id}/export', {
            'format': 'pdf',
          }),
        );
      case 'spreadsheet':
        return _NativeExport(
          extension: 'xlsx',
          uri: Uri.https(
            'docs.google.com',
            '/spreadsheets/d/${link.id}/export',
            {'format': 'xlsx'},
          ),
        );
      case 'presentation':
        return _NativeExport(
          extension: 'pptx',
          uri: Uri.https(
            'docs.google.com',
            '/presentation/d/${link.id}/export',
            {'format': 'pptx'},
          ),
        );
      default:
        return null;
    }
  }

  static String _fallbackFileTitle(DriveLink link) {
    final shortId = link.id.length > 6 ? link.id.substring(0, 6) : link.id;
    if (link.isNative) {
      return 'Google ${link.nativeKind ?? 'file'} $shortId';
    }
    return 'Drive file $shortId';
  }

  static bool _isGoogleHost(String host) {
    final lower = host.toLowerCase();
    return lower == 'drive.google.com' ||
        lower == 'drive.usercontent.google.com' ||
        lower == 'docs.google.com' ||
        lower.endsWith('.google.com') ||
        lower.endsWith('.googleusercontent.com');
  }

  static Duration? _eta(int received, int total, int elapsedMs) {
    if (total <= 0 || received <= 0 || elapsedMs <= 0 || received >= total) {
      return null;
    }
    final bytesPerMs = received / elapsedMs;
    if (bytesPerMs <= 0) return null;
    return Duration(milliseconds: ((total - received) / bytesPerMs).round());
  }

  static String _replaceExtension(String value, String extension) {
    final slash = _lastSeparator(value);
    final dot = value.lastIndexOf('.');
    if (dot > slash + 1) return '${value.substring(0, dot)}.$extension';
    return '$value.$extension';
  }

  static bool _hasExtension(String value) {
    final slash = _lastSeparator(value);
    final dot = value.lastIndexOf('.');
    return dot > slash + 1 && dot < value.length - 1;
  }

  static String? _extensionOf(String? value) {
    if (value == null) return null;
    final slash = _lastSeparator(value);
    final dot = value.lastIndexOf('.');
    if (dot <= slash + 1 || dot >= value.length - 1) return null;
    final extension = value.substring(dot + 1).toLowerCase();
    if (!RegExp(r'^[a-z0-9]{1,10}$').hasMatch(extension)) return null;
    return extension;
  }

  static int _lastSeparator(String value) {
    final slash = value.lastIndexOf('/');
    final backslash = value.lastIndexOf('\\');
    return slash > backslash ? slash : backslash;
  }
}

class _RunningDriveDownload {
  DriveDownloadResponse? response;
  bool cancelled = false;
}

class _DriveCancelled implements Exception {
  const _DriveCancelled();
}

class _NativeExport {
  final String extension;
  final Uri uri;

  const _NativeExport({required this.extension, required this.uri});
}

class _EntrySource {
  final Uri uri;
  final String? extension;

  const _EntrySource({required this.uri, this.extension});
}
