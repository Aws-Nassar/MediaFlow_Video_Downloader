import 'package:flutter_test/flutter_test.dart';
import 'package:mediaflow/models/media_models.dart';
import 'package:mediaflow/sources/fake_source_adapter.dart';
import 'package:mediaflow/sources/source_adapter.dart';

void main() {
  group('SourceRegistry', () {
    test('labels known hosts', () {
      expect(
        SourceRegistry.labelFor(Uri.parse('https://youtu.be/abc')),
        'YouTube',
      );
      expect(
        SourceRegistry.labelFor(
          Uri.parse('https://drive.google.com/drive/folders/abc'),
        ),
        'Google Drive',
      );
      expect(
        SourceRegistry.labelFor(
          Uri.parse('https://soundcloud.com/artist/track'),
        ),
        'SoundCloud',
      );
    });

    test('creates a readable fallback title', () {
      expect(
        SourceRegistry.fallbackTitle(
          Uri.parse('https://example.com/files/My%20Video.mp4'),
        ),
        'My Video.mp4',
      );
      expect(
        SourceRegistry.fallbackTitle(
          Uri.parse('https://www.youtube.com/watch?v=fixture123'),
        ),
        'YouTube fixture123',
      );
    });

    test('resolves the fake adapter for http links', () {
      final adapter = FakeSourceAdapter(
        probeDelay: Duration.zero,
        stepDelay: Duration.zero,
      );
      final registry = SourceRegistry([adapter]);
      expect(registry.resolve(Uri.parse('https://example.com/a')).id, 'fake');
      expect(
        () => registry.resolve(Uri.parse('ftp://example.com/a')),
        throwsA(isA<MediaFlowException>()),
      );
    });
  });

  group('FakeSourceAdapter', () {
    test('detects a demo folder', () async {
      final adapter = FakeSourceAdapter(
        probeDelay: Duration.zero,
        stepDelay: Duration.zero,
      );
      final descriptor = await adapter.probe(
        Uri.parse('https://drive.google.com/drive/folders/demo-mixed'),
        downloadType: DownloadType.video,
      );
      expect(descriptor.isCollection, isTrue);
      expect(descriptor.itemCount, 3);
      expect(descriptor.sourceLabel, 'Google Drive');
    });

    test('maps a simulated login failure', () async {
      final adapter = FakeSourceAdapter(
        probeDelay: Duration.zero,
        stepDelay: Duration.zero,
      );
      expect(
        () => adapter.probe(
          Uri.parse('https://example.com/cookies'),
          downloadType: DownloadType.video,
        ),
        throwsA(
          isA<MediaFlowException>().having(
            (error) => error.error.code,
            'code',
            MediaFlowErrorCode.loginRequired,
          ),
        ),
      );
    });
  });

  test('formats byte sizes without losing the unit', () {
    expect(formatBytes(0), '—');
    expect(formatBytes(1024), '1.0 KB');
    expect(formatBytes(8 * 1024 * 1024), '8.0 MB');
  });
}
