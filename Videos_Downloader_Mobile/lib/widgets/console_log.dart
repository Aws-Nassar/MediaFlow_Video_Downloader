import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

class ConsoleLog extends StatelessWidget {
  final List<String> lines;
  final ScrollController? scrollController;

  const ConsoleLog({
    super.key,
    required this.lines,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Text(
              t('consoleLog'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              controller: scrollController,
              shrinkWrap: true,
              itemCount: lines.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Text(
                  lines[i],
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
