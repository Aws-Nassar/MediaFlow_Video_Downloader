import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediaflow/engine/ytdlp/ytdlp_command_builder.dart';
import 'package:mediaflow/engine/ytdlp/ytdlp_error_mapper.dart';
import 'package:mediaflow/engine/ytdlp/ytdlp_markers.dart';
import 'package:mediaflow/engine/ytdlp/ytdlp_parser.dart';
import 'package:mediaflow/models/media_models.dart';

Uri get _uri => Uri.parse('https://example.com/watch?v=fixture123');

String get _fixture =>
    File('test/fixtures/ytdlp/single_video.json').readAsStringSync();

void main() {
  group('yt-dlp command builder', () {
    test('builds a deterministic probe command', () {
      final args = YtDlpCommandBuilder.probeArgs(_uri);

      expect(args, contains('--ignore-config'));
      expect(args, contains('--dump-single-json'));
      expect(args, contains('--no-playlist'));
      expect(args.sublist(args.length - 2), ['--', _uri.toString()]);
    });

    test('builds a video command that merges with FFmpeg', () {
      final args = YtDlpCommandBuilder.downloadArgs(
        uri: _uri,
        downloadType: DownloadType.video,
        outputDirectory: r'C:\MediaFlow\Downloads',
        ffmpegPath: r'C:\MediaFlow\ffmpeg.exe',
      );

      expect(args, contains('--no-simulate'));
      expect(args, contains('--progress'));
      expect(
        args[args.indexOf('--progress-template') + 1],
        contains(YtDlpMarkers.progress),
      );
      expect(
        args[args.indexOf('--print') + 1],
        startsWith('after_move:${YtDlpMarkers.file} '),
      );
      expect(args[args.indexOf('-P') + 1], r'C:\MediaFlow\Downloads');
      expect(args[args.indexOf('-o') + 1], YtDlpCommandBuilder.outputTemplate);
      expect(
        args[args.indexOf('--ffmpeg-location') + 1],
        r'C:\MediaFlow\ffmpeg.exe',
      );
      expect(args[args.indexOf('-f') + 1], 'bv*+ba/b');
      expect(args, isNot(contains('--extract-audio')));
    });

    test('uses a progressive format when FFmpeg is absent', () {
      final args = YtDlpCommandBuilder.downloadArgs(
        uri: _uri,
        downloadType: DownloadType.video,
        outputDirectory: r'C:\MediaFlow\Downloads',
      );

      expect(args[args.indexOf('-f') + 1], 'best[acodec!=none][vcodec!=none]');
      expect(args, isNot(contains('--ffmpeg-location')));
    });

    test('builds an audio extraction command', () {
      final args = YtDlpCommandBuilder.downloadArgs(
        uri: _uri,
        downloadType: DownloadType.audio,
        outputDirectory: r'C:\MediaFlow\Downloads',
        ffmpegPath: r'C:\MediaFlow\ffmpeg.exe',
      );

      expect(args[args.indexOf('-f') + 1], 'ba/b');
      expect(args, contains('--extract-audio'));
      expect(args[args.indexOf('--audio-format') + 1], 'm4a');
    });
  });

  group('yt-dlp probe parser', () {
    test('maps metadata and merged size', () {
      final descriptor = parseYtDlpProbe(
        _fixture,
        uri: _uri,
        downloadType: DownloadType.video,
        ffmpegAvailable: true,
      );

      expect(descriptor.title, 'Fixture video');
      expect(descriptor.author, 'Fixture channel');
      expect(descriptor.duration, const Duration(seconds: 212));
      expect(descriptor.kind, MediaKind.video);
      expect(descriptor.totalBytes, 54000000);
      expect(descriptor.sourceLabel, 'example.com');
      expect(descriptor.isCollection, isFalse);
    });

    test('uses the progressive size without FFmpeg', () {
      final descriptor = parseYtDlpProbe(
        _fixture,
        uri: _uri,
        downloadType: DownloadType.video,
        ffmpegAvailable: false,
      );

      expect(descriptor.totalBytes, 15000000);
    });

    test('uses the audio stream size in audio mode', () {
      final descriptor = parseYtDlpProbe(
        _fixture,
        uri: _uri,
        downloadType: DownloadType.audio,
        ffmpegAvailable: true,
      );

      expect(descriptor.kind, MediaKind.audio);
      expect(descriptor.totalBytes, 4000000);
    });

    test('falls back to the URL path when the title is empty', () {
      final descriptor = parseYtDlpProbe(
        '{"_type":"video","title":"","formats":[]}',
        uri: Uri.parse('https://example.com/files/My%20Video.mp4'),
        downloadType: DownloadType.video,
        ffmpegAvailable: true,
      );

      expect(descriptor.title, 'My Video.mp4');
      expect(descriptor.totalBytes, isNull);
    });

    test('rejects playlist output in the single-video slice', () {
      expect(
        () => parseYtDlpProbe(
          '{"_type":"playlist","entries":[{"id":"one"}]}',
          uri: _uri,
          downloadType: DownloadType.video,
          ffmpegAvailable: true,
        ),
        throwsA(
          isA<MediaFlowException>().having(
            (error) => error.error.code,
            'code',
            MediaFlowErrorCode.unsupportedUrl,
          ),
        ),
      );
    });

    test('reports unreadable metadata as unknown', () {
      expect(
        () => parseYtDlpProbe(
          'not json',
          uri: _uri,
          downloadType: DownloadType.video,
          ffmpegAvailable: true,
        ),
        throwsA(
          isA<MediaFlowException>().having(
            (error) => error.error.code,
            'code',
            MediaFlowErrorCode.unknown,
          ),
        ),
      );
    });
  });

  group('yt-dlp output parser', () {
    test('parses downloading progress', () {
      final progress = parseYtDlpProgressLine(
        'MF_PROGRESS {"status":"downloading","downloaded_bytes":5242880,'
        '"total_bytes":10485760,"speed":1048576,"eta":5}',
      );

      expect(progress, isNotNull);
      expect(progress!.fraction, 0.5);
      expect(progress.downloadedBytes, 5242880);
      expect(progress.totalBytes, 10485760);
      expect(progress.bytesPerSecond, 1048576);
      expect(progress.eta, const Duration(seconds: 5));
    });

    test('treats finished progress as complete', () {
      final progress = parseYtDlpProgressLine(
        'MF_PROGRESS {"status":"finished","downloaded_bytes":90,'
        '"total_bytes":100,"speed":null,"eta":null}',
      );

      expect(progress, isNotNull);
      expect(progress!.fraction, 1);
      expect(progress.downloadedBytes, 100);
      expect(progress.bytesPerSecond, isNull);
      expect(progress.eta, isNull);
    });

    test('ignores malformed or unrelated lines', () {
      expect(parseYtDlpProgressLine('not a progress line'), isNull);
      expect(parseYtDlpProgressLine('MF_PROGRESS not-json'), isNull);
    });

    test('parses the final file path, including spaces', () {
      expect(
        parseYtDlpFileLine(r'MF_FILE C:\Users\Test\Downloads\My Video.mp4'),
        r'C:\Users\Test\Downloads\My Video.mp4',
      );
      expect(parseYtDlpFileLine('MF_FILE   '), isNull);
    });
  });

  group('yt-dlp error mapping', () {
    test('maps permanent and transient failures', () {
      expect(
        mapYtDlpProcessFailure(
          details: 'ERROR: Sign in to confirm your age',
          exitCode: 1,
        ).code,
        MediaFlowErrorCode.loginRequired,
      );
      expect(
        mapYtDlpProcessFailure(
          details: 'ERROR: This video is private',
          exitCode: 1,
        ).code,
        MediaFlowErrorCode.permissionDenied,
      );
      expect(
        mapYtDlpProcessFailure(
          details: 'ERROR: The uploader has disabled downloads',
          exitCode: 1,
        ).code,
        MediaFlowErrorCode.downloadRestricted,
      );
      expect(
        mapYtDlpProcessFailure(
          details: 'ERROR: Requested format is not available',
          exitCode: 1,
        ).code,
        MediaFlowErrorCode.formatUnavailable,
      );
      expect(
        mapYtDlpProcessFailure(
          details: 'ERROR: HTTP Error 429: Too Many Requests',
          exitCode: 1,
        ).code,
        MediaFlowErrorCode.rateLimited,
      );
      expect(
        mapYtDlpProcessFailure(
          details: 'ERROR: [Errno 28] No space left on device',
          exitCode: 1,
        ).code,
        MediaFlowErrorCode.diskFull,
      );
      expect(
        mapYtDlpProcessFailure(
          details: 'ERROR: Postprocessing: ffmpeg not found',
          exitCode: 1,
        ).code,
        MediaFlowErrorCode.ffmpegMissing,
      );
      expect(
        mapYtDlpProcessFailure(
          details: 'ERROR: Unsupported URL: https://example.com/file',
          exitCode: 1,
        ).code,
        MediaFlowErrorCode.unsupportedUrl,
      );
      expect(
        mapYtDlpProcessFailure(
          details: 'ERROR: Temporary failure in name resolution',
          exitCode: 1,
        ).code,
        MediaFlowErrorCode.network,
      );
      expect(
        mapYtDlpProcessFailure(
          details: 'ERROR: something strange happened',
          exitCode: 1,
        ).code,
        MediaFlowErrorCode.unknown,
      );
    });

    test('marks network and rate-limit errors retryable', () {
      final network = mapYtDlpProcessFailure(
        details: 'ERROR: Connection reset by peer',
        exitCode: 1,
      );
      final rateLimited = mapYtDlpProcessFailure(
        details: 'ERROR: HTTP Error 429: Too Many Requests',
        exitCode: 1,
      );
      final login = mapYtDlpProcessFailure(
        details: 'ERROR: Sign in to continue',
        exitCode: 1,
      );

      expect(network.isRetryable, isTrue);
      expect(rateLimited.isRetryable, isTrue);
      expect(login.isRetryable, isFalse);
    });

    test('redacts signed URLs and credential headers', () {
      final error = mapYtDlpProcessFailure(
        details:
            'ERROR: Unable to download webpage: '
            'https://cdn.example.com/file?token=secret&sig=abc\n'
            'Cookie: SID=secret; HSID=other\n'
            'Authorization: Bearer secret-token',
        exitCode: 1,
      );

      final details = error.technicalDetails!;
      expect(error.code, MediaFlowErrorCode.network);
      expect(details, isNot(contains('token=secret')));
      expect(details, isNot(contains('sig=abc')));
      expect(details, isNot(contains('SID=secret')));
      expect(details, isNot(contains('Bearer')));
      expect(details, contains('https://cdn.example.com/file'));
      expect(details, contains('Cookie: [redacted]'));
    });

    test('uses a stable fallback when stderr is empty', () {
      final error = mapYtDlpProcessFailure(details: '', exitCode: 7);
      expect(error.code, MediaFlowErrorCode.unknown);
      expect(error.technicalDetails, 'yt-dlp exited with code 7.');
    });
  });
}
