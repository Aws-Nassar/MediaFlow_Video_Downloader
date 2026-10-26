import 'package:flutter/material.dart';

import '../state/media_flow_scope.dart';
import '../theme/studio_theme.dart';
import '../widgets/studio_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _folder = TextEditingController();
  bool _folderInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_folderInitialized) return;
    _folder.text = MediaFlowScope.of(context).outputDirectory;
    _folderInitialized = true;
  }

  @override
  void dispose() {
    _folder.dispose();
    super.dispose();
  }

  void _saveFolder() {
    final state = MediaFlowScope.of(context);
    final value = _folder.text.trim();
    if (value.isEmpty) return;
    state.setOutputDirectory(value);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(state.strings.saved)));
  }

  @override
  Widget build(BuildContext context) {
    final state = MediaFlowScope.of(context);
    final strings = state.strings;
    final palette = context.palette;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return ListView(
      padding: EdgeInsets.fromLTRB(wide ? 36 : 18, 26, wide ? 36 : 18, 40),
      children: [
        Text(
          strings.settings,
          style: TextStyle(
            color: palette.text,
            fontSize: wide ? 32 : 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.9,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          strings.appTagline,
          style: TextStyle(color: palette.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: strings.settingsAppearance),
              StudioCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SettingLabel(text: strings.theme),
                    const SizedBox(height: 8),
                    SegmentedButton<StudioThemeMode>(
                      segments: [
                        ButtonSegment(
                          value: StudioThemeMode.dark,
                          label: Text(strings.dark),
                        ),
                        ButtonSegment(
                          value: StudioThemeMode.light,
                          label: Text(strings.light),
                        ),
                        ButtonSegment(
                          value: StudioThemeMode.oled,
                          label: Text(strings.oled),
                        ),
                      ],
                      selected: {state.themeMode},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) {
                        if (selection.isNotEmpty) {
                          state.setThemeMode(selection.first);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    _SettingLabel(text: strings.language),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'en', label: Text('English')),
                        ButtonSegment(value: 'ar', label: Text('العربية')),
                      ],
                      selected: {state.locale.languageCode},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) {
                        if (selection.isNotEmpty) {
                          state.setLocale(Locale(selection.first));
                        }
                      },
                    ),
                  ],
                ),
              ),
              SectionHeader(title: strings.settingsDownloads),
              StudioCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SettingLabel(text: strings.outputFolder),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _folder,
                            onSubmitted: (_) => _saveFolder(),
                            decoration: InputDecoration(
                              hintText: strings.outputFolderHint,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _saveFolder,
                          child: Text(strings.save),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _SettingLabel(text: strings.concurrency),
                        ),
                        Text(
                          '${state.concurrency}',
                          style: TextStyle(
                            color: palette.accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: state.concurrency.toDouble(),
                      min: 1,
                      max: 4,
                      divisions: 3,
                      label: '${state.concurrency}',
                      onChanged: (value) => state.setConcurrency(value.round()),
                    ),
                    Text(
                      strings.concurrencyHint,
                      style: TextStyle(color: palette.textFaint, fontSize: 11),
                    ),
                  ],
                ),
              ),
              SectionHeader(title: strings.settingsDrive),
              StudioCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: palette.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.add_to_drive_outlined,
                            color: palette.success,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            strings.driveTitle,
                            style: TextStyle(
                              color: palette.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SourceBadge(label: 'Google Drive'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      strings.driveBody,
                      style: TextStyle(
                        color: palette.textMuted,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DrivePoint(
                      icon: Icons.person_off_outlined,
                      text: strings.driveNoAccount,
                    ),
                    _DrivePoint(
                      icon: Icons.link_rounded,
                      text: strings.driveNoButton,
                    ),
                    _DrivePoint(
                      icon: Icons.gpp_maybe_outlined,
                      text: strings.driveRestricted,
                    ),
                  ],
                ),
              ),
              SectionHeader(title: strings.about),
              StudioCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AboutRow(label: strings.version, value: '0.1.0 · Phase 3'),
                    _AboutRow(
                      label: strings.engineLabel,
                      value: state.engineLabel,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      strings.noTelemetry,
                      style: TextStyle(
                        color: palette.textMuted,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      strings.legalNote,
                      style: TextStyle(
                        color: palette.textFaint,
                        fontSize: 11,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingLabel extends StatelessWidget {
  final String text;

  const _SettingLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Text(
      text,
      style: TextStyle(
        color: palette.text,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _DrivePoint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DrivePoint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: palette.textFaint),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: palette.textMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;

  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(color: palette.textMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: palette.text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
