import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/media_models.dart';
import '../sources/fake_source_adapter.dart';
import '../sources/source_adapter.dart';
import '../theme/studio_theme.dart';

class AppState extends ChangeNotifier {
  AppState({
    SourceAdapter? adapter,
    int concurrency = 2,
    this.outputDirectory = 'Downloads/MediaFlow',
  }) : adapter = adapter ?? FakeSourceAdapter(),
       concurrency = concurrency.clamp(1, 4) {
    registry = SourceRegistry([this.adapter]);
    final current = this.adapter;
    if (current is OutputDirectoryAware) {
      (current as OutputDirectoryAware).setOutputDirectory(outputDirectory);
    }
  }

  final SourceAdapter adapter;
  late final SourceRegistry registry;

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

  Future<void> analyzeAndEnqueue(String rawInput) async {
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

    final batchId = 'batch-${++_batchCounter}';
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

          if (descriptor.isCollection && descriptor.itemCount > 1) {
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
            }
            _notify();
          } else {
            job.title = descriptor.title;
            job.sourceId = descriptor.sourceId;
            job.sourceLabel = descriptor.sourceLabel;
            job.totalBytes = descriptor.totalBytes;
            job.status = JobStatus.queued;
            _notify();
          }
        } catch (error) {
          job.status = JobStatus.failed;
          job.error = _errorFrom(error);
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

  DownloadJob _newJob({
    required String batchId,
    required String url,
    required String fallbackTitle,
    required String sourceLabel,
    required String sourceId,
    required JobStatus status,
    MediaFlowError? error,
  }) {
    return DownloadJob(
      id: 'job-${++_jobCounter}',
      batchId: batchId,
      url: url,
      sourceId: sourceId,
      sourceLabel: sourceLabel,
      title: fallbackTitle,
      downloadType: downloadType,
      status: status,
      error: error,
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
    _notify();

    try {
      await for (final event in adapter.download(job)) {
        if (_disposed) return;
        switch (event) {
          case DownloadProgress():
            job.status = JobStatus.downloading;
            job.progress = event.fraction.clamp(0, 1);
            job.downloadedBytes = event.downloadedBytes;
            job.totalBytes = event.totalBytes;
            job.bytesPerSecond = event.bytesPerSecond;
            job.eta = event.eta;
            _notify();
          case DownloadCompleted():
            job.status = JobStatus.completed;
            job.progress = 1;
            job.filePath = event.filePath;
            job.totalBytes = event.totalBytes;
            job.bytesPerSecond = null;
            job.eta = null;
            job.completedAt = DateTime.now();
            _notify();
          case DownloadFailed():
            job.status = JobStatus.failed;
            job.error = event.error;
            job.bytesPerSecond = null;
            job.eta = null;
            _notify();
          case DownloadCancelled():
            job.status = JobStatus.cancelled;
            job.bytesPerSecond = null;
            job.eta = null;
            _notify();
        }
      }
    } catch (error) {
      job.status = JobStatus.failed;
      job.error = _errorFrom(error);
      _notify();
    } finally {
      if (!job.status.isTerminal) {
        job.status = JobStatus.failed;
        job.error = const MediaFlowError(
          code: MediaFlowErrorCode.unknown,
          technicalDetails: 'The engine ended without a terminal event.',
        );
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

    final completed = batchJobs
        .where((job) => job.status == JobStatus.completed)
        .toList();
    final failures = batchJobs
        .where((job) => job.status == JobStatus.failed)
        .map(
          (job) => BatchFailure(
            jobId: job.id,
            title: job.title,
            url: job.url,
            code: job.error?.code ?? MediaFlowErrorCode.unknown,
          ),
        )
        .toList();
    final started =
        _batchStartedAt[batchId] ??
        batchJobs
            .map((job) => job.createdAt)
            .reduce((a, b) => a.isBefore(b) ? a : b);
    final summary = BatchSummary(
      batchId: batchId,
      total: batchJobs.length,
      completed: completed.length,
      failed: failures.length,
      skipped: batchJobs.where((job) => job.status == JobStatus.skipped).length,
      cancelled: batchJobs
          .where((job) => job.status == JobStatus.cancelled)
          .length,
      totalBytes: completed.fold<int>(
        0,
        (sum, job) => sum + (job.totalBytes ?? 0),
      ),
      elapsed: DateTime.now().difference(started),
      failures: failures,
    );
    _summaries.insert(0, summary);
    lastSummary = summary;
    _finalizedBatches.add(batchId);
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
    if (lastSummary?.batchId == job.batchId) {
      lastSummary = null;
    }
    _finalizedBatches.remove(job.batchId);
    _notify();
    _maybeFinalizeBatch(job.batchId);
  }

  Future<void> retryJob(String jobId) async {
    final job = _findJob(jobId);
    if (job == null || job.status.isActive) return;
    if (job.status == JobStatus.completed) return;
    _resetJob(job);
    _finalizedBatches.remove(job.batchId);
    if (lastSummary?.batchId == job.batchId) lastSummary = null;
    _batchStartedAt[job.batchId] = DateTime.now();
    _notify();
    _schedule();
  }

  void retryFailed() {
    final summary = lastSummary;
    if (summary == null || summary.failures.isEmpty) return;
    var changed = false;
    for (final failure in summary.failures) {
      final job = _findJob(failure.jobId);
      if (job != null && job.status == JobStatus.failed) {
        _resetJob(job);
        changed = true;
      }
    }
    if (!changed) return;
    _finalizedBatches.remove(summary.batchId);
    lastSummary = null;
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
  }

  void dismissSummary() {
    if (lastSummary == null) return;
    lastSummary = null;
    _notify();
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
