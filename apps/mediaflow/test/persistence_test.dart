import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediaflow/models/media_models.dart';
import 'package:mediaflow/sources/fake_source_adapter.dart';
import 'package:mediaflow/sources/source_adapter.dart';
import 'package:mediaflow/state/app_state.dart';
import 'package:mediaflow/storage/app_database.dart';
import 'package:mediaflow/storage/drift_job_repository.dart';

void main() {
  late AppDatabase database;
  late DriftJobRepository repository;
  var databaseClosedByTest = false;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = DriftJobRepository(database);
    databaseClosedByTest = false;
  });

  tearDown(() async {
    if (!databaseClosedByTest) await repository.close();
  });

  test(
    'round-trips a job with errors, archive entries, and skipped items',
    () async {
      final created = DateTime(2026, 10, 27, 13, 40, 5);
      final completed = DateTime(2026, 10, 27, 13, 41, 9);
      final job = DownloadJob(
        id: 'job-round-trip',
        batchId: 'batch-round-trip',
        url: 'https://example.com/folder',
        sourceId: 'drive.google.com',
        sourceLabel: 'Google Drive',
        title: 'Folder archive',
        downloadType: DownloadType.audio,
        status: JobStatus.failed,
        progress: 0.42,
        downloadedBytes: 512,
        totalBytes: 2048,
        bytesPerSecond: 1024.5,
        eta: const Duration(seconds: 17),
        error: const MediaFlowError(
          code: MediaFlowErrorCode.permissionDenied,
          technicalDetails: 'The owner disabled downloads.',
          retryable: true,
        ),
        filePath: 'Downloads/MediaFlow/folder.zip',
        relativePath: 'nested/file.mp3',
        createdAt: created,
        completedAt: completed,
        itemIndex: 2,
        itemCount: 4,
        zipEntries: const [
          MediaEntry(
            title: 'clip.mp4',
            url: 'https://example.com/clip.mp4',
            sizeBytes: 2048,
            kind: MediaKind.video,
            id: 'entry-1',
            relativePath: 'nested/clip.mp4',
          ),
          MediaEntry(
            title: 'blocked.mp4',
            url: 'https://example.com/blocked.mp4',
            kind: MediaKind.file,
            blockedCode: MediaFlowErrorCode.downloadRestricted,
          ),
        ],
        itemSkipped: const [
          BatchFailure(
            jobId: 'entry-2',
            title: 'blocked.mp4',
            url: 'https://example.com/blocked.mp4',
            code: MediaFlowErrorCode.downloadRestricted,
          ),
        ],
      );

      await repository.saveJob(job);
      final loaded = (await repository.loadJobs()).single;

      expect(loaded.id, job.id);
      expect(loaded.batchId, job.batchId);
      expect(loaded.url, job.url);
      expect(loaded.sourceId, job.sourceId);
      expect(loaded.sourceLabel, job.sourceLabel);
      expect(loaded.title, job.title);
      expect(loaded.downloadType, DownloadType.audio);
      expect(loaded.status, JobStatus.failed);
      expect(loaded.progress, closeTo(0.42, 0.0001));
      expect(loaded.downloadedBytes, 512);
      expect(loaded.totalBytes, 2048);
      expect(loaded.bytesPerSecond, closeTo(1024.5, 0.0001));
      expect(loaded.eta, const Duration(seconds: 17));
      expect(loaded.error?.code, MediaFlowErrorCode.permissionDenied);
      expect(loaded.error?.technicalDetails, 'The owner disabled downloads.');
      expect(loaded.error?.retryable, isTrue);
      expect(loaded.filePath, job.filePath);
      expect(loaded.relativePath, job.relativePath);
      expect(loaded.createdAt.toUtc(), created.toUtc());
      expect(loaded.completedAt?.toUtc(), completed.toUtc());
      expect(loaded.itemIndex, 2);
      expect(loaded.itemCount, 4);
      expect(loaded.zipEntries, hasLength(2));
      expect(loaded.zipEntries.first.kind, MediaKind.video);
      expect(loaded.zipEntries.first.sizeBytes, 2048);
      expect(loaded.zipEntries.first.id, 'entry-1');
      expect(loaded.zipEntries.first.relativePath, 'nested/clip.mp4');
      expect(
        loaded.zipEntries.last.blockedCode,
        MediaFlowErrorCode.downloadRestricted,
      );
      expect(loaded.itemSkipped, hasLength(1));
      expect(loaded.itemSkipped.single.jobId, 'entry-2');
      expect(
        loaded.itemSkipped.single.code,
        MediaFlowErrorCode.downloadRestricted,
      );
    },
  );

  test(
    'progress writes update download fields without dropping entries',
    () async {
      final job = _job(
        id: 'job-progress',
        status: JobStatus.downloading,
        progress: 0.1,
        zipEntries: const [
          MediaEntry(title: 'one.mp4', url: 'https://example.com/one.mp4'),
        ],
      );
      await repository.saveJob(job);

      job.status = JobStatus.processing;
      job.progress = 0.8;
      job.downloadedBytes = 800;
      job.totalBytes = 1000;
      job.bytesPerSecond = 42;
      job.eta = const Duration(seconds: 2);
      await repository.saveJobProgress(job);

      final loaded = (await repository.loadJobs()).single;
      expect(loaded.status, JobStatus.processing);
      expect(loaded.progress, closeTo(0.8, 0.0001));
      expect(loaded.downloadedBytes, 800);
      expect(loaded.totalBytes, 1000);
      expect(loaded.bytesPerSecond, closeTo(42, 0.0001));
      expect(loaded.eta, const Duration(seconds: 2));
      expect(loaded.zipEntries, hasLength(1));
    },
  );

  test('summaries load newest first', () async {
    final first = _summary('batch-first', completed: 1);
    final second = _summary('batch-second', completed: 2, failed: 1);
    await repository.saveSummary(first);
    await repository.saveSummary(second);

    final loaded = await repository.loadSummaries();

    expect(loaded.map((summary) => summary.batchId), [
      'batch-second',
      'batch-first',
    ]);
    expect(loaded.first.completed, 2);
    expect(loaded.first.failures.single.title, 'failed.mp4');
    expect(loaded.first.skippedItems.single.title, 'blocked.mp4');
  });

  test('the database file survives close and reopen', () async {
    final directory = await Directory.systemTemp.createTemp('mediaflow_db_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File(
      '${directory.path}${Platform.pathSeparator}mediaflow.sqlite',
    );

    // Close the per-test in-memory database before opening the file database
    // so Drift only sees one connection at a time.
    await repository.close();
    databaseClosedByTest = true;

    final firstDatabase = AppDatabase(NativeDatabase(file));
    final firstRepository = DriftJobRepository(firstDatabase);
    await firstRepository.saveJob(
      _job(
        id: 'job-file',
        batchId: 'batch-file',
        status: JobStatus.completed,
        progress: 1,
        filePath: 'Downloads/MediaFlow/file.mp4',
      ),
    );
    await firstRepository.saveSummary(_summary('batch-file', completed: 1));
    await firstRepository.close();
    expect(await file.exists(), isTrue);

    final reopenedDatabase = AppDatabase(NativeDatabase(file));
    final reopenedRepository = DriftJobRepository(reopenedDatabase);
    addTearDown(reopenedRepository.close);

    final jobs = await reopenedRepository.loadJobs();
    final summaries = await reopenedRepository.loadSummaries();
    expect(jobs.single.id, 'job-file');
    expect(jobs.single.filePath, 'Downloads/MediaFlow/file.mp4');
    expect(summaries.single.batchId, 'batch-file');
  });

  test('restores history and requeues interrupted downloads', () async {
    final history = _job(
      id: 'job-history',
      batchId: 'batch-history',
      status: JobStatus.completed,
      progress: 1,
      filePath: 'Downloads/MediaFlow/history.mp4',
      completedAt: DateTime(2026, 10, 27, 13, 40, 5),
    );
    final interrupted = _job(
      id: 'job-interrupted',
      batchId: 'batch-interrupted',
      status: JobStatus.downloading,
      progress: 0.55,
      downloadedBytes: 550,
    );
    await repository.saveJob(history);
    await repository.saveJob(interrupted);
    await repository.saveSummary(
      _summary('batch-history', completed: 1, failures: const []),
    );

    final state = AppState(
      adapter: FakeSourceAdapter(
        probeDelay: Duration.zero,
        stepDelay: Duration.zero,
        steps: 1,
      ),
      concurrency: 1,
      repository: repository,
    );
    addTearDown(state.dispose);

    await state.initialize(autoStart: false);

    expect(state.jobs, hasLength(2));
    expect(state.libraryJobs.single.id, 'job-history');
    expect(state.lastSummary?.batchId, 'batch-history');
    expect(
      state.jobs.singleWhere((job) => job.id == 'job-interrupted').status,
      JobStatus.queued,
    );

    final persisted = await repository.loadJobs();
    expect(
      persisted.singleWhere((job) => job.id == 'job-interrupted').status,
      JobStatus.queued,
    );
    expect(
      persisted.singleWhere((job) => job.id == 'job-interrupted').progress,
      0,
    );
  });

  test(
    'restored queued jobs auto-start and finish with a persisted summary',
    () async {
      for (var index = 1; index <= 3; index++) {
        await repository.saveJob(
          _job(
            id: 'job-resume-$index',
            batchId: 'batch-resume',
            status: JobStatus.queued,
          ),
        );
      }

      final state = AppState(
        adapter: FakeSourceAdapter(
          probeDelay: Duration.zero,
          stepDelay: Duration.zero,
          steps: 2,
        ),
        concurrency: 2,
        repository: repository,
      );
      addTearDown(state.dispose);

      await state.initialize();
      await _waitFor(() => state.jobs.every((job) => job.status.isTerminal));
      await state.flushPersistence();

      expect(state.jobs, hasLength(3));
      expect(
        state.jobs.where((job) => job.status == JobStatus.completed),
        hasLength(3),
      );
      expect(state.lastSummary?.batchId, 'batch-resume');
      expect(state.lastSummary?.completed, 3);
      final summaries = await repository.loadSummaries();
      expect(summaries.single.batchId, 'batch-resume');
    },
  );

  test('rebuilds a missing summary for terminal persisted jobs', () async {
    final completed = _job(
      id: 'job-done',
      batchId: 'batch-done',
      status: JobStatus.completed,
      progress: 1,
      filePath: 'Downloads/MediaFlow/done.mp4',
    );
    await repository.saveJob(completed);

    final state = AppState(repository: repository);
    addTearDown(state.dispose);
    await state.initialize(autoStart: false);
    await state.flushPersistence();

    expect(state.lastSummary?.batchId, 'batch-done');
    expect(state.lastSummary?.completed, 1);
    final summaries = await repository.loadSummaries();
    expect(summaries.single.batchId, 'batch-done');
  });

  test('removing a job deletes it and its stale summary', () async {
    final completed = _job(
      id: 'job-remove',
      batchId: 'batch-remove',
      status: JobStatus.completed,
      progress: 1,
      filePath: 'Downloads/MediaFlow/remove.mp4',
    );
    await repository.saveJob(completed);
    await repository.saveSummary(_summary('batch-remove', completed: 1));

    final state = AppState(repository: repository);
    addTearDown(state.dispose);
    await state.initialize(autoStart: false);
    await state.removeJob('job-remove');
    await state.flushPersistence();

    expect(await repository.loadJobs(), isEmpty);
    expect(await repository.loadSummaries(), isEmpty);
  });

  test('retry removes the old summary and resets the failed job', () async {
    final failed = _job(
      id: 'job-retry',
      batchId: 'batch-retry',
      status: JobStatus.failed,
      error: const MediaFlowError(
        code: MediaFlowErrorCode.network,
        technicalDetails: 'offline',
        retryable: true,
      ),
    );
    await repository.saveJob(failed);
    await repository.saveSummary(_summary('batch-retry', failed: 1));

    final state = AppState(adapter: _HangingAdapter(), repository: repository);
    addTearDown(state.dispose);
    await state.initialize(autoStart: false);
    await state.retryJob('job-retry');
    await state.flushPersistence();

    expect(await repository.loadSummaries(), isEmpty);
    final loaded = (await repository.loadJobs()).single;
    expect(loaded.status, JobStatus.downloading);
    expect(loaded.error, isNull);
    expect(loaded.progress, 0);
  });
}

class _HangingAdapter extends FakeSourceAdapter {
  @override
  Stream<DownloadEvent> download(DownloadJob job) async* {
    await Completer<void>().future;
  }
}

Future<void> _waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for the restored queue.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

DownloadJob _job({
  required String id,
  String batchId = 'batch-test',
  JobStatus status = JobStatus.queued,
  double progress = 0,
  int? downloadedBytes,
  String? filePath,
  DateTime? completedAt,
  MediaFlowError? error,
  List<MediaEntry> zipEntries = const [],
}) {
  return DownloadJob(
    id: id,
    batchId: batchId,
    url: 'https://example.com/$id.mp4',
    sourceId: 'example.com',
    sourceLabel: 'Example',
    title: id,
    downloadType: DownloadType.video,
    status: status,
    progress: progress,
    downloadedBytes: downloadedBytes,
    totalBytes: 1000,
    filePath: filePath,
    completedAt: completedAt,
    error: error,
    createdAt: DateTime(2026, 10, 27, 13, 40, 5),
    zipEntries: zipEntries,
  );
}

BatchSummary _summary(
  String batchId, {
  int completed = 0,
  int failed = 0,
  List<BatchFailure> failures = const [
    BatchFailure(
      jobId: 'failure',
      title: 'failed.mp4',
      url: 'https://example.com/failed.mp4',
      code: MediaFlowErrorCode.network,
    ),
  ],
}) {
  return BatchSummary(
    batchId: batchId,
    total: completed + failed + 1,
    completed: completed,
    failed: failed,
    skipped: 1,
    cancelled: 0,
    totalBytes: 2048,
    elapsed: const Duration(seconds: 3),
    failures: failed > 0 ? failures : const [],
    skippedItems: const [
      BatchFailure(
        jobId: 'blocked',
        title: 'blocked.mp4',
        url: 'https://example.com/blocked.mp4',
        code: MediaFlowErrorCode.downloadRestricted,
      ),
    ],
  );
}
