import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'prefs_service.dart';

class FfmpegService {
  static const _assetPath = 'assets/ffmpeg';
  static const _extractedName = 'ffmpeg';

  static Future<bool> extractFfmpeg(PrefsService prefs) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final ffmpegDir = Directory('${appDir.path}/ffmpeg');
      if (!ffmpegDir.existsSync()) {
        ffmpegDir.createSync(recursive: true);
      }

      final ffmpegFile = File('${ffmpegDir.path}/$_extractedName');
      if (ffmpegFile.existsSync()) {
        // Already extracted, ensure prefs are set
        if (prefs.ffmpegPath.isEmpty) {
          prefs.ffmpegPath = ffmpegFile.path;
          prefs.allowFfmpeg = true;
        }
        return true;
      }

      // Extract from APK assets
      final byteData = await rootBundle.load(_assetPath);
      await ffmpegFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      // Make executable
      await Process.run('chmod', ['755', ffmpegFile.path]);

      // Save path in preferences
      prefs.ffmpegPath = ffmpegFile.path;
      prefs.allowFfmpeg = true;

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isFfmpegAvailable() async {
    final appDir = await getApplicationDocumentsDirectory();
    final ffmpegFile = File('${appDir.path}/ffmpeg/$_extractedName');
    return ffmpegFile.existsSync();
  }
}
