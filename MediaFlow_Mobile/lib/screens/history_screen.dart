import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/l10n.dart';
import '../providers/history_provider.dart';
import '../widgets/history_tile.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Consumer<HistoryProvider>(
      builder: (context, hp, _) {
        if (hp.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  t('noHistory'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _confirmClear(context, hp),
                    icon: const Icon(Icons.delete_sweep),
                    label: Text(t('clear')),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: hp.items.length,
                itemBuilder: (context, i) {
                  final item = hp.items[i];
                  return HistoryTile(
                    item: item,
                    index: i,
                    onShare: () => _shareFile(context, item.filePath),
                    onOpen: () => _openFile(context, item.filePath),
                    onDelete: () => _confirmDelete(context, hp, i),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    HistoryProvider hp,
    int index,
  ) async {
    final t = AppLocalizations.of(context)!;
    final item = hp.items[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          item.filePath == null ? t('confirmDelete') : t('confirmDeleteFile'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t('no')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t('yes')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final path = item.filePath;
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) {
        try {
          await file.delete();
        } catch (_) {
          // Keep the history row removable even if the OS refuses deletion.
        }
      }
    }
    hp.remove(index);
  }

  void _confirmClear(BuildContext context, HistoryProvider hp) {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t('confirmClearHistory')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t('no')),
          ),
          TextButton(
            onPressed: () {
              hp.clear();
              Navigator.pop(dialogContext);
            },
            child: Text(t('yes')),
          ),
        ],
      ),
    );
  }

  Future<void> _shareFile(BuildContext context, String? filePath) async {
    if (filePath == null) return;
    final t = AppLocalizations.of(context)!;
    final file = File(filePath);
    if (!file.existsSync()) {
      _showMessage(context, t('fileMissing'));
      return;
    }
    try {
      await SharePlus.instance.share(ShareParams(files: [XFile(filePath)]));
    } catch (_) {
      if (context.mounted) _showMessage(context, t('fileMissing'));
    }
  }

  Future<void> _openFile(BuildContext context, String? filePath) async {
    if (filePath == null) return;
    final t = AppLocalizations.of(context)!;
    final result = await OpenFilex.open(filePath);
    if (!context.mounted) return;
    if (result.type != ResultType.done) {
      _showMessage(
        context,
        result.message.isNotEmpty ? result.message : t('fileMissing'),
      );
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
