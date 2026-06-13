import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/download_item.dart';
import '../services/ytdlp_service.dart';
import 'settings_provider.dart';
import 'history_provider.dart';

class DownloadProvider extends ChangeNotifier {
  final YtdlpService _ytdlp = YtdlpService();
  final SettingsProvider _settings;
  final HistoryProvider _history;
  StreamSubscription<Map<String, dynamic>>? _progressSub;

  DownloadProvider(this._settings, this._history) {
    _progressSub = _ytdlp.onProgress.listen(_onProgress);
  }

  DownloadStatus _status = DownloadStatus.idle;
  DownloadStatus get status => _status;

  String _statusText = '';
  String get statusText => _statusText;

  Map<String, dynamic>? _mediaInfo;
  Map<String, dynamic>? get mediaInfo => _mediaInfo;

  List<String> _consoleLines = [];
  List<String> get consoleLines => List.unmodifiable(_consoleLines);

  double _progress = 0;
  double get progress => _progress;

  String _speed = '';
  String get speed => _speed;

  String _eta = '';
  String get eta => _eta;

  String _downloaded = '';
  String get downloaded => _downloaded;

  String _totalSize = '';
  String get totalSize => _totalSize;

  // Available options from Python backend
  List<String> _videoFormats = ['mp4', 'mkv', 'webm'];
  List<String> get videoFormats => _videoFormats;

  List<String> _audioFormats = ['mp3', 'm4a', 'aac', 'opus', 'flac', 'wav', 'ogg'];
  List<String> get audioFormats => _audioFormats;

  List<String> _videoQualities = [
    'Best Available', '1080p (FHD)', '720p (HD)', '480p',
    '360p', '240p', '144p', 'Worst'
  ];
  List<String> get videoQualities => _videoQualities;

  List<String> _audioQualities = [
    'Best', '320 kbps', '256 kbps', '192 kbps',
    '128 kbps', '96 kbps', '64 kbps', 'Worst'
  ];
  List<String> get audioQualities => _audioQualities;

  // Selected options
  String selectedExt = 'mp4';
  String selectedQuality = 'Best Available';
  bool isAudioOnly = false;

  Future<void> init() async {
    final opts = await _ytdlp.getOptions();
    if (opts.isNotEmpty) {
      if (opts['video_formats'] != null) {
        _videoFormats = List<String>.from(opts['video_formats']);
      }
      if (opts['audio_formats'] != null) {
        _audioFormats = List<String>.from(opts['audio_formats']);
      }
      if (opts['video_qualities'] != null) {
        _videoQualities = List<String>.from(opts['video_qualities']);
      }
      if (opts['audio_qualities'] != null) {
        _audioQualities = List<String>.from(opts['audio_qualities']);
      }
      notifyListeners();
    }
  }

  void setExt(String v) {
    selectedExt = v;
    notifyListeners();
  }

  void setQuality(String v) {
    selectedQuality = v;
    notifyListeners();
  }

  void setAudioOnly(bool v) {
    isAudioOnly = v;
    if (v) {
      selectedExt = _audioFormats.contains('mp3') ? 'mp3' : _audioFormats.first;
      selectedQuality = _audioQualities.first;
    } else {
      selectedExt = 'mp4';
      selectedQuality = _videoQualities.first;
    }
    notifyListeners();
  }

  Future<void> fetchInfo(String url) async {
    if (url.trim().isEmpty) {
      _setError('Please enter a valid URL');
      return;
    }

    _status = DownloadStatus.fetching;
    _statusText = 'fetching';
    _mediaInfo = null;
    _progress = 0;
    _speed = '';
    _eta = '';
    _downloaded = '';
    _totalSize = '';
    _consoleLines = [];
    notifyListeners();

    final result = await _ytdlp.fetchInfo(
      url.trim(),
      cookieFile: _settings.cookieFile,
    );

    if (result['ok'] == true) {
      _mediaInfo = result;
      _status = DownloadStatus.idle;
      _statusText = 'idle';
    } else {
      _setError(result['error']?.toString() ?? 'fetchError');
    }
    notifyListeners();
  }

  Future<void> startDownload(String url) async {
    if (_status == DownloadStatus.downloading) return;

    _status = DownloadStatus.downloading;
    _statusText = 'downloading';
    _progress = 0;
    _speed = '';
    _eta = '';
    _downloaded = '';
    _totalSize = '';
    notifyListeners();

    // Determine output directory
    String outputDir;
    if (_settings.downloadPath.isNotEmpty) {
      outputDir = _settings.downloadPath;
    } else {
      final dir = await getExternalStorageDirectory();
      outputDir = dir?.path ?? (await getApplicationDocumentsDirectory()).path;
    }

    final result = await _ytdlp.download(
      url.trim(),
      outputDir,
      selectedExt,
      selectedQuality,
      isAudioOnly,
      _settings.toPythonOptions(),
    );

    if (result['ok'] == true) {
      _status = DownloadStatus.completed;
      _statusText = 'completed';
      _progress = 1.0;

      // Add to history
      final title = _mediaInfo?['title'] ?? 'Unknown';
      _history.add(DownloadItem(
        url: url,
        title: title,
        thumbnail: _mediaInfo?['thumbnail'],
        ext: selectedExt,
        quality: selectedQuality,
        isAudio: isAudioOnly,
        filePath: result['file_path'],
      ));
    } else if (result['cancelled'] == true) {
      _status = DownloadStatus.cancelled;
      _statusText = 'cancelled';
    } else {
      _setError(result['error']?.toString() ?? 'downloadError');
    }
    notifyListeners();
  }

  Future<void> cancelDownload() async {
    await _ytdlp.cancelDownload();
    _status = DownloadStatus.cancelled;
    _statusText = 'cancelled';
    notifyListeners();
  }

  void addLog(String line) {
    _consoleLines.add(line);
    notifyListeners();
  }

  void clearAll() {
    _status = DownloadStatus.idle;
    _statusText = 'idle';
    _mediaInfo = null;
    _progress = 0;
    _speed = '';
    _eta = '';
    _downloaded = '';
    _totalSize = '';
    _consoleLines = [];
    isAudioOnly = false;
    selectedExt = 'mp4';
    selectedQuality = 'Best Available';
    notifyListeners();
  }

  void _onProgress(Map<String, dynamic> data) {
    if (data['percent'] != null) {
      final p = data['percent'];
      if (p is num) {
        _progress = p.toDouble() / 100.0;
      } else if (p is String) {
        _progress = (double.tryParse(p) ?? 0) / 100.0;
      }
    }
    if (data['speed'] != null) _speed = data['speed'].toString();
    if (data['eta'] != null) _eta = data['eta'].toString();
    if (data['downloaded'] != null) _downloaded = data['downloaded'].toString();
    if (data['total'] != null) _totalSize = data['total'].toString();
    if (data['log'] != null) _consoleLines.add(data['log'].toString());
    notifyListeners();
  }

  void _setError(String msg) {
    _status = DownloadStatus.error;
    _statusText = msg;
    _consoleLines.add('ERROR: $msg');
    notifyListeners();
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }
}
