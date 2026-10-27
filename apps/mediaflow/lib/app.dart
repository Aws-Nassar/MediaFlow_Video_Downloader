import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/analyze_screen.dart';
import 'screens/library_screen.dart';
import 'screens/queue_screen.dart';
import 'screens/settings_screen.dart';
import 'state/app_state.dart';
import 'state/media_flow_scope.dart';
import 'theme/studio_theme.dart';

class MediaFlowApp extends StatefulWidget {
  final AppState? appState;

  const MediaFlowApp({super.key, this.appState});

  @override
  State<MediaFlowApp> createState() => _MediaFlowAppState();
}

class _MediaFlowAppState extends State<MediaFlowApp>
    with WidgetsBindingObserver {
  late final AppState _state = widget.appState ?? AppState();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_state.flushPersistence());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.appState == null) _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MediaFlowScope(
      state: _state,
      child: AnimatedBuilder(
        animation: _state,
        builder: (context, _) {
          final theme = buildStudioTheme(_state.themeMode);
          return MaterialApp(
            title: 'MediaFlow',
            debugShowCheckedModeBanner: false,
            theme: theme,
            darkTheme: theme,
            themeMode: ThemeMode.system,
            // The scaffold uses its own AppStrings map. Keep Material's
            // localizations on English until flutter_localizations/ARB is added;
            // Directionality below still flips the whole UI for Arabic.
            locale: const Locale('en'),
            supportedLocales: const [Locale('en'), Locale('ar')],
            builder: (context, child) => Directionality(
              textDirection: _state.textDirection,
              child: child ?? const SizedBox.shrink(),
            ),
            home: const HomeShell(),
          );
        },
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _openAnalyze() => setState(() => _index = 0);
  void _openQueue() => setState(() => _index = 1);
  void _openLibrary() => setState(() => _index = 2);

  @override
  Widget build(BuildContext context) {
    final state = MediaFlowScope.of(context);
    final strings = state.strings;
    final palette = context.palette;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final railExtended = MediaQuery.sizeOf(context).width >= 1180;

    final screens = [
      AnalyzeScreen(onOpenQueue: _openQueue),
      QueueScreen(onOpenAnalyze: _openAnalyze, onOpenLibrary: _openLibrary),
      const LibraryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: wide ? 18 : 14,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _StudioMark(),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  strings.appName,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if (wide)
                  Text(
                    strings.appTagline,
                    style: TextStyle(color: palette.textFaint, fontSize: 10),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              state.setLocale(Locale(state.isArabic ? 'en' : 'ar'));
            },
            child: Text(
              state.isArabic ? 'EN' : 'AR',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          PopupMenuButton<StudioThemeMode>(
            tooltip: strings.theme,
            icon: Icon(
              Icons.brightness_6_outlined,
              color: palette.textMuted,
              size: 20,
            ),
            onSelected: state.setThemeMode,
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: StudioThemeMode.dark,
                checked: state.themeMode == StudioThemeMode.dark,
                child: Text(strings.dark),
              ),
              CheckedPopupMenuItem(
                value: StudioThemeMode.light,
                checked: state.themeMode == StudioThemeMode.light,
                child: Text(strings.light),
              ),
              CheckedPopupMenuItem(
                value: StudioThemeMode.oled,
                checked: state.themeMode == StudioThemeMode.oled,
                child: Text(strings.oled),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  extended: railExtended,
                  minExtendedWidth: 196,
                  labelType: railExtended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  onDestinationSelected: (value) {
                    setState(() => _index = value);
                  },
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.add_link_rounded),
                      selectedIcon: const Icon(Icons.add_link_rounded),
                      label: Text(strings.analyze),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.download_outlined),
                      selectedIcon: const Icon(Icons.download_rounded),
                      label: Text(strings.queue),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.video_library_outlined),
                      selectedIcon: const Icon(Icons.video_library_rounded),
                      label: Text(strings.library),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.settings_outlined),
                      selectedIcon: const Icon(Icons.settings_rounded),
                      label: Text(strings.settings),
                    ),
                  ],
                ),
                VerticalDivider(width: 1, color: palette.border),
                Expanded(
                  child: IndexedStack(index: _index, children: screens),
                ),
              ],
            )
          : IndexedStack(index: _index, children: screens),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) {
                setState(() => _index = value);
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.add_link_rounded),
                  label: strings.analyze,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.download_outlined),
                  selectedIcon: const Icon(Icons.download_rounded),
                  label: strings.queue,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.video_library_outlined),
                  selectedIcon: const Icon(Icons.video_library_rounded),
                  label: strings.library,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings_rounded),
                  label: strings.settings,
                ),
              ],
            ),
    );
  }
}

class _StudioMark extends StatelessWidget {
  const _StudioMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C5CFF), Color(0xFF22D3EE)],
        ),
      ),
      child: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
    );
  }
}
