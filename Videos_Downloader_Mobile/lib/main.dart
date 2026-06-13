import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/l10n.dart';
import 'providers/settings_provider.dart';
import 'providers/download_provider.dart';
import 'providers/history_provider.dart';
import 'screens/download_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = SettingsProvider();
  await settings.init();

  final history = HistoryProvider();
  await history.init();

  final download = DownloadProvider(settings, history);
  await download.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: history),
        ChangeNotifierProvider.value(value: download),
      ],
      child: const MediaFlowApp(),
    ),
  );
}

class MediaFlowApp extends StatelessWidget {
  const MediaFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'MediaFlow',
          debugShowCheckedModeBanner: false,
          themeMode: _getThemeMode(settings.themeMode),
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          locale: Locale(settings.language),
          localizationsDelegates: [
            ...AppLocalizations.localizationsDelegates,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MainShell(),
        );
      },
    );
  }

  ThemeMode _getThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'oled':
        return ThemeMode.dark;
      default:
        return ThemeMode.dark;
    }
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final isOled = isDark; // Oled uses dark theme with custom colors

    return ThemeData(
      brightness: brightness,
      colorSchemeSeed: const Color(0xFF6C63FF),
      useMaterial3: true,
      scaffoldBackgroundColor: isOled
          ? const Color(0xFF000000)
          : isDark
              ? const Color(0xFF151820)
              : const Color(0xFFF5F5F5),
      cardTheme: CardThemeData(
        color: isOled
            ? const Color(0xFF0A0A0A)
            : isDark
                ? const Color(0xFF1E2430)
                : Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isOled
            ? const Color(0xFF000000)
            : isDark
                ? const Color(0xFF151820)
                : const Color(0xFFF5F5F5),
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isOled
            ? const Color(0xFF000000)
            : isDark
                ? const Color(0xFF151820)
                : Colors.white,
        selectedItemColor: const Color(0xFF6C63FF),
        unselectedItemColor: Colors.grey,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E2430) : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    DownloadScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('appName')),
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.download),
            label: t('download'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: t('history'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: t('settings'),
          ),
        ],
      ),
    );
  }
}
