import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediaflow/drive/drive_http.dart';
import 'package:mediaflow/drive/drive_source_adapter.dart';
import 'package:mediaflow/models/media_models.dart';
import 'package:mediaflow/sources/source_adapter.dart';

import 'support/fake_drive_transport.dart';

const _folderId = 'fixtureRootFolderAAAAAAAAA';
const _fileId = 'fixtureFileADDDDDDDDDDDDDD';
const _docId = 'fixtureNativeDocumentHHHHHH';

String _fixture(String name) =>
    File('test/fixtures/drive/$name').readAsStringSync();

bool _containsBytes(List<int> haystack, String needle) {
  final target = utf8.encode(needle);
  for (var i = 0; i + target.length <= haystack.length; i++) {
    var match = true;
    for (var j = 0; j < target.length; j++) {
      if (haystack[i + j] != target[j]) {
        match = false;
        break;
      }
    }
    if (match) return true;
  }
  return false;
}

DownloadJob _job({
  required String url,
  String title = 'Download',
  String? relativePath,
  String id = 'job-1',
  List<MediaEntry> zipEntries = const [],
}) {
  return DownloadJob(
    id: id,
    batchId: 'batch-1',
    url: url,
    sourceId: 'drive.google.com',
    sourceLabel: 'Google Drive',
    title: title,
    downloadType: DownloadType.video,
    status: JobStatus.downloading,
    createdAt: DateTime(2026, 1, 1),
    relativePath: relativePath,
    zipEntries: zipEntries,
  );
}

void main() {
  late Directory temp;
  late FakeDriveTransport transport;
  late DriveSourceAdapter adapter;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('mediaflow-drive-');
    transport = FakeDriveTransport();
    adapter = DriveSourceAdapter(
      transport: transport,
      outputDirectory: temp.path,
    );
  });

  tearDown(() {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  test('probes a folder into nested entries and relative paths', () async {
    transport
      ..enqueueGet(htmlResponse(body: _fixture('root.html')))
      ..enqueueGet(htmlResponse(body: _fixture('subfolder.html')))
      ..enqueueGet(htmlResponse(body: _fixture('nested.html')));

    final descriptor = await adapter.probe(
      Uri.parse('https://drive.google.com/drive/folders/$_folderId'),
      downloadType: DownloadType.video,
    );

    expect(descriptor.isCollection, isTrue);
    expect(descriptor.title, 'Team Assets');
    expect(descriptor.itemCount, 5);
    expect(descriptor.entries.length, 5);
    expect(descriptor.entries[0].relativePath, 'Clip & Notes.mp4');
    expect(descriptor.entries[1].url, contains('docs.google.com'));
    expect(descriptor.entries[2].relativePath, 'Subfolder/Second file.pdf');
    expect(
      descriptor.entries[3].relativePath,
      'Subfolder/Nested/Third file.zip',
    );
    expect(descriptor.entries[4].title, 'Back to root');
    expect(
      descriptor.entries[4].blockedCode,
      MediaFlowErrorCode.collectionLimitReached,
    );
    expect(transport.getRequests, hasLength(3));
  });

  test('rejects a folder with only unsupported native entries', () async {
    transport.enqueueGet(
      htmlResponse(
        body:
            '<html><head><title>Forms - Google Drive</title></head><body>'
            '<a href="https://docs.google.com/forms/d/'
            'fixtureFormFFFFFFFFFFFFFFFF/view">Form</a>'
            '</body></html>',
      ),
    );

    await expectLater(
      adapter.probe(
        Uri.parse('https://drive.google.com/drive/folders/$_folderId'),
        downloadType: DownloadType.video,
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

  test('returns a clear error for an empty folder', () async {
    transport.enqueueGet(htmlResponse(body: _fixture('empty.html')));

    await expectLater(
      adapter.probe(
        Uri.parse('https://drive.google.com/drive/folders/$_folderId'),
        downloadType: DownloadType.video,
      ),
      throwsA(
        isA<MediaFlowException>().having(
          (error) => error.error.code,
          'code',
          MediaFlowErrorCode.emptyCollection,
        ),
      ),
    );
  });

  test('maps a forbidden folder page to permissionDenied', () async {
    transport.enqueueGet(htmlResponse(statusCode: 403, body: ''));

    await expectLater(
      adapter.probe(
        Uri.parse('https://drive.google.com/drive/folders/$_folderId'),
        downloadType: DownloadType.video,
      ),
      throwsA(
        isA<MediaFlowException>().having(
          (error) => error.error.code,
          'code',
          MediaFlowErrorCode.permissionDenied,
        ),
      ),
    );
  });

  test('maps an owner-disabled 403 page to downloadRestricted', () async {
    transport.enqueueGet(
      htmlResponse(
        statusCode: 403,
        body:
            '<html><body>The owner has disabled downloading of this file.'
            '</body></html>',
      ),
    );

    await expectLater(
      adapter.probe(
        Uri.parse('https://drive.google.com/drive/folders/$_folderId'),
        downloadType: DownloadType.video,
      ),
      throwsA(
        isA<MediaFlowException>().having(
          (error) => error.error.code,
          'code',
          MediaFlowErrorCode.downloadRestricted,
        ),
      ),
    );
  });

  test('maps a sign-in page to loginRequired', () async {
    transport.enqueueGet(htmlResponse(body: _fixture('sign_in.html')));

    await expectLater(
      adapter.probe(
        Uri.parse('https://drive.google.com/drive/folders/$_folderId'),
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

  test('reads a public file title without downloading it', () async {
    transport.enqueueGet(
      htmlResponse(
        body: '<html><head><title>My Clip - Google Drive</title></head></html>',
      ),
    );

    final descriptor = await adapter.probe(
      Uri.parse('https://drive.google.com/file/d/$_fileId/view'),
      downloadType: DownloadType.video,
    );

    expect(descriptor.title, 'My Clip');
    expect(descriptor.isCollection, isFalse);
    expect(transport.openRequests, isEmpty);
  });

  test(
    'downloads a direct file with progress and the response filename',
    () async {
      final bytes = [1, 2, 3, 4, 5, 6];
      transport.enqueueOpen(
        downloadResponse(
          bytes: bytes,
          contentType: 'video/mp4',
          disposition: 'attachment; filename="clip.mp4"',
        ),
      );

      final events = await adapter
          .download(
            _job(
              url: 'https://drive.google.com/file/d/$_fileId/view',
              title: 'view',
            ),
          )
          .toList();

      expect(events.whereType<DownloadProgress>(), isNotEmpty);
      final completed = events.whereType<DownloadCompleted>().single;
      expect(completed.totalBytes, bytes.length);
      expect(completed.filePath, endsWith('clip.mp4'));
      expect(File(completed.filePath).readAsBytesSync(), bytes);
      expect(transport.openRequests.single.queryParameters['id'], _fileId);
    },
  );

  test('keeps the folder relative path for a collection item', () async {
    transport.enqueueOpen(
      downloadResponse(
        bytes: [7, 8],
        contentType: 'application/pdf',
        disposition: 'attachment; filename="other.pdf"',
      ),
    );

    final events = await adapter
        .download(
          _job(
            url: 'https://drive.google.com/file/d/$_fileId/view',
            title: 'Second file.pdf',
            relativePath: 'Subfolder/Second file.pdf',
          ),
        )
        .toList();

    final completed = events.whereType<DownloadCompleted>().single;
    expect(
      completed.filePath,
      endsWith(
        '${Platform.pathSeparator}Subfolder'
        '${Platform.pathSeparator}Second file.pdf',
      ),
    );
    expect(File(completed.filePath).readAsBytesSync(), [7, 8]);
  });

  test('builds a ZIP from the selected folder files', () async {
    transport
      ..enqueueOpen(
        downloadResponse(
          bytes: utf8.encode('first'),
          disposition: 'attachment; filename="One.txt"',
        ),
      )
      ..enqueueOpen(
        downloadResponse(
          bytes: [2, 3],
          disposition: 'attachment; filename="Two.bin"',
        ),
      );

    final events = await adapter
        .download(
          _job(
            url: 'https://drive.google.com/drive/folders/$_folderId',
            title: 'Folder',
            zipEntries: const [
              MediaEntry(
                title: 'One.txt',
                url: 'https://drive.google.com/file/d/$_fileId/view',
                relativePath: 'One.txt',
              ),
              MediaEntry(
                title: 'Two.bin',
                url:
                    'https://drive.google.com/file/d/'
                    'fixtureFileBEEEEEEEEEEEEE/view',
                relativePath: 'Nested/Two.bin',
              ),
            ],
          ),
        )
        .toList();

    final completed = events.whereType<DownloadCompleted>().single;
    expect(completed.filePath, endsWith('Folder.zip'));
    expect(completed.skipped, isEmpty);
    expect(File(completed.filePath).existsSync(), isTrue);
    expect(completed.totalBytes, File(completed.filePath).lengthSync());
    final archive = File(completed.filePath).readAsBytesSync();
    expect(archive.take(4), [0x50, 0x4b, 0x03, 0x04]);
    expect(_containsBytes(archive, 'One.txt'), isTrue);
    expect(_containsBytes(archive, 'Nested/Two.bin'), isTrue);
    expect(
      temp.listSync().where((entry) => entry.path.contains('.mediaflow_zip_')),
      isEmpty,
    );
  });

  test('ZIP keeps successful files and reports skipped entries', () async {
    transport
      ..enqueueOpen(downloadResponse(statusCode: 403))
      ..enqueueOpen(
        downloadResponse(
          bytes: utf8.encode('kept'),
          disposition: 'attachment; filename="Kept.txt"',
        ),
      );

    final events = await adapter
        .download(
          _job(
            url: 'https://drive.google.com/drive/folders/$_folderId',
            title: 'Partial folder',
            zipEntries: const [
              MediaEntry(
                title: 'Blocked.txt',
                url: 'https://drive.google.com/file/d/$_fileId/view',
                relativePath: 'Blocked.txt',
              ),
              MediaEntry(
                title: 'Kept.txt',
                url:
                    'https://drive.google.com/file/d/'
                    'fixtureFileBEEEEEEEEEEEEE/view',
                relativePath: 'Kept.txt',
              ),
            ],
          ),
        )
        .toList();

    final completed = events.whereType<DownloadCompleted>().single;
    expect(completed.skipped, hasLength(1));
    expect(completed.skipped.single.title, 'Blocked.txt');
    expect(completed.skipped.single.code, MediaFlowErrorCode.permissionDenied);
  });

  test('ZIP fails cleanly when every entry fails', () async {
    transport
      ..enqueueOpen(downloadResponse(statusCode: 403))
      ..enqueueOpen(downloadResponse(statusCode: 404));

    final events = await adapter
        .download(
          _job(
            url: 'https://drive.google.com/drive/folders/$_folderId',
            title: 'Failed folder',
            zipEntries: const [
              MediaEntry(
                title: 'One.txt',
                url: 'https://drive.google.com/file/d/$_fileId/view',
                relativePath: 'One.txt',
              ),
              MediaEntry(
                title: 'Two.txt',
                url:
                    'https://drive.google.com/file/d/'
                    'fixtureFileBEEEEEEEEEEEEE/view',
                relativePath: 'Two.txt',
              ),
            ],
          ),
        )
        .toList();

    final failed = events.whereType<DownloadFailed>().single;
    expect(failed.skipped, hasLength(2));
    expect(
      File(
        '${temp.path}${Platform.pathSeparator}Failed folder.zip',
      ).existsSync(),
      isFalse,
    );
    expect(
      temp.listSync().where((entry) => entry.path.contains('.mediaflow_zip_')),
      isEmpty,
    );
  });

  test('reports every entry when archive staging cannot start', () async {
    final blocker = File('${temp.path}${Platform.pathSeparator}blocked')
      ..writeAsStringSync('not a directory');
    adapter = DriveSourceAdapter(
      transport: transport,
      outputDirectory: blocker.path,
    );

    final entries = const [
      MediaEntry(
        title: 'One.txt',
        url: 'https://drive.google.com/file/d/$_fileId/view',
        relativePath: 'One.txt',
      ),
      MediaEntry(
        title: 'Two.txt',
        url:
            'https://drive.google.com/file/d/'
            'fixtureFileBEEEEEEEEEEEEE/view',
        relativePath: 'Two.txt',
      ),
    ];
    final events = await adapter
        .download(
          _job(
            url: 'https://drive.google.com/drive/folders/$_folderId',
            title: 'Failed staging',
            zipEntries: entries,
          ),
        )
        .toList();

    final failed = events.whereType<DownloadFailed>().single;
    expect(failed.skipped, hasLength(2));
    expect(failed.skipped.map((failure) => failure.title), [
      'One.txt',
      'Two.txt',
    ]);
    expect(
      failed.skipped.map((failure) => failure.url),
      entries.map((entry) => entry.url),
    );
  });

  test(
    'cancelling an archive removes staging and does not write a ZIP',
    () async {
      final controller = StreamController<List<int>>();
      var aborted = false;
      transport.enqueueOpen(
        DriveDownloadResponse(
          statusCode: 200,
          finalUri: Uri.parse('https://drive.google.com/uc?id=$_fileId'),
          headers: const {
            'content-type': 'application/octet-stream',
            'content-length': '100',
          },
          body: controller.stream,
          abort: () {
            aborted = true;
            if (!controller.isClosed) controller.close();
          },
        ),
      );

      final future = adapter
          .download(
            _job(
              url: 'https://drive.google.com/drive/folders/$_folderId',
              title: 'Cancel folder',
              zipEntries: const [
                MediaEntry(
                  title: 'One.bin',
                  url: 'https://drive.google.com/file/d/$_fileId/view',
                  relativePath: 'One.bin',
                ),
              ],
            ),
          )
          .toList();
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (transport.openRequests.isEmpty &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }

      await adapter.cancel('job-1');
      final events = await future;

      expect(aborted, isTrue);
      expect(events.whereType<DownloadCancelled>(), hasLength(1));
      expect(
        temp
            .listSync(recursive: true)
            .where((entry) => entry.path.endsWith('.zip')),
        isEmpty,
      );
      expect(
        temp
            .listSync(recursive: true)
            .where((entry) => entry.path.contains('.mediaflow_zip_')),
        isEmpty,
      );
    },
  );

  test('follows the public confirmation form once', () async {
    final form =
        '''
      <html><body>
      <form action="https://drive.usercontent.google.com/download" method="get">
        <input type="hidden" name="id" value="$_fileId">
        <input type="hidden" name="export" value="download">
        <input type="hidden" name="confirm" value="t">
        <input type="hidden" name="uuid" value="fixture-uuid">
      </form>
      </body></html>
    ''';
    transport
      ..enqueueOpen(
        downloadResponse(
          bytes: utf8.encode(form),
          contentType: 'text/html; charset=utf-8',
          finalUri: Uri.parse('https://drive.google.com/uc?id=$_fileId'),
        ),
      )
      ..enqueueOpen(
        downloadResponse(
          bytes: utf8.encode('large-file'),
          contentType: 'application/octet-stream',
          disposition: 'attachment; filename="large.bin"',
          finalUri: Uri.parse(
            'https://drive.usercontent.google.com/download?id=$_fileId',
          ),
        ),
      );

    final events = await adapter
        .download(
          _job(
            url: 'https://drive.google.com/file/d/$_fileId/view',
            title: 'large.bin',
          ),
        )
        .toList();

    expect(transport.openRequests, hasLength(2));
    expect(transport.openRequests[0].queryParameters['export'], 'download');
    expect(transport.openRequests[1].host, 'drive.usercontent.google.com');
    expect(transport.openRequests[1].queryParameters['confirm'], 't');
    final completed = events.whereType<DownloadCompleted>().single;
    expect(completed.filePath, endsWith('large.bin'));
    expect(File(completed.filePath).readAsStringSync(), 'large-file');
  });

  test('reports an access page instead of writing HTML as a file', () async {
    transport.enqueueOpen(
      downloadResponse(
        bytes: utf8.encode(
          '<html><body>You need access. Request access.</body></html>',
        ),
        contentType: 'text/html; charset=utf-8',
      ),
    );

    final events = await adapter
        .download(_job(url: 'https://drive.google.com/file/d/$_fileId/view'))
        .toList();

    final failed = events.whereType<DownloadFailed>().single;
    expect(failed.error.code, MediaFlowErrorCode.permissionDenied);
    expect(temp.listSync(), isEmpty);
  });

  test('maps an owner-disabled download page to downloadRestricted', () async {
    transport.enqueueOpen(
      downloadResponse(
        statusCode: 403,
        bytes: utf8.encode(
          '<html><body>The owner has disabled downloading of this file.'
          '</body></html>',
        ),
        contentType: 'text/html; charset=utf-8',
      ),
    );

    final events = await adapter
        .download(_job(url: 'https://drive.google.com/file/d/$_fileId/view'))
        .toList();

    final failed = events.whereType<DownloadFailed>().single;
    expect(failed.error.code, MediaFlowErrorCode.downloadRestricted);
    expect(temp.listSync(), isEmpty);
  });

  test('maps an HTTP 429 to a retryable rate-limit error', () async {
    transport.enqueueOpen(
      downloadResponse(
        statusCode: 429,
        contentType: 'text/html; charset=utf-8',
      ),
    );

    final events = await adapter
        .download(_job(url: 'https://drive.google.com/file/d/$_fileId/view'))
        .toList();

    final failed = events.whereType<DownloadFailed>().single;
    expect(failed.error.code, MediaFlowErrorCode.rateLimited);
    expect(failed.error.isRetryable, isTrue);
  });

  test('does not complete a truncated response', () async {
    transport.enqueueOpen(
      downloadResponse(
        bytes: [1, 2],
        contentType: 'application/octet-stream',
        disposition: 'attachment; filename="short.bin"',
        headers: const {'content-length': '5'},
      ),
    );

    final events = await adapter
        .download(_job(url: 'https://drive.google.com/file/d/$_fileId/view'))
        .toList();

    final failed = events.whereType<DownloadFailed>().single;
    expect(failed.error.code, MediaFlowErrorCode.network);
    expect(failed.error.isRetryable, isTrue);
    expect(temp.listSync(recursive: true), isEmpty);
  });

  test('exports a Google-native document as PDF', () async {
    transport.enqueueOpen(
      downloadResponse(
        bytes: [37, 80, 68, 70],
        contentType: 'application/pdf',
        disposition: 'attachment; filename="Plan.pdf"',
        finalUri: Uri.parse('https://doc-0s.googleusercontent.com/export'),
      ),
    );

    final events = await adapter
        .download(
          _job(
            url: 'https://docs.google.com/document/d/$_docId/edit',
            title: 'Plan',
          ),
        )
        .toList();

    final request = transport.openRequests.single;
    expect(request.host, 'docs.google.com');
    expect(request.path, '/document/d/$_docId/export');
    expect(request.queryParameters['format'], 'pdf');
    final completed = events.whereType<DownloadCompleted>().single;
    expect(completed.filePath, endsWith('Plan.pdf'));
    expect(File(completed.filePath).readAsBytesSync(), [37, 80, 68, 70]);
  });

  test('cancels an in-flight download and removes the partial file', () async {
    final controller = StreamController<List<int>>();
    var aborted = false;
    transport.enqueueOpen(
      DriveDownloadResponse(
        statusCode: 200,
        finalUri: Uri.parse('https://drive.google.com/uc?id=$_fileId'),
        headers: const {
          'content-type': 'application/octet-stream',
          'content-length': '100',
        },
        body: controller.stream,
        abort: () {
          aborted = true;
          if (!controller.isClosed) controller.close();
        },
      ),
    );

    final future = adapter
        .download(
          _job(
            url: 'https://drive.google.com/file/d/$_fileId/view',
            title: 'pending.bin',
          ),
        )
        .toList();
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (transport.openRequests.isEmpty &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }

    await adapter.cancel('job-1');
    final events = await future;

    expect(aborted, isTrue);
    expect(events.whereType<DownloadCancelled>(), hasLength(1));
    expect(
      temp
          .listSync(recursive: true)
          .where((file) => file.path.endsWith('.part')),
      isEmpty,
    );
  });

  test('cancels a job before its stream starts', () async {
    await adapter.cancel('job-1');

    final events = await adapter
        .download(_job(url: 'https://drive.google.com/file/d/$_fileId/view'))
        .toList();

    expect(events.single, isA<DownloadCancelled>());
    expect(transport.openRequests, isEmpty);
  });

  test('does not allow a relative path to escape the output folder', () async {
    transport.enqueueOpen(
      downloadResponse(
        bytes: [9],
        contentType: 'application/octet-stream',
        disposition: 'attachment; filename="escape.txt"',
      ),
    );

    final events = await adapter
        .download(
          _job(
            url: 'https://drive.google.com/file/d/$_fileId/view',
            title: 'escape.txt',
            relativePath: '../escape.txt',
          ),
        )
        .toList();

    final completed = events.whereType<DownloadCompleted>().single;
    expect(
      File(completed.filePath).absolute.path.toLowerCase(),
      startsWith(temp.absolute.path.toLowerCase()),
    );
    expect(File(completed.filePath).readAsBytesSync(), [9]);
  });
}
