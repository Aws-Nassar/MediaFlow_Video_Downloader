import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediaflow/platform/platform_storage.dart';

void main() {
  test('parses the available column from df output', () {
    const output = '''
Filesystem     1024-blocks    Used Available Capacity Mounted on
/dev/sda1         10485760 2097152   8388608      20% /
''';
    expect(parsePosixDfAvailableBytes(output), 8388608 * 1024);
    expect(parsePosixDfAvailableBytes(''), isNull);
    expect(parsePosixDfAvailableBytes('garbage'), isNull);
  });

  test('resolves the scaffold output directory off Android', () async {
    if (Platform.isAndroid) return;
    final profile = Platform.environment['USERPROFILE']?.trim();
    final expected = Platform.isWindows && profile != null && profile.isNotEmpty
        ? [profile, 'Downloads', 'MediaFlow'].join(Platform.pathSeparator)
        : fallbackOutputDirectory;
    expect(await defaultOutputDirectory(), expected);
  });

  test('reads free space for the temporary directory', () async {
    if (!(Platform.isWindows ||
        Platform.isLinux ||
        Platform.isMacOS ||
        Platform.isAndroid)) {
      return;
    }
    final free = await const PlatformDiskSpaceProbe().availableBytes(
      Directory.systemTemp.path,
    );
    expect(free, isNotNull);
    expect(free! > 0, isTrue);
  });
}
