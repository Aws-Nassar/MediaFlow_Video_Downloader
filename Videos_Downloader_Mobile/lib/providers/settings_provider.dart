import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  late SharedPreferences _prefs;

  // Download path
  String _downloadPath = '';
  String get downloadPath => _downloadPath;

  // Concurrent fragments
  int _concurrentFragments = 4;
  int get concurrentFragments => _concurrentFragments;

  // Cookies file
  String _cookieFile = '';
  String get cookieFile => _cookieFile;

  // FFmpeg
  bool _allowFfmpeg = false;
  bool get allowFfmpeg => _allowFfmpeg;
  String _ffmpegPath = '';
  String get ffmpegPath => _ffmpegPath;

  // Theme
  String _themeMode = 'dark';
  String get themeMode => _themeMode;

  // Language
  String _language = 'en';
  String get language => _language;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _load();
  }

  void _load() {
    _downloadPath = _prefs.getString('download_path') ?? '';
    _concurrentFragments = _prefs.getInt('concurrent_fragments') ?? 4;
    _cookieFile = _prefs.getString('cookie_file') ?? '';
    _allowFfmpeg = _prefs.getBool('allow_ffmpeg') ?? false;
    _ffmpegPath = _prefs.getString('ffmpeg_path') ?? '';
    _themeMode = _prefs.getString('theme_mode') ?? 'dark';
    _language = _prefs.getString('language') ?? 'en';
    notifyListeners();
  }

  void setDownloadPath(String v) {
    _downloadPath = v;
    _prefs.setString('download_path', v);
    notifyListeners();
  }

  void setConcurrentFragments(int v) {
    _concurrentFragments = v;
    _prefs.setInt('concurrent_fragments', v);
    notifyListeners();
  }

  void setCookieFile(String v) {
    _cookieFile = v;
    _prefs.setString('cookie_file', v);
    notifyListeners();
  }

  void setAllowFfmpeg(bool v) {
    _allowFfmpeg = v;
    _prefs.setBool('allow_ffmpeg', v);
    notifyListeners();
  }

  void setFfmpegPath(String v) {
    _ffmpegPath = v;
    _prefs.setString('ffmpeg_path', v);
    notifyListeners();
  }

  void setThemeMode(String v) {
    _themeMode = v;
    _prefs.setString('theme_mode', v);
    notifyListeners();
  }

  void setLanguage(String v) {
    _language = v;
    _prefs.setString('language', v);
    notifyListeners();
  }

  Map<String, dynamic> toPythonOptions() => {
        'concurrent_fragments': _concurrentFragments,
        'cookiefile': _cookieFile,
        'allow_ffmpeg': _allowFfmpeg,
        'ffmpeg_path': _ffmpegPath,
      };
}
