import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/download_item.dart';

class HistoryTile extends StatelessWidget {
  final DownloadItem item;
  final int index;
  final VoidCallback? onShare;
  final VoidCallback? onOpen;
  final VoidCallback? onDelete;

  const HistoryTile({
    super.key,
    required this.item,
    required this.index,
    this.onShare,
    this.onOpen,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final path = item.filePath;
    final exists = path != null && File(path).existsSync();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: item.thumbnail != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  item.thumbnail!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _placeholder(),
                ),
              )
            : _placeholder(),
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          _subtitle(t, exists),
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            switch (v) {
              case 'share':
                onShare?.call();
                break;
              case 'open':
                onOpen?.call();
                break;
              case 'delete':
                onDelete?.call();
                break;
            }
          },
          itemBuilder: (_) => [
            if (exists)
              PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: const Icon(Icons.share),
                  title: Text(t('share')),
                  dense: true,
                ),
              ),
            if (exists)
              PopupMenuItem(
                value: 'open',
                child: ListTile(
                  leading: const Icon(Icons.open_in_new),
                  title: Text(t('openFile')),
                  dense: true,
                ),
              ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  t('delete'),
                  style: const TextStyle(color: Colors.red),
                ),
                dense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      color: Colors.grey[900],
      child: Icon(
        item.isAudio ? Icons.audiotrack : Icons.movie,
        color: Colors.grey,
      ),
    );
  }

  String _subtitle(AppLocalizations t, bool exists) {
    final parts = <String>['${item.ext.toUpperCase()} · ${item.quality}'];
    if (!exists) {
      parts.add(t('fileMissing'));
    } else {
      try {
        parts.add(_formatBytes(File(item.filePath!).lengthSync()));
      } catch (_) {
        parts.add(t('fileMissing'));
      }
    }
    return parts.join(' · ');
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    return '${(mb / 1024).toStringAsFixed(1)} GB';
  }
}
