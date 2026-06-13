import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Download path
  String get downloadPath =>
      _prefs.getString('download_path') ?? '';
  set downloadPath(String v) => _prefs.setString('download_path', v);

  // Concurrent fragments
  int get concurrentFragments => _prefs.getInt('concurrent_fragments') ?? 4;
  set concurrentFragments(int v) => _prefs.setInt('concurrent_fragments', v);

  // Cookies file
  String get cookieFile =>
      _prefs.getString('cookie_file') ?? '';
  set cookieFile(String v) => _prefs.setString('cookie_file', v);

  // Allow FFmpeg
  bool get allowFfmpeg => _prefs.getBool('allow_ffmpeg') ?? false;
  set allowFfmpeg(bool v) => _prefs.setBool('allow_ffmpeg', v);

  // FFmpeg path
  String get ffmpegPath =>
      _prefs.getString('ffmpeg_path') ?? '';
  set ffmpegPath(String v) => _prefs.setString('ffmpeg_path', v);

  // Theme mode: 'dark', 'light', 'oled'
  String get themeMode => _prefs.getString('theme_mode') ?? 'dark';
  set themeMode(String v) => _prefs.setString('theme_mode', v);

  // Language
  String get language => _prefs.getString('language') ?? 'en';
  set language(String v) => _prefs.setString('language', v);

  // Download history (JSON array)
  List<Map<String, dynamic>> get history {
    final raw = _prefs.getString('download_history');
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  set history(List<Map<String, dynamic>> v) {
    _prefs.setString('download_history', jsonEncode(v));
  }

  void addHistoryItem(Map<String, dynamic> item) {
    final list = history;
    list.insert(0, item);
    history = list;
  }

  void removeHistoryItem(int index) {
    final list = history;
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      history = list;
    }
  }

  void clearHistory() {
    _prefs.remove('download_history');
  }
}
