import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

const fallbackOutputDirectory = 'Downloads/MediaFlow';
const _platformChannel = MethodChannel('com.mediaflow.app/platform');

/// Resolves the platform-appropriate default output folder.
///
/// Android has no writable working directory for a relative `Downloads` path,
/// so the native side returns the app-specific external downloads directory.
/// Windows uses the user profile; other targets keep the relative fallback.
Future<String> defaultOutputDirectory() async {
  if (Platform.isAndroid) {
    try {
      final value = await _platformChannel.invokeMethod<String>(
        'getDownloadDirectory',
      );
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    } on PlatformException {
      // Fall back to the scaffold default if the channel is unavailable.
    } on MissingPluginException {
      // Tests and desktop builds do not register the Android channel.
    }
  }
  if (Platform.isWindows) {
    final profile = Platform.environment['USERPROFILE']?.trim();
    if (profile != null && profile.isNotEmpty) {
      return [profile, 'Downloads', 'MediaFlow'].join(Platform.pathSeparator);
    }
  }
  return fallbackOutputDirectory;
}

/// Reads free space without adding a storage or filesystem dependency.
abstract interface class DiskSpaceProbe {
  Future<int?> availableBytes(String path);
}

class PlatformDiskSpaceProbe implements DiskSpaceProbe {
  const PlatformDiskSpaceProbe();

  @override
  Future<int?> availableBytes(String path) async {
    try {
      if (Platform.isAndroid) return _android(path);
      if (Platform.isWindows) return await _windows(path);
      if (Platform.isLinux || Platform.isMacOS) return await _posix(path);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    } on ProcessException {
      return null;
    } on FileSystemException {
      return null;
    }
    return null;
  }

  Future<int?> _android(String path) async {
    final value = await _platformChannel.invokeMethod<int>(
      'getAvailableBytes',
      {'path': path},
    );
    return value != null && value > 0 ? value : null;
  }

  Future<int?> _windows(String path) async {
    final literal = "'${path.replaceAll("'", "''")}'";
    final script =
        '''
try {
  \$full = [System.IO.Path]::GetFullPath($literal)
  \$root = [System.IO.Path]::GetPathRoot(\$full)
  [System.IO.DriveInfo]::new(\$root).AvailableFreeSpace
} catch { exit 2 }
''';
    final encoded = base64Encode(_utf16Le(script));
    final result = await Process.run('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-EncodedCommand',
      encoded,
    ]);
    if (result.exitCode != 0) return null;
    final text = result.stdout.toString().trim();
    final match = RegExp(r'\d+').firstMatch(text);
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  Future<int?> _posix(String path) async {
    final probePath = _nearestExisting(path);
    final result = await Process.run('df', ['-Pk', probePath]);
    if (result.exitCode != 0) return null;
    return parsePosixDfAvailableBytes(result.stdout.toString());
  }
}

/// Parses the `Available` column of `df -Pk` output into bytes.
int? parsePosixDfAvailableBytes(String output) {
  final lines = const LineSplitter()
      .convert(output)
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  if (lines.isEmpty) return null;
  final fields = lines.last.split(RegExp(r'\s+'));
  if (fields.length < 4) return null;
  final blocks = int.tryParse(fields[3]);
  if (blocks == null || blocks < 0) return null;
  return blocks * 1024;
}

String _nearestExisting(String path) {
  var directory = Directory(path).absolute;
  while (!directory.existsSync()) {
    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }
  return directory.path;
}

/// PowerShell `-EncodedCommand` expects base64 over UTF-16LE code units.
List<int> _utf16Le(String value) {
  final bytes = <int>[];
  for (final unit in value.codeUnits) {
    bytes
      ..add(unit & 0xff)
      ..add((unit >> 8) & 0xff);
  }
  return bytes;
}
