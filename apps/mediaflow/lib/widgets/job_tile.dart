import 'package:flutter/material.dart';

import '../models/media_models.dart';
import '../state/media_flow_scope.dart';
import '../theme/studio_theme.dart';
import 'studio_widgets.dart';

class JobTile extends StatelessWidget {
  final DownloadJob job;

  const JobTile({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final state = MediaFlowScope.of(context);
    final palette = context.palette;
    final strings = state.strings;
    final statusColor = _statusColor(job.status, palette);
    final isActive = job.status.isActive;
    final isDownloading = job.status == JobStatus.downloading;
    final isProbing = job.status == JobStatus.probing;
    final isQueued = job.status == JobStatus.queued;

    return StudioCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusIcon(status: job.status, color: statusColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SourceBadge(label: job.sourceLabel, compact: true),
                        if (job.itemCount > 1)
                          Text(
                            '${strings.item} ${job.itemIndex}/${job.itemCount}',
                            style: TextStyle(
                              color: palette.textFaint,
                              fontSize: 11,
                            ),
                          ),
                        if (!isActive)
                          Text(
                            job.createdAtLabel,
                            style: TextStyle(
                              color: palette.textFaint,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                label: strings.statusLabel(job.status),
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.link_rounded, size: 13, color: palette.textFaint),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  shortUrl(job.url, max: 78),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: palette.textFaint, fontSize: 11),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: strings.copyLink,
                onPressed: () =>
                    copyToClipboard(context, job.url, strings.linkCopied),
                icon: Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
          if (isProbing || isQueued) ...[
            const SizedBox(height: 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: isProbing ? null : 0,
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isProbing ? strings.analyzing : strings.statusLabel(job.status),
              style: TextStyle(color: palette.textMuted, fontSize: 11),
            ),
          ],
          if (isDownloading || job.status == JobStatus.processing) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: job.safeProgress,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                Text(
                  formatPercent(job.safeProgress),
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (job.totalBytes != null)
                  Text(
                    '${formatBytes(job.downloadedBytes)} / ${formatBytes(job.totalBytes)}',
                    style: TextStyle(color: palette.textMuted, fontSize: 11),
                  ),
                if (formatSpeed(job.bytesPerSecond).isNotEmpty)
                  Text(
                    formatSpeed(job.bytesPerSecond),
                    style: TextStyle(color: palette.textMuted, fontSize: 11),
                  ),
                if (formatEta(job.eta).isNotEmpty)
                  Text(
                    formatEta(job.eta),
                    style: TextStyle(color: palette.textFaint, fontSize: 11),
                  ),
              ],
            ),
          ],
          if (job.status == JobStatus.failed && job.error != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: palette.dangerSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: palette.danger.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: palette.danger,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      strings.errorMessage(job.error!.code),
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (job.status == JobStatus.completed) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.folder_outlined, size: 14, color: palette.textFaint),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    job.filePath ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.textFaint, fontSize: 11),
                  ),
                ),
                if (job.totalBytes != null)
                  Text(
                    formatBytes(job.totalBytes),
                    style: TextStyle(color: palette.textMuted, fontSize: 11),
                  ),
              ],
            ),
          ],
          if (job.status == JobStatus.cancelled ||
              job.status == JobStatus.skipped) ...[
            const SizedBox(height: 4),
            Text(
              strings.statusLabel(job.status),
              style: TextStyle(color: palette.textFaint, fontSize: 11),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 2,
            runSpacing: 2,
            children: [
              if (job.status == JobStatus.failed) ...[
                TextButton.icon(
                  onPressed: () => state.retryJob(job.id),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(strings.retry),
                ),
                TextButton.icon(
                  onPressed: () => _showDetails(context, job),
                  icon: const Icon(Icons.info_outline_rounded, size: 16),
                  label: Text(strings.details),
                ),
              ],
              if (isActive)
                TextButton.icon(
                  onPressed: () => state.cancelJob(job.id),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: Text(strings.cancel),
                ),
              if (!isActive)
                TextButton.icon(
                  onPressed: () => state.removeJob(job.id),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: Text(
                    job.status == JobStatus.completed
                        ? strings.removeFromLibrary
                        : strings.remove,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, DownloadJob job) {
    final state = MediaFlowScope.of(context);
    final palette = context.palette;
    final strings = state.strings;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface,
        title: Text(strings.technicalDetails),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  strings.link,
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  job.url,
                  style: TextStyle(color: palette.text, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Text(
                  strings.error,
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  job.error?.technicalDetails ?? strings.noFailures,
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.close),
          ),
        ],
      ),
    );
  }

  Color _statusColor(JobStatus status, StudioPalette palette) {
    return switch (status) {
      JobStatus.completed => palette.success,
      JobStatus.failed => palette.danger,
      JobStatus.downloading => palette.accent,
      JobStatus.processing => palette.cyan,
      JobStatus.probing => palette.warning,
      JobStatus.cancelled => palette.textMuted,
      JobStatus.skipped => palette.warning,
      JobStatus.queued => palette.textMuted,
    };
  }
}

class _StatusIcon extends StatelessWidget {
  final JobStatus status;
  final Color color;

  const _StatusIcon({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    final icon = switch (status) {
      JobStatus.completed => Icons.check_rounded,
      JobStatus.failed => Icons.priority_high_rounded,
      JobStatus.downloading => Icons.download_rounded,
      JobStatus.processing => Icons.auto_awesome_rounded,
      JobStatus.probing => Icons.search_rounded,
      JobStatus.cancelled => Icons.block_rounded,
      JobStatus.skipped => Icons.skip_next_rounded,
      JobStatus.queued => Icons.schedule_rounded,
    };
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
