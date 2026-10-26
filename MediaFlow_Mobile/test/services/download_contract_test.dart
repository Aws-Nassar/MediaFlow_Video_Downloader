import 'package:flutter_test/flutter_test.dart';
import 'package:mediaflow_android/services/download_contract.dart';

void main() {
  group('normalizePercent', () {
    test('keeps 0..1 fractions', () {
      expect(normalizePercent(0), 0);
      expect(normalizePercent(0.42), closeTo(0.42, 1e-9));
      expect(normalizePercent(1), 1);
    });

    test('converts 0..100 percentages', () {
      expect(normalizePercent(42), closeTo(0.42, 1e-9));
      expect(normalizePercent(100), 1);
      expect(normalizePercent('75'), closeTo(0.75, 1e-9));
    });

    test('clamps invalid values', () {
      expect(normalizePercent(null), 0);
      expect(normalizePercent(-5), 0);
      expect(normalizePercent(150), 1);
      expect(normalizePercent(double.nan), 0);
    });
  });

  group('extractDownloadedFiles', () {
    test('reads the downloaded_files list', () {
      expect(
        extractDownloadedFiles({
          'downloaded_files': ['/a.mp4', '', '/b.mp4'],
        }),
        ['/a.mp4', '/b.mp4'],
      );
    });

    test('falls back to file_path', () {
      expect(extractDownloadedFiles({'file_path': '/a.mp4'}), ['/a.mp4']);
    });

    test('returns an empty list when no paths are present', () {
      expect(extractDownloadedFiles({}), isEmpty);
      expect(extractDownloadedFiles({'downloaded_files': null}), isEmpty);
    });
  });
}
