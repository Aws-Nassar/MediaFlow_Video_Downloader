import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

class MediaInfoCard extends StatelessWidget {
  final Map<String, dynamic> info;

  const MediaInfoCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final title = info['title'] ?? 'Unknown';
    final thumbnail = info['thumbnail'] as String?;
    final duration = info['duration'] != null
        ? _formatDuration(info['duration'])
        : '0:00';
    final uploader = info['uploader'] as String? ??
        info['channel'] as String? ??
        info['creator'] as String?;
    final description = info['description'] as String?;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (thumbnail != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                thumbnail,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: Colors.grey[900],
                  child: const Icon(Icons.movie, size: 64, color: Colors.grey),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (uploader != null)
                  Text(
                    uploader,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.timer, size: 14),
                    const SizedBox(width: 4),
                    Text(duration, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[400],
                        ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(dynamic secs) {
    if (secs == null) return '0:00';
    num total;
    if (secs is num) {
      total = secs;
    } else if (secs is String) {
      total = num.tryParse(secs) ?? 0;
    } else {
      return '0:00';
    }
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    if (h > 0) {
      return '${h}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m}:${s.toString().padLeft(2, '0')}';
  }
}
