import 'package:flutter/material.dart';

import '../models/media_models.dart';
import '../state/media_flow_scope.dart';
import '../theme/studio_theme.dart';
import '../widgets/studio_widgets.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _search = TextEditingController();
  bool _grid = true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = MediaFlowScope.of(context);
    final strings = state.strings;
    final palette = context.palette;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final query = _search.text.trim().toLowerCase();
    final jobs = state.libraryJobs.where((job) {
      if (query.isEmpty) return true;
      return job.title.toLowerCase().contains(query) ||
          job.sourceLabel.toLowerCase().contains(query) ||
          job.url.toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(wide ? 36 : 18, 26, wide ? 36 : 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.library,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: wide ? 32 : 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.9,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${state.libraryJobs.length} ${strings.items}',
                      style: TextStyle(color: palette.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              _ViewToggle(
                grid: _grid,
                onChanged: (value) => setState(() => _grid = value),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: strings.searchHint,
              prefixIcon: Icon(Icons.search_rounded, color: palette.textFaint),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: strings.clear,
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                      icon: Icon(Icons.close_rounded, color: palette.textMuted),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: jobs.isEmpty
                ? ListView(
                    padding: const EdgeInsets.only(bottom: 40),
                    children: [
                      EmptyState(
                        icon: Icons.video_library_outlined,
                        title: state.libraryJobs.isEmpty
                            ? strings.noLibrary
                            : strings.search,
                        body: state.libraryJobs.isEmpty
                            ? strings.noLibraryBody
                            : strings.searchHint,
                      ),
                    ],
                  )
                : _grid
                ? GridView.builder(
                    padding: const EdgeInsets.only(bottom: 40),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 330,
                          mainAxisExtent: 258,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: jobs.length,
                    itemBuilder: (context, index) => _LibraryGridCard(
                      job: jobs[index],
                      onTap: () => _showDetails(context, jobs[index]),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 40),
                    itemCount: jobs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _LibraryRow(
                      job: jobs[index],
                      onTap: () => _showDetails(context, jobs[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDetails(BuildContext context, DownloadJob job) async {
    final state = MediaFlowScope.of(context);
    final palette = context.palette;
    final strings = state.strings;
    final remove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface,
        title: Text(job.title),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SourceBadge(label: job.sourceLabel),
                const SizedBox(height: 14),
                _DetailLine(label: strings.link, value: job.url),
                _DetailLine(
                  label: strings.totalSize,
                  value: formatBytes(job.totalBytes),
                ),
                _DetailLine(
                  label: strings.completed,
                  value: formatDateTime(job.completedAt ?? job.createdAt),
                ),
                _DetailLine(
                  label: strings.outputFolder,
                  value: job.filePath ?? state.outputDirectory,
                ),
                const SizedBox(height: 10),
                Text(
                  strings.fileActionsLater,
                  style: TextStyle(
                    color: palette.textFaint,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () =>
                copyToClipboard(context, job.url, strings.linkCopied),
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: Text(strings.copyLink),
          ),
          TextButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            label: Text(strings.removeFromLibrary),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.close),
          ),
        ],
      ),
    );
    if (remove == true && context.mounted) {
      await _confirmRemove(context, job);
    }
  }

  Future<void> _confirmRemove(BuildContext context, DownloadJob job) async {
    final state = MediaFlowScope.of(context);
    final palette = context.palette;
    final strings = state.strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface,
        title: Text(strings.removeFromLibrary),
        content: Text(strings.removeFromLibraryBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.keep),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.removeConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await state.removeJob(job.id);
    }
  }
}

class _ViewToggle extends StatelessWidget {
  final bool grid;
  final ValueChanged<bool> onChanged;

  const _ViewToggle({required this.grid, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            selected: !grid,
            icon: Icons.view_list_rounded,
            onTap: () => onChanged(false),
          ),
          _ToggleButton(
            selected: grid,
            icon: Icons.grid_view_rounded,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 30,
        decoration: BoxDecoration(
          color: selected ? palette.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 17,
          color: selected ? palette.accent : palette.textMuted,
        ),
      ),
    );
  }
}

class _LibraryGridCard extends StatelessWidget {
  final DownloadJob job;
  final VoidCallback onTap;

  const _LibraryGridCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = sourceColor(job.sourceLabel, palette);
    return StudioCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 130,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.28),
                    palette.surfaceRaised,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      job.downloadType == DownloadType.audio
                          ? Icons.graphic_eq_rounded
                          : Icons.play_circle_outline_rounded,
                      size: 42,
                      color: color,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: SourceBadge(label: job.sourceLabel, compact: true),
                  ),
                  if (job.totalBytes != null)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          formatBytes(job.totalBytes),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        job.createdAtLabel,
                        style: TextStyle(
                          color: palette.textFaint,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: palette.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryRow extends StatelessWidget {
  final DownloadJob job;
  final VoidCallback onTap;

  const _LibraryRow({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = sourceColor(job.sourceLabel, palette);
    return StudioCard(
      padding: const EdgeInsets.all(13),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              job.downloadType == DownloadType.audio
                  ? Icons.graphic_eq_rounded
                  : Icons.play_arrow_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${job.sourceLabel} · ${formatBytes(job.totalBytes)} · ${job.createdAtLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: palette.textFaint, fontSize: 11),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: palette.textFaint),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: palette.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: TextStyle(color: palette.text, fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
  }
}
