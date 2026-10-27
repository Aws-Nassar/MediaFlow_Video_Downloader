import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediaflow/drive/drive_source_adapter.dart';
import 'package:mediaflow/models/media_models.dart';
import 'package:mediaflow/state/app_state.dart';

import 'support/fake_drive_transport.dart';

const _folderId = 'fixtureZipFolderAAAAAAAAA';
const _oneId = 'fixtureFileADDDDDDDDDDDDDD';
const _twoId = 'fixtureFileBEEEEEEEEEEEEE';

String _folderHtml() =>
    '''
<html><head><title>ZIP Folder - Google Drive</title></head><body>
  <a href="https://drive.google.com/file/d/$_oneId/view">One.txt</a>
  <a href="https://drive.google.com/file/d/$_twoId/view">Two.txt</a>
</body></html>
''';

Future<void> _waitForSummary(AppState state) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (DateTime.now().isBefore(deadline)) {
    if (state.lastSummary != null && state.activeJobs.isEmpty) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('Timed out waiting for the batch summary.');
}

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

void main() {
  late Directory temp;
  late FakeDriveTransport transport;
  late DriveSourceAdapter adapter;
  late AppState state;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('mediaflow-zip-flow-');
    transport = FakeDriveTransport();
    adapter = DriveSourceAdapter(
      transport: transport,
      outputDirectory: temp.path,
    );
    state = AppState(
      adapter: adapter,
      concurrency: 1,
      outputDirectory: temp.path,
    );
  });

  tearDown(() {
    state.dispose();
    transport.close();
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  Future<void> analyzeZip() async {
    await state.analyzeAndEnqueue(
      'https://drive.google.com/drive/folders/$_folderId',
      selectCollection: (descriptor) async {
        return CollectionSelection(entries: descriptor.entries, asZip: true);
      },
    );
    await _waitForSummary(state);
  }

  test('selection ZIP creates one archive job and an item summary', () async {
    transport
      ..enqueueGet(htmlResponse(body: _folderHtml()))
      ..enqueueOpen(
        downloadResponse(
          bytes: utf8.encode('one'),
          disposition: 'attachment; filename="One.txt"',
        ),
      )
      ..enqueueOpen(
        downloadResponse(
          bytes: utf8.encode('two'),
          disposition: 'attachment; filename="Two.txt"',
        ),
      );

    await analyzeZip();

    final job = state.jobs.single;
    expect(job.isArchive, isTrue);
    expect(job.zipEntries, hasLength(2));
    expect(job.status, JobStatus.completed);
    expect(job.filePath, endsWith('ZIP Folder.zip'));
    final summary = state.lastSummary!;
    expect(summary.total, 2);
    expect(summary.completed, 2);
    expect(summary.failed, 0);
    expect(summary.skipped, 0);
    expect(summary.skippedItems, isEmpty);
    expect(File(job.filePath!).existsSync(), isTrue);

    final archive = File(job.filePath!).readAsBytesSync();
    expect(_containsBytes(archive, 'One.txt'), isTrue);
    expect(_containsBytes(archive, 'Two.txt'), isTrue);
  });

  test(
    'partial ZIP failure keeps successes and reports skipped files',
    () async {
      transport
        ..enqueueGet(htmlResponse(body: _folderHtml()))
        ..enqueueOpen(downloadResponse(statusCode: 403))
        ..enqueueOpen(
          downloadResponse(
            bytes: utf8.encode('two'),
            disposition: 'attachment; filename="Two.txt"',
          ),
        );

      await analyzeZip();

      final summary = state.lastSummary!;
      expect(summary.total, 2);
      expect(summary.completed, 1);
      expect(summary.failed, 0);
      expect(summary.skipped, 1);
      expect(summary.skippedItems.single.title, 'One.txt');
      expect(
        summary.skippedItems.single.code,
        MediaFlowErrorCode.permissionDenied,
      );

      final archive = File(state.jobs.single.filePath!).readAsBytesSync();
      expect(_containsBytes(archive, 'Two.txt'), isTrue);
      expect(_containsBytes(archive, 'One.txt'), isFalse);
    },
  );
}
