import 'package:flutter/material.dart';

import '../models/media_models.dart';
import '../state/media_flow_scope.dart';
import '../theme/studio_theme.dart';
import 'studio_widgets.dart';

class BatchSummaryCard extends StatelessWidget {
  final BatchSummary summary;
  final VoidCallback? onOpenLibrary;

  const BatchSummaryCard({
    super.key,
    required this.summary,
    this.onOpenLibrary,
  });

  @override
  Widget build(BuildContext context) {
    final state = MediaFlowScope.of(context);
    final palette = context.palette;
    final strings = state.strings;
    final hasIssues = summary.hasFailures;
    final accent = hasIssues ? palette.warning : palette.success;

    if (summary.isSingleSuccess) {
      return StudioCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: palette.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.check_rounded,
                color: palette.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.downloadComplete,
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    strings.downloadCompleteBody,
                    style: TextStyle(color: palette.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (onOpenLibrary != null)
              TextButton(
                onPressed: onOpenLibrary,
                child: Text(strings.openLibrary),
              ),
            IconButton(
              tooltip: strings.dismiss,
              onPressed: state.dismissSummary,
              icon: Icon(Icons.close_rounded, color: palette.textMuted),
            ),
          ],
        ),
      );
    }

    return StudioCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 10, 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasIssues
                        ? Icons.report_problem_outlined
                        : Icons.check_circle_outline_rounded,
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasIssues
                            ? strings.batchWithIssues
                            : strings.batchFinished,
                        style: TextStyle(
                          color: palette.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasIssues
                            ? strings.batchFinishedBody
                            : strings.noFailures,
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: strings.dismiss,
                  onPressed: state.dismissSummary,
                  icon: Icon(
                    Icons.close_rounded,
                    color: palette.textMuted,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Stat(
                  label: strings.items,
                  value: '${summary.total}',
                  color: palette.text,
                ),
                _Stat(
                  label: strings.downloaded,
                  value: '${summary.completed}',
                  color: palette.success,
                ),
                if (summary.failed > 0)
                  _Stat(
                    label: strings.failed,
                    value: '${summary.failed}',
                    color: palette.danger,
                  ),
                if (summary.skipped > 0)
                  _Stat(
                    label: strings.skipped,
                    value: '${summary.skipped}',
                    color: palette.warning,
                  ),
                if (summary.cancelled > 0)
                  _Stat(
                    label: strings.cancelled,
                    value: '${summary.cancelled}',
                    color: palette.textMuted,
                  ),
                _Stat(
                  label: strings.totalSize,
                  value: formatBytes(summary.totalBytes),
                  color: palette.textMuted,
                ),
                _Stat(
                  label: strings.elapsed,
                  value: formatDuration(summary.elapsed),
                  color: palette.textMuted,
                ),
              ],
            ),
          ),
          if (hasIssues) ...[
            Divider(color: palette.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
              child: Text(
                strings.retryOnlyFailed,
                style: TextStyle(color: palette.textFaint, fontSize: 11),
              ),
            ),
            for (final failure in summary.failures)
              _FailureRow(failure: failure),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (hasIssues)
                  FilledButton.tonalIcon(
                    onPressed: state.retryFailed,
                    icon: const Icon(Icons.refresh_rounded, size: 17),
                    label: Text(strings.retryFailed),
                  ),
                if (hasIssues)
                  OutlinedButton.icon(
                    onPressed: () => copyToClipboard(
                      context,
                      summary.failures.map((failure) => failure.url).join('\n'),
                      strings.failedLinksCopied,
                    ),
                    icon: const Icon(Icons.copy_all_rounded, size: 17),
                    label: Text(strings.copyFailedLinks),
                  ),
                if (!hasIssues && onOpenLibrary != null)
                  FilledButton.tonalIcon(
                    onPressed: onOpenLibrary,
                    icon: const Icon(Icons.video_library_outlined, size: 17),
                    label: Text(strings.openLibrary),
                  ),
                TextButton(
                  onPressed: state.dismissSummary,
                  child: Text(strings.dismiss),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: palette.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _FailureRow extends StatelessWidget {
  final BatchFailure failure;

  const _FailureRow({required this.failure});

  @override
  Widget build(BuildContext context) {
    final state = MediaFlowScope.of(context);
    final palette = context.palette;
    final strings = state.strings;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 10, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 17, color: palette.danger),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  failure.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  shortUrl(failure.url, max: 64),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: palette.textFaint, fontSize: 10),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.errorMessage(failure.code),
                  style: TextStyle(color: palette.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: strings.copyLink,
            onPressed: () =>
                copyToClipboard(context, failure.url, strings.linkCopied),
            icon: Icon(Icons.copy_rounded, size: 16, color: palette.textMuted),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: strings.retry,
            onPressed: () => state.retryJob(failure.jobId),
            icon: Icon(Icons.refresh_rounded, size: 17, color: palette.accent),
          ),
        ],
      ),
    );
  }
}
