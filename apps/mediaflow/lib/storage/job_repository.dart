import '../models/media_models.dart';

/// Persistence boundary for the queue and batch history.
///
/// Implementations must preserve the order passed to [loadJobs] (oldest first)
/// and return summaries newest first.
abstract interface class JobRepository {
  Future<List<DownloadJob>> loadJobs();

  Future<List<BatchSummary>> loadSummaries();

  /// Inserts or replaces the complete job, including folder entries.
  Future<void> saveJob(DownloadJob job);

  /// Writes only the frequently-changing download fields for an existing job.
  Future<void> saveJobProgress(DownloadJob job);

  Future<void> deleteJob(String id);

  Future<void> saveSummary(BatchSummary summary);

  Future<void> deleteSummary(String batchId);

  Future<void> close();
}
