import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            if (hp.items.isNotEmpty)
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
                    onDelete: () => hp.remove(i),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmClear(BuildContext context, HistoryProvider hp) {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t('confirmClearHistory')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('no')),
          ),
          TextButton(
            onPressed: () {
              hp.clear();
              Navigator.pop(context);
            },
            child: Text(t('yes')),
          ),
        ],
      ),
    );
  }

  void _shareFile(BuildContext context, String? filePath) {
    if (filePath == null) return;
    final file = File(filePath);
    if (!file.existsSync()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share: ${file.path}')),
    );
  }

  void _openFile(BuildContext context, String? filePath) {
    if (filePath == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open: $filePath')),
    );
  }
}
