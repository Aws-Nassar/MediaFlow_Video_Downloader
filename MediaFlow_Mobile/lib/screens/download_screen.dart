import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/download_item.dart';
import '../providers/download_provider.dart';
import '../widgets/media_info_card.dart';
import '../widgets/options_card.dart';
import '../widgets/progress_card.dart';
import '../widgets/console_log.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final _urlController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _urlController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _analyze(DownloadProvider dp) {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    dp.fetchInfo(url);
  }

  void _download(DownloadProvider dp) {
    final url = _urlController.text.trim();
    if (url.isEmpty || dp.mediaInfo == null) return;
    dp.startDownload(url);
  }

  void _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _urlController.text = data.text!;
      _urlController.selection = TextSelection.fromPosition(
        TextPosition(offset: data.text!.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Consumer<DownloadProvider>(
      builder: (context, dp, _) {
        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            children: [
              // URL input
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          hintText: t('urlHint'),
                          prefixIcon: const Icon(Icons.link),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                        textInputAction: TextInputAction.go,
                        onSubmitted: (_) => _analyze(dp),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (dp.status != DownloadStatus.downloading)
                      FilledButton(
                        onPressed: () => _analyze(dp),
                        child: Text(t('analyze')),
                      ),
                  ],
                ),
              ),

              // Action buttons (Clear, Paste)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: dp.clearAll,
                      icon: const Icon(Icons.clear),
                      label: Text(t('clear')),
                    ),
                    TextButton.icon(
                      onPressed: _paste,
                      icon: const Icon(Icons.paste),
                      label: Text(t('paste')),
                    ),
                    const Spacer(),
                    if (dp.mediaInfo != null &&
                        dp.status != DownloadStatus.downloading)
                      FilledButton.icon(
                        onPressed: () => _download(dp),
                        icon: const Icon(Icons.download),
                        label: Text(t('download')),
                      ),
                  ],
                ),
              ),

              // Media info
              if (dp.mediaInfo != null && dp.status != DownloadStatus.fetching)
                MediaInfoCard(info: dp.mediaInfo!),

              // Options
              if (dp.mediaInfo != null && dp.status == DownloadStatus.idle)
                OptionsCard(
                  selectedExt: dp.selectedExt,
                  selectedQuality: dp.selectedQuality,
                  isAudioOnly: dp.isAudioOnly,
                  videoFormats: dp.videoFormats,
                  audioFormats: dp.audioFormats,
                  videoQualities: dp.videoQualities,
                  audioQualities: dp.audioQualities,
                  onExtChanged: dp.setExt,
                  onQualityChanged: dp.setQuality,
                  onAudioOnlyChanged: dp.setAudioOnly,
                ),

              // Progress
              if (dp.status == DownloadStatus.downloading ||
                  dp.status == DownloadStatus.completed ||
                  dp.status == DownloadStatus.error ||
                  dp.status == DownloadStatus.cancelled)
                ProgressCard(
                  progress: dp.progress,
                  statusText: dp.statusText,
                  speed: dp.speed,
                  eta: dp.eta,
                  downloaded: dp.downloaded,
                  totalSize: dp.totalSize,
                  onCancel: dp.status == DownloadStatus.downloading
                      ? () => dp.cancelDownload()
                      : null,
                ),

              // Console log
              if (dp.consoleLines.isNotEmpty)
                ConsoleLog(
                  lines: dp.consoleLines,
                ),
            ],
          ),
        );
      },
    );
  }
}
