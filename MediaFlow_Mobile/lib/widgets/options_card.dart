import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

class OptionsCard extends StatelessWidget {
  final String selectedExt;
  final String selectedQuality;
  final bool isAudioOnly;
  final List<String> videoFormats;
  final List<String> audioFormats;
  final List<String> videoQualities;
  final List<String> audioQualities;
  final ValueChanged<String> onExtChanged;
  final ValueChanged<String> onQualityChanged;
  final ValueChanged<bool> onAudioOnlyChanged;

  const OptionsCard({
    super.key,
    required this.selectedExt,
    required this.selectedQuality,
    required this.isAudioOnly,
    required this.videoFormats,
    required this.audioFormats,
    required this.videoQualities,
    required this.audioQualities,
    required this.onExtChanged,
    required this.onQualityChanged,
    required this.onAudioOnlyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final formats = isAudioOnly ? audioFormats : videoFormats;
    final qualities = isAudioOnly ? audioQualities : videoQualities;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(t('format'), style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                DropdownButton<String>(
                  value: formats.contains(selectedExt) ? selectedExt : formats.first,
                  items: formats
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onExtChanged(v);
                  },
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Text(t('quality'), style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                DropdownButton<String>(
                  value: qualities.contains(selectedQuality)
                      ? selectedQuality
                      : qualities.first,
                  items: qualities
                      .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onQualityChanged(v);
                  },
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Text(t('audioOnly'), style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                Switch(
                  value: isAudioOnly,
                  onChanged: onAudioOnlyChanged,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
