import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

class ProgressCard extends StatelessWidget {
  final double progress;
  final String statusText;
  final String speed;
  final String eta;
  final String downloaded;
  final String totalSize;
  final VoidCallback? onCancel;

  const ProgressCard({
    super.key,
    required this.progress,
    required this.statusText,
    this.speed = '',
    this.eta = '',
    this.downloaded = '',
    this.totalSize = '',
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 12),
            if (statusText == 'downloading') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (speed.isNotEmpty)
                    _Stat(label: t('progressSpeed'), value: speed),
                  if (eta.isNotEmpty)
                    _Stat(label: t('progressEta'), value: eta),
                  if (totalSize.isNotEmpty)
                    _Stat(label: t('progressSize'), value: totalSize),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 12),
              if (onCancel != null)
                FilledButton.tonalIcon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel),
                  label: Text(t('cancel')),
                ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _statusIcon,
                    color: _statusColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _statusLabel(t),
                    style: TextStyle(color: _statusColor),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData get _statusIcon {
    switch (statusText) {
      case 'completed':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      case 'cancelled':
        return Icons.cancel;
      case 'fetching':
        return Icons.search;
      case 'downloading':
        return Icons.download;
      default:
        return Icons.info;
    }
  }

  Color get _statusColor {
    switch (statusText) {
      case 'completed':
        return Colors.green;
      case 'error':
        return Colors.red;
      case 'cancelled':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(AppLocalizations t) {
    switch (statusText) {
      case 'fetching':
        return t('fetching');
      case 'downloading':
        return t('downloading');
      case 'completed':
        return t('completed');
      case 'error':
        return t('error');
      case 'cancelled':
        return t('cancelled');
      default:
        return t('idle');
    }
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
