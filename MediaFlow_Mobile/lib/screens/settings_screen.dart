import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../l10n/l10n.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Consumer<SettingsProvider>(
      builder: (context, sp, _) {
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // Download path
            _Section(
              title: t('downloadPath'),
              children: [
                ListTile(
                  title: Text(
                    sp.downloadPath.isNotEmpty
                        ? sp.downloadPath
                        : t('selectPath'),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.folder_open),
                  onTap: () => _pickDirectory(context, sp),
                ),
              ],
            ),

            // Concurrent fragments
            _Section(
              title: t('concurrentFragments'),
              children: [
                ListTile(
                  title: Row(
                    children: [
                      Text('${sp.concurrentFragments}'),
                      const Spacer(),
                      SizedBox(
                        width: 200,
                        child: Slider(
                          value: sp.concurrentFragments.toDouble(),
                          min: 1,
                          max: 16,
                          divisions: 15,
                          label: '${sp.concurrentFragments}',
                          onChanged: (v) =>
                              sp.setConcurrentFragments(v.round()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Cookies
            _Section(
              title: t('cookiesFile'),
              children: [
                ListTile(
                  title: Text(
                    sp.cookieFile.isNotEmpty
                        ? sp.cookieFile.split('\\').last.split('/').last
                        : t('selectCookies'),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (sp.cookieFile.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => sp.setCookieFile(''),
                        ),
                      const Icon(Icons.upload_file),
                    ],
                  ),
                  onTap: () => _pickCookieFile(context, sp),
                ),
              ],
            ),

            // FFmpeg
            _Section(
              title: 'FFmpeg',
              children: [
                SwitchListTile(
                  title: Text(t('ffmpegEnabled')),
                  subtitle: sp.ffmpegPath.isNotEmpty
                      ? Text(sp.ffmpegPath, overflow: TextOverflow.ellipsis)
                      : null,
                  value: sp.allowFfmpeg,
                  onChanged: sp.setAllowFfmpeg,
                ),
              ],
            ),

            // Theme
            _Section(
              title: t('theme'),
              children: [
                RadioListTile<String>(
                  title: Text(t('dark')),
                  value: 'dark',
                  groupValue: sp.themeMode,
                  onChanged: (v) => sp.setThemeMode(v!),
                ),
                RadioListTile<String>(
                  title: Text(t('light')),
                  value: 'light',
                  groupValue: sp.themeMode,
                  onChanged: (v) => sp.setThemeMode(v!),
                ),
                RadioListTile<String>(
                  title: Text(t('oled')),
                  value: 'oled',
                  groupValue: sp.themeMode,
                  onChanged: (v) => sp.setThemeMode(v!),
                ),
              ],
            ),

            // Language
            _Section(
              title: t('language'),
              children: [
                RadioListTile<String>(
                  title: Text(t('english')),
                  value: 'en',
                  groupValue: sp.language,
                  onChanged: (v) => sp.setLanguage(v!),
                ),
                RadioListTile<String>(
                  title: Text(t('arabic')),
                  value: 'ar',
                  groupValue: sp.language,
                  onChanged: (v) => sp.setLanguage(v!),
                ),
              ],
            ),

            // About
            _Section(
              title: t('about'),
              children: [
                ListTile(
                  title: Text(t('appName')),
                  subtitle: Text(t('version')),
                ),
                ListTile(
                  title: Text(t('appDescription')),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _pickDirectory(BuildContext context, SettingsProvider sp) async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      sp.setDownloadPath(result);
    }
  }

  void _pickCookieFile(BuildContext context, SettingsProvider sp) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );
    if (result != null && result.files.isNotEmpty) {
      sp.setCookieFile(result.files.first.path ?? '');
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
