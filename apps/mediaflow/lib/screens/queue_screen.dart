import 'package:flutter/material.dart';

import '../models/media_models.dart';
import '../state/media_flow_scope.dart';
import '../theme/studio_theme.dart';
import '../widgets/batch_summary_card.dart';
import '../widgets/job_tile.dart';
import '../widgets/studio_widgets.dart';

class QueueScreen extends StatelessWidget {
  final VoidCallback onOpenAnalyze;
  final VoidCallback onOpenLibrary;

  const QueueScreen({
    super.key,
    required this.onOpenAnalyze,
    required this.onOpenLibrary,
  });

  @override
  Widget build(BuildContext context) {
    final state = MediaFlowScope.of(context);
    final strings = state.strings;
    final palette = context.palette;
    final active = state.activeJobs;
    final failed = state.failedJobs;
    final recent = state.jobs
        .where(
          (job) =>
              job.status == JobStatus.completed ||
              job.status == JobStatus.cancelled ||
              job.status == JobStatus.skipped,
        )
        .toList()
        .reversed
        .take(6)
        .toList();
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return ListView(
      padding: EdgeInsets.fromLTRB(wide ? 36 : 18, 26, wide ? 36 : 18, 40),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.queue,
                    style: TextStyle(
                      color: palette.text,
                      fontSize: wide ? 32 : 27,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.9,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    active.isEmpty
                        ? strings.nothingDownloading
                        : '${active.length} ${strings.active}',
                    style: TextStyle(color: palette.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: onOpenAnalyze,
              icon: const Icon(Icons.add_link_rounded, size: 17),
              label: Text(strings.newDownload),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (state.lastSummary != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: BatchSummaryCard(
              summary: state.lastSummary!,
              onOpenLibrary: onOpenLibrary,
            ),
          ),
        if (active.isEmpty && failed.isEmpty && state.lastSummary == null)
          EmptyState(
            icon: Icons.download_for_offline_outlined,
            title: strings.nothingDownloading,
            body: strings.nothingDownloadingBody,
            action: FilledButton.icon(
              onPressed: onOpenAnalyze,
              icon: const Icon(Icons.add_link_rounded, size: 18),
              label: Text(strings.pasteLink),
            ),
          ),
        if (active.isNotEmpty) ...[
          SectionHeader(
            title: strings.active,
            trailing: _CountPill(value: active.length),
          ),
          for (final job in active)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: JobTile(job: job),
            ),
        ],
        if (failed.isNotEmpty) ...[
          SectionHeader(
            title: strings.needsAttention,
            trailing: _CountPill(value: failed.length, color: palette.danger),
          ),
          for (final job in failed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: JobTile(job: job),
            ),
        ],
        if (recent.isNotEmpty) ...[
          SectionHeader(title: strings.recent),
          for (final job in recent)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: JobTile(job: job),
            ),
        ],
      ],
    );
  }
}

class _CountPill extends StatelessWidget {
  final int value;
  final Color? color;

  const _CountPill({required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final effective = color ?? palette.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Text(
        '$value',
        style: TextStyle(
          color: effective,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
