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
                  errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey[900],
                    child: Icon(
                      item.isAudio ? Icons.audiotrack : Icons.movie,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            : Container(
                width: 56,
                height: 56,
                color: Colors.grey[900],
                child: Icon(
                  item.isAudio ? Icons.audiotrack : Icons.movie,
                  color: Colors.grey,
                ),
              ),
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${item.ext.toUpperCase()} · ${item.quality}',
          style: Theme.of(context).textTheme.bodySmall,
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
            if (item.filePath != null && File(item.filePath!).existsSync())
              PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: const Icon(Icons.share),
                  title: Text(t('share')),
                  dense: true,
                ),
              ),
            if (item.filePath != null && File(item.filePath!).existsSync())
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
                title: Text(t('delete'), style: const TextStyle(color: Colors.red)),
                dense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
