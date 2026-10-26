import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/media_models.dart';
import '../state/media_flow_scope.dart';
import '../theme/studio_theme.dart';
import '../widgets/drive_selection_sheet.dart';
import '../widgets/studio_widgets.dart';

class AnalyzeScreen extends StatefulWidget {
  final VoidCallback onOpenQueue;

  const AnalyzeScreen({super.key, required this.onOpenQueue});

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) return;
    _controller.text = text;
    setState(() {});
  }

  Future<void> _submit() async {
    final state = MediaFlowScope.of(context);
    final raw = _controller.text.trim();
    if (raw.isEmpty || state.isAnalyzing) return;
    await state.analyzeAndEnqueue(
      raw,
      selectCollection: (descriptor) {
        if (descriptor.sourceId != 'drive.google.com' || !mounted) {
          return Future.value(CollectionSelection(entries: descriptor.entries));
        }
        return showDriveCollectionSelection(context, descriptor);
      },
    );
    if (!mounted) return;
    if (state.jobs.isNotEmpty || state.lastSummary != null) {
      _controller.clear();
      setState(() {});
      widget.onOpenQueue();
    }
  }

  void _fillDemo() {
    _controller.text = [
      'https://example.com/video/1',
      'https://example.com/cookies',
      'https://drive.google.com/drive/folders/demo-mixed',
    ].join('\n');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = MediaFlowScope.of(context);
    final strings = state.strings;
    final palette = context.palette;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final canAnalyze = _controller.text.trim().isNotEmpty && !state.isAnalyzing;
    final headlineSize = wide ? 36.0 : 29.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(wide ? 36 : 18, 26, wide ? 36 : 18, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.newDownload.toUpperCase(),
                style: TextStyle(
                  color: palette.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                strings.pasteLink,
                style: TextStyle(
                  color: palette.text,
                  fontSize: headlineSize,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.1,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Text(
                  strings.analyzeSubtitle,
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: wide ? 15 : 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              StudioCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _controller,
                      minLines: 3,
                      maxLines: 6,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: strings.urlHint,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(bottom: 52),
                          child: Icon(
                            Icons.link_rounded,
                            color: palette.textFaint,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 640;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                SegmentedButton<DownloadType>(
                                  segments: [
                                    ButtonSegment(
                                      value: DownloadType.video,
                                      icon: const Icon(
                                        Icons.movie_outlined,
                                        size: 17,
                                      ),
                                      label: Text(strings.video),
                                    ),
                                    ButtonSegment(
                                      value: DownloadType.audio,
                                      icon: const Icon(
                                        Icons.graphic_eq_rounded,
                                        size: 17,
                                      ),
                                      label: Text(strings.audio),
                                    ),
                                  ],
                                  selected: {state.downloadType},
                                  showSelectedIcon: false,
                                  onSelectionChanged: (selection) {
                                    if (selection.isNotEmpty) {
                                      state.setDownloadType(selection.first);
                                    }
                                  },
                                ),
                                OutlinedButton.icon(
                                  onPressed: _paste,
                                  icon: const Icon(
                                    Icons.content_paste_rounded,
                                    size: 17,
                                  ),
                                  label: Text(strings.paste),
                                ),
                                TextButton(
                                  onPressed: _controller.text.isEmpty
                                      ? null
                                      : () {
                                          _controller.clear();
                                          setState(() {});
                                        },
                                  child: Text(strings.clear),
                                ),
                                if (kDebugMode)
                                  TextButton(
                                    onPressed: _fillDemo,
                                    child: Text(strings.demoLinks),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: compact ? double.infinity : 230,
                              child: FilledButton.icon(
                                onPressed: canAnalyze ? _submit : null,
                                icon: state.isAnalyzing
                                    ? const SizedBox(
                                        width: 17,
                                        height: 17,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.download_rounded,
                                        size: 19,
                                      ),
                                label: Text(
                                  state.isAnalyzing
                                      ? strings.analyzing
                                      : strings.download,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (state.analyzeError != null) ...[
                const SizedBox(height: 12),
                InfoBanner(
                  icon: Icons.info_outline_rounded,
                  title: strings.analyze,
                  body: state.analyzeError!,
                  danger: true,
                ),
              ],
              if (kDebugMode) ...[
                const SizedBox(height: 12),
                Text(
                  strings.demoHint,
                  style: TextStyle(color: palette.textFaint, fontSize: 11),
                ),
              ],
              const SizedBox(height: 28),
              SectionHeader(title: strings.supportedSources),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  SourceBadge(label: 'YouTube'),
                  SourceBadge(label: 'TikTok'),
                  SourceBadge(label: 'Facebook'),
                  SourceBadge(label: 'Instagram'),
                  SourceBadge(label: 'Kick'),
                  SourceBadge(label: 'Twitch'),
                  SourceBadge(label: 'SoundCloud'),
                  SourceBadge(label: 'Google Drive'),
                  SourceBadge(label: 'Direct link'),
                ],
              ),
              const SizedBox(height: 26),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 17,
                      color: palette.textFaint,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        strings.legalNote,
                        style: TextStyle(
                          color: palette.textFaint,
                          fontSize: 11,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
