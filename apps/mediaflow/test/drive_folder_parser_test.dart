import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediaflow/drive/drive_folder_parser.dart';
import 'package:mediaflow/models/media_models.dart';

String _fixture(String name) =>
    File('test/fixtures/drive/$name').readAsStringSync();

void main() {
  test('parses folder title, files, folders, and native documents', () {
    final page = DriveFolderParser.parse(_fixture('root.html'));

    expect(page.name, 'Team Assets');
    expect(page.entries.length, 3);
    expect(page.entries[0].kind, DriveEntryKind.folder);
    expect(page.entries[0].name, 'Subfolder');
    expect(page.entries[1].kind, DriveEntryKind.file);
    expect(page.entries[1].name, 'Clip & Notes.mp4');
    expect(page.entries[2].kind, DriveEntryKind.native);
    expect(page.entries[2].name, 'Plan & Scope');
    expect(page.entries[2].nativeKind, 'document');
  });

  test(
    'keeps a link-shared folder with no files as a successful empty page',
    () {
      final page = DriveFolderParser.parse(_fixture('empty.html'));

      expect(page.name, 'Empty Folder');
      expect(page.entries, isEmpty);
    },
  );

  test('classifies sign-in pages as loginRequired', () {
    expect(
      () => DriveFolderParser.parse(_fixture('sign_in.html')),
      throwsA(
        isA<DriveFolderParseException>().having(
          (error) => error.code,
          'code',
          MediaFlowErrorCode.loginRequired,
        ),
      ),
    );
  });

  test('classifies missing titles as driveLayoutChanged', () {
    expect(
      () => DriveFolderParser.parse('<html><body>nothing here</body></html>'),
      throwsA(
        isA<DriveFolderParseException>().having(
          (error) => error.code,
          'code',
          MediaFlowErrorCode.driveLayoutChanged,
        ),
      ),
    );
  });

  test('detects quota and malware pages before parsing', () {
    expect(
      DriveFolderParser.detectAccessError(
        '<html><body>Too many users have viewed or downloaded this file.</body></html>',
      ),
      MediaFlowErrorCode.quotaExceeded,
    );
    expect(
      DriveFolderParser.detectAccessError(
        '<html><body>This file has been identified as malware.</body></html>',
      ),
      MediaFlowErrorCode.downloadRestricted,
    );
  });
}
