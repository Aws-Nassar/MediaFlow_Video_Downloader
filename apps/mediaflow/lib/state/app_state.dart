import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/media_models.dart';
import '../platform/platform_storage.dart';
import '../sources/fake_source_adapter.dart';
import '../sources/source_adapter.dart';
import '../storage/job_repository.dart';
import '../theme/studio_theme.dart';

class AppState extends ChangeNotifier {
  AppState({
    SourceAdapter? adapter,
    int concurrency = 2,
    this.outputDirectory = fallbackOutputDirectory,
    DiskSpaceProbe? diskSpaceProbe,
    this.repository,
  }) : adapter = adapter ?? FakeSourceAdapter(),
       concurrency = concurrency.clamp(1, 4),
       diskSpaceProbe = diskSpaceProbe ?? const PlatformDiskSpaceProbe() {
    registry = SourceRegistry([this.adapter]);
    final current = this.adapter;
    if (current is OutputDirectoryAware) {
      (current as OutputDirectoryAware).setOutputDirectory(outputDirectory);
    }
  }

  final SourceAdapter adapter;
  final DiskSpaceProbe diskSpaceProbe;
  late final SourceRegistry registry;

  Future<int?> availableDiskBytes() =>
      diskSpaceProbe.availableBytes(outputDirectory);

  final List<DownloadJob> _jobs = [];
  final List<BatchSummary> _summaries = [];
  final Map<String, DateTime> _batchStartedAt = {};
  final Set<String> _finalizedBatches = {};
  final Set<String> _activeJobIds = {};

  Locale locale = const Locale('en');
  AppStrings strings = const AppStrings(Locale('en'));
  StudioThemeMode themeMode = StudioThemeMode.dark;
  DownloadType downloadType = DownloadType.video;
  String outputDirectory;
  int concurrency;
  bool isAnalyzing = false;
  String? analyzeError;
  BatchSummary? lastSummary;
  String? persistenceError;

  final JobRepository? repository;
  final Map<String, DateTime> _lastProgressWrite = {};
  Future<void> _persistence = Future<void>.value();
  bool _initialized = false;
  bool _persistenceReady = false;

  int _jobCounter = 0;
  int _batchCounter = 0;
  bool _disposed = false;

  List<DownloadJob> get jobs => List.unmodifiable(_jobs);

  List<DownloadJob> get activeJobs =>
      _jobs.where((job) => job.status.isActive).toList();

  List<DownloadJob> get failedJobs =>
      _jobs.where((job) => job.status == JobStatus.failed).toList();

  List<DownloadJob> get completedJobs =>
      _jobs.where((job) => job.status == JobStatus.completed).toList();

  List<DownloadJob> get libraryJobs => completedJobs.reversed.toList();

  List<DownloadJob> get recentJobs =>
      _jobs.where((job) => job.isTerminal).toList().reversed.take(8).toList();

  List<BatchSummary> get summaries => List.unmodifiable(_summaries);

  int get activeCount => activeJobs.length;

  bool get isArabic => locale.languageCode == 'ar';

  String get engineLabel {
    final current = adapter;
    if (current is EngineInfo) {
      final info = current as EngineInfo;
      return info.isDemoEngine ? strings.fakeEngine : info.engineLabel;
    }
    return strings.fakeEngine;
  }

  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  /// Loads persisted queue entries and history.
  ///
  /// Interrupted downloads are put back in the queue. [autoStart] is exposed
  /// for tests that need to inspect the recovered queue before downloads start.
  Future<void> initialize({bool autoStart = true}) async {
    if (_initialized) return;
    _initialized = true;
    final repository = this.repository;
    if (repository == null) return;

    List<DownloadJob> loadedJobs;
    try {
      loadedJobs = await repository.loadJobs();
    } catch (error) {
      _recordPersistenceError('load queue', error);
      return;
    }

    var loadedSummaries = <BatchSummary>[];
    try {
      loadedSummaries = await repository.loadSummaries();
    } catch (error) {
      _recordPersistenceError('load history', error);
    }

    await _restoreJobs(loadedJobs, repository);
    _persistenceReady = true;

    final activeBatchIds = {
      for (final job in _jobs)
        if (job.status.isActive) job.batchId,
    };
    for (final summary in loadedSummaries) {
      if (activeBatchIds.contains(summary.batchId)) {
        try {
          await repository.deleteSummary(summary.batchId);
        } catch (error) {
          _recordPersistenceError('clear stale summary', error);
        }
        continue;
      }
      _summaries.add(summary);
      _finalizedBatches.add(summary.batchId);
    }
    lastSummary = _summaries.isEmpty ? null : _summaries.first;

    for (final job in _jobs) {
      final started = _batchStartedAt[job.batchId];
      if (started == null || job.createdAt.isBefore(started)) {
        _batchStartedAt[job.batchId] = job.createdAt;
      }
    }

    final loadedBatchIds = _jobs.map((job) => job.batchId).toSet();
    for (final batchId in loadedBatchIds) {
      _maybeFinalizeBatch(batchId);
    }

    _notify();
    if (autoStart) _schedule();
  }

  /// Waits until the persistence writes queued so far have completed.
  Future<void> flushPersistence() => _persistence;

  /// Starts queued jobs again, for example after a paused restore.
  void resumeQueue() => _schedule();

  Future<void> _restoreJobs(
    List<DownloadJob> loadedJobs,
    JobRepository repository,
  ) async {
    for (final job in loadedJobs) {
      if (job.status == JobStatus.probing) {
        try {
          await repository.deleteJob(job.id);
        } catch (error) {
          _recordPersistenceError('discard probe row', error);
        }
        continue;
      }
      if (job.status == JobStatus.downloading ||
          job.status == JobStatus.processing) {
        job.status = JobStatus.queued;
        job.progress = 0;
        job.downloadedBytes = 0;
        job.bytesPerSecond = null;
        job.eta = null;
        job.error = null;
        job.filePath = null;
        job.completedAt = null;
        try {
          await repository.saveJob(job);
        } catch (error) {
          _recordPersistenceError('restore interrupted job', error);
        }
      }
      _jobs.add(job);
    }
  }

  void setLocale(Locale value) {
    if (locale == value) return;
    locale = value;
    strings = AppStrings(value);
    _notify();
  }

  void setThemeMode(StudioThemeMode value) {
    if (themeMode == value) return;
    themeMode = value;
    _notify();
  }

  void setDownloadType(DownloadType value) {
    if (downloadType == value) return;
    downloadType = value;
    _notify();
  }

  void setConcurrency(int value) {
    final next = value.clamp(1, 4);
    if (concurrency == next) return;
    concurrency = next;
    _notify();
    _schedule();
  }

  void setOutputDirectory(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    outputDirectory = trimmed;
    final current = adapter;
    if (current is OutputDirectoryAware) {
      (current as OutputDirectoryAware).setOutputDirectory(trimmed);
    }
    _notify();
  }

  Future<void> analyzeAndEnqueue(
    String rawInput, {
    Future<CollectionSelection?> Function(MediaDescriptor descriptor)?
    selectCollection,
  }) async {
    if (isAnalyzing) return;
    final urls = rawInput
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (urls.isEmpty) {
      analyzeError = strings.enterAtLeastOneLink;
      _notify();
      return;
    }

    isAnalyzing = true;
    analyzeError = null;
    _notify();

    final batchId = _nextBatchId();
    _batchStartedAt[batchId] = DateTime.now();
    final seen = <String>{};

    try {
      for (final raw in urls) {
        if (!seen.add(raw)) continue;
        final uri = Uri.tryParse(raw);
        final valid =
            uri != null &&
            (uri.scheme == 'http' || uri.scheme == 'https') &&
            uri.host.isNotEmpty;

        if (!valid) {
          final job = _newJob(
            batchId: batchId,
            url: raw,
            fallbackTitle: raw.length > 48 ? shortUrl(raw, max: 48) : raw,
            sourceLabel: strings.sourceUnknown,
            sourceId: 'unknown',
            status: JobStatus.failed,
            error: const MediaFlowError(code: MediaFlowErrorCode.invalidUrl),
          );
          _jobs.add(job);
          _persistJob(job);
          _notify();
          continue;
        }

        final label = SourceRegistry.labelFor(uri);
        final job = _newJob(
          batchId: batchId,
          url: raw,
          fallbackTitle: SourceRegistry.fallbackTitle(uri),
          sourceLabel: label,
          sourceId: SourceRegistry.sourceIdFor(uri),
          status: JobStatus.probing,
        );
        _jobs.add(job);
        _notify();

        try {
          final descriptor = await adapter.probe(
            uri,
            downloadType: downloadType,
          );

          if (descriptor.isCollection && descriptor.entries.isNotEmpty) {
            final entries = descriptor.entries;
            CollectionSelection? selection;
            try {
              selection = selectCollection == null
                  ? CollectionSelection(entries: entries)
                  : await selectCollection(descriptor);
            } catch (error) {
              job.status = JobStatus.failed;
              job.error = _errorFrom(error);
              _persistJob(job);
              _notify();
              continue;
            }

            _jobs.remove(job);
            if (selection == null) {
              _notify();
              continue;
            }

            final selected = selection.entries.toSet();
            if (selection.asZip) {
              final zipEntries = [
                for (final entry in entries)
                  if (entry.isBlocked || selected.contains(entry)) entry,
              ];
              final downloadable = zipEntries
                  .where((entry) => !entry.isBlocked)
                  .length;
              if (downloadable == 0) {
                final failed = _newJob(
                  batchId: batchId,
                  url: descriptor.canonicalUrl,
                  fallbackTitle: descriptor.title,
                  sourceLabel: descriptor.sourceLabel,
                  sourceId: descriptor.sourceId,
                  status: JobStatus.failed,
                  error: const MediaFlowError(
                    code: MediaFlowErrorCode.emptyCollection,
                    technicalDetails: 'No downloadable files were selected.',
                  ),
                );
                _jobs.add(failed);
                _persistJob(failed);
                _notify();
                continue;
              }

              final archive = _newJob(
                batchId: batchId,
                url: descriptor.canonicalUrl,
                fallbackTitle: descriptor.title,
                sourceLabel: descriptor.sourceLabel,
                sourceId: descriptor.sourceId,
                status: JobStatus.queued,
                zipEntries: zipEntries,
              );
              archive.title = descriptor.title;
              archive.itemCount = 1;
              _jobs.add(archive);
              _persistJob(archive);
              _notify();
              continue;
            }

            final children = <DownloadJob>[];
            for (final entry in entries) {
              final blocked = entry.blockedCode;
              if (blocked != null) {
                final child = _newJob(
                  batchId: batchId,
                  url: entry.url,
                  fallbackTitle: entry.title,
                  sourceLabel: descriptor.sourceLabel,
                  sourceId: descriptor.sourceId,
                  status: JobStatus.skipped,
                  error: MediaFlowError(
                    code: blocked,
                    technicalDetails: 'The folder entry cannot be downloaded.',
                  ),
                  relativePath: entry.relativePath,
                );
                child.title = entry.title;
                child.totalBytes = entry.sizeBytes;
                children.add(child);
                continue;
              }
              if (!selected.contains(entry)) continue;

              final child = _newJob(
                batchId: batchId,
                url: entry.url,
                fallbackTitle: entry.title,
                sourceLabel: descriptor.sourceLabel,
                sourceId: descriptor.sourceId,
                status: JobStatus.queued,
                relativePath: entry.relativePath,
              );
              child.title = entry.title;
              child.totalBytes = entry.sizeBytes;
              child.itemIndex = children.length + 1;
              child.itemCount = entries.length;
              children.add(child);
            }

            for (var i = 0; i < children.length; i++) {
              children[i].itemIndex = i + 1;
              children[i].itemCount = children.length;
            }
            _jobs.addAll(children);
            for (final child in children) {
              _persistJob(child);
            }
            _notify();
          } else if (descriptor.isCollection && descriptor.itemCount > 1) {
            _jobs.remove(job);
            final perItemBytes = descriptor.totalBytes == null
                ? null
                : descriptor.totalBytes! ~/ descriptor.itemCount;
            for (var i = 1; i <= descriptor.itemCount; i++) {
              final child = _newJob(
                batchId: batchId,
                url: raw,
                fallbackTitle: '${descriptor.title} · ${strings.item} $i',
                sourceLabel: descriptor.sourceLabel,
                sourceId: descriptor.sourceId,
                status: JobStatus.queued,
              );
              child.title = '${descriptor.title} · ${strings.item} $i';
              child.totalBytes = perItemBytes;
              child.itemIndex = i;
              child.itemCount = descriptor.itemCount;
              _jobs.add(child);
              _persistJob(child);
            }
            _notify();
          } else {
            job.title = descriptor.title;
            job.sourceId = descriptor.sourceId;
            job.sourceLabel = descriptor.sourceLabel;
            job.totalBytes = descriptor.totalBytes;
            job.status = JobStatus.queued;
            _persistJob(job);
            _notify();
          }
        } catch (error) {
          job.status = JobStatus.failed;
          job.error = _errorFrom(error);
          _persistJob(job);
          _notify();
        }
      }
    } finally {
      isAnalyzing = false;
      _notify();
      _schedule();
      _maybeFinalizeBatch(batchId);
    }
  }

  String _nextJobId() {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final counter = (++_jobCounter).toString().padLeft(6, '0');
    return 'job-$stamp-$counter';
  }

  String _nextBatchId() {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final counter = (++_batchCounter).toString().padLeft(6, '0');
    return 'batch-$stamp-$counter';
  }

  DownloadJob _newJob({
    required String batchId,
    required String url,
    required String fallbackTitle,
    required String sourceLabel,
    required String sourceId,
    required JobStatus status,
    MediaFlowError? error,
    String? relativePath,
    List<MediaEntry> zipEntries = const [],
  }) {
    return DownloadJob(
      id: _nextJobId(),
      batchId: batchId,
      url: url,
      sourceId: sourceId,
      sourceLabel: sourceLabel,
      title: fallbackTitle,
      downloadType: downloadType,
      status: status,
      error: error,
      relativePath: relativePath,
      zipEntries: zipEntries,
      createdAt: DateTime.now(),
    );
  }

  void _schedule() {
    if (_disposed) return;
    while (_activeJobIds.length < concurrency) {
      DownloadJob? next;
      for (final job in _jobs) {
        if (job.status == JobStatus.queued && !_activeJobIds.contains(job.id)) {
          next = job;
          break;
        }
      }
      if (next == null) break;
      unawaited(_startJob(next));
    }
  }

  Future<void> _startJob(DownloadJob job) async {
    if (_activeJobIds.contains(job.id) || job.status.isTerminal) return;
    _activeJobIds.add(job.id);
    job.status = JobStatus.downloading;
    job.error = null;
    job.progress = 0;
    job.downloadedBytes = 0;
    job.bytesPerSecond = null;
    job.eta = null;
    _persistJob(job);
    _notify();

    try {
      await for (final event in adapter.download(job)) {
        if (_disposed || !_jobs.contains(job)) return;
        switch (event) {
          case DownloadProgress():
            job.status = JobStatus.downloading;
            job.progress = event.fraction.clamp(0, 1);
            job.downloadedBytes = event.downloadedBytes;
            job.totalBytes = event.totalBytes;
            job.bytesPerSecond = event.bytesPerSecond;
            job.eta = event.eta;
            _persistProgress(job);
            _notify();
          case DownloadCompleted():
            job.status = JobStatus.completed;
            job.progress = 1;
            job.filePath = event.filePath;
            job.totalBytes = event.totalBytes;
            job.bytesPerSecond = null;
            job.eta = null;
            job.itemSkipped = List.of(event.skipped);
            job.completedAt = DateTime.now();
            _persistJob(job);
            _notify();
          case DownloadFailed():
            job.status = JobStatus.failed;
            job.error = event.error;
            job.itemSkipped = List.of(event.skipped);
            job.bytesPerSecond = null;
            job.eta = null;
            _persistJob(job);
            _notify();
          case DownloadCancelled():
            job.status = JobStatus.cancelled;
            job.bytesPerSecond = null;
            job.eta = null;
            _persistJob(job);
            _notify();
        }
      }
    } catch (error) {
      if (_jobs.contains(job)) {
        job.status = JobStatus.failed;
        job.error = _errorFrom(error);
        _persistJob(job);
        _notify();
      }
    } finally {
      if (_jobs.contains(job) && !job.status.isTerminal) {
        job.status = JobStatus.failed;
        job.error = const MediaFlowError(
          code: MediaFlowErrorCode.unknown,
          technicalDetails: 'The engine ended without a terminal event.',
        );
        _persistJob(job);
      }
      _activeJobIds.remove(job.id);
      _notify();
      _schedule();
      _maybeFinalizeBatch(job.batchId);
    }
  }

  void _maybeFinalizeBatch(String batchId) {
    if (_disposed) return;
    if (_finalizedBatches.contains(batchId)) return;
    final batchJobs = _jobs.where((job) => job.batchId == batchId).toList();
    if (batchJobs.isEmpty) return;
    if (batchJobs.any((job) => !job.isTerminal)) return;

    final failures = <BatchFailure>[];
    final skippedItems = <BatchFailure>[];
    var total = 0;
    var completedCount = 0;
    var failedCount = 0;
    var skippedCount = 0;
    var cancelledCount = 0;
    var totalBytes = 0;

    for (final job in batchJobs) {
      if (job.isArchive) {
        final itemCount = job.zipEntries.length;
        total += itemCount;
        skippedItems.addAll(job.itemSkipped);
        skippedCount += job.itemSkipped.length;
        final unaccounted = (itemCount - job.itemSkipped.length).clamp(
          0,
          itemCount,
        );
        switch (job.status) {
          case JobStatus.completed:
            completedCount += unaccounted;
            totalBytes += job.totalBytes ?? 0;
          case JobStatus.failed:
            if (unaccounted > 0) {
              failedCount += unaccounted;
              failures.add(
                BatchFailure(
                  jobId: job.id,
                  title: job.title,
                  url: job.url,
                  code: job.error?.code ?? MediaFlowErrorCode.zipFailed,
                ),
              );
            }
          case JobStatus.cancelled:
            cancelledCount += unaccounted;
          default:
            break;
        }
        continue;
      }

      total++;
      switch (job.status) {
        case JobStatus.completed:
          completedCount++;
          totalBytes += job.totalBytes ?? 0;
        case JobStatus.failed:
          failedCount++;
          failures.add(
            BatchFailure(
              jobId: job.id,
              title: job.title,
              url: job.url,
              code: job.error?.code ?? MediaFlowErrorCode.unknown,
            ),
          );
        case JobStatus.skipped:
          skippedCount++;
          skippedItems.add(
            BatchFailure(
              jobId: job.id,
              title: job.title,
              url: job.url,
              code: job.error?.code ?? MediaFlowErrorCode.unknown,
            ),
          );
        case JobStatus.cancelled:
          cancelledCount++;
        default:
          break;
      }
    }

    final started =
        _batchStartedAt[batchId] ??
        batchJobs
            .map((job) => job.createdAt)
            .reduce((a, b) => a.isBefore(b) ? a : b);
    final summary = BatchSummary(
      batchId: batchId,
      total: total,
      completed: completedCount,
      failed: failedCount,
      skipped: skippedCount,
      cancelled: cancelledCount,
      totalBytes: totalBytes,
      elapsed: DateTime.now().difference(started),
      failures: failures,
      skippedItems: skippedItems,
    );
    _summaries.removeWhere((existing) => existing.batchId == batchId);
    _summaries.insert(0, summary);
    lastSummary = summary;
    _finalizedBatches.add(batchId);
    _persistSummary(summary);
    _notify();
  }

  Future<void> cancelJob(String jobId) async {
    final job = _findJob(jobId);
    if (job == null || job.status.isTerminal) return;
    await adapter.cancel(jobId);
  }

  Future<void> removeJob(String jobId) async {
    final job = _findJob(jobId);
    if (job == null) return;
    if (job.status.isActive) {
      await adapter.cancel(jobId);
    }
    _jobs.remove(job);
    _activeJobIds.remove(jobId);
    _removeSummaryForBatch(job.batchId);
    _deletePersistedJob(jobId);
    _notify();
    _maybeFinalizeBatch(job.batchId);
  }

  Future<void> retryJob(String jobId) async {
    final job = _findJob(jobId);
    if (job == null || job.status.isActive) return;
    if (job.status == JobStatus.completed) return;
    _resetJob(job);
    _removeSummaryForBatch(job.batchId);
    _persistJob(job);
    _batchStartedAt[job.batchId] = DateTime.now();
    _notify();
    _schedule();
  }

  void retryFailed() {
    final summary = lastSummary;
    if (summary == null || summary.failures.isEmpty) return;
    final reset = <DownloadJob>[];
    for (final failure in summary.failures) {
      final job = _findJob(failure.jobId);
      if (job != null && job.status == JobStatus.failed) {
        _resetJob(job);
        reset.add(job);
      }
    }
    if (reset.isEmpty) return;
    _removeSummaryForBatch(summary.batchId);
    for (final job in reset) {
      _persistJob(job);
    }
    _batchStartedAt[summary.batchId] = DateTime.now();
    _notify();
    _schedule();
  }

  void _resetJob(DownloadJob job) {
    job.status = JobStatus.queued;
    job.progress = 0;
    job.downloadedBytes = 0;
    job.bytesPerSecond = null;
    job.eta = null;
    job.error = null;
    job.filePath = null;
    job.completedAt = null;
    job.itemSkipped = [];
  }

  void dismissSummary() {
    if (lastSummary == null) return;
    lastSummary = null;
    _notify();
  }

  void _persistJob(DownloadJob job) {
    if (!_persistenceReady || !_jobs.contains(job)) return;
    _lastProgressWrite.remove(job.id);
    _enqueuePersistence((repository) => repository.saveJob(job));
  }

  void _persistProgress(DownloadJob job) {
    if (!_persistenceReady || !_jobs.contains(job)) return;
    final now = DateTime.now();
    final last = _lastProgressWrite[job.id];
    if (last != null && now.difference(last) < const Duration(seconds: 1)) {
      return;
    }
    _lastProgressWrite[job.id] = now;
    _enqueuePersistence((repository) => repository.saveJobProgress(job));
  }

  void _persistSummary(BatchSummary summary) {
    _enqueuePersistence((repository) => repository.saveSummary(summary));
  }

  void _deletePersistedJob(String jobId) {
    _lastProgressWrite.remove(jobId);
    _enqueuePersistence((repository) => repository.deleteJob(jobId));
  }

  void _deletePersistedSummary(String batchId) {
    _enqueuePersistence((repository) => repository.deleteSummary(batchId));
  }

  void _removeSummaryForBatch(String batchId) {
    _summaries.removeWhere((summary) => summary.batchId == batchId);
    if (lastSummary?.batchId == batchId) lastSummary = null;
    _finalizedBatches.remove(batchId);
    _deletePersistedSummary(batchId);
  }

  void _enqueuePersistence(
    Future<void> Function(JobRepository repository) action,
  ) {
    final repository = _persistenceReady ? this.repository : null;
    if (repository == null) return;
    _persistence = _persistence.then((_) async {
      try {
        await action(repository);
      } catch (error) {
        _recordPersistenceError('write', error);
      }
    });
  }

  void _recordPersistenceError(String operation, Object error) {
    persistenceError = '$operation: $error';
    debugPrint('MediaFlow persistence $operation failed: $error');
  }

  DownloadJob? _findJob(String id) {
    for (final job in _jobs) {
      if (job.id == id) return job;
    }
    return null;
  }

  MediaFlowError _errorFrom(Object error) {
    if (error is MediaFlowException) return error.error;
    return MediaFlowError(
      code: MediaFlowErrorCode.unknown,
      technicalDetails: error.toString(),
    );
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
