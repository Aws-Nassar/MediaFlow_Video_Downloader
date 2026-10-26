import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediaflow/drive/drive_folder_expander.dart';
import 'package:mediaflow/drive/drive_folder_parser.dart';

const _rootId = 'fixtureRootFolderAAAAAAAAA';
const _subId = 'fixtureSubFolderBBBBBBBBBB';
const _nestedId = 'fixtureNestedFolderCCCCCC';

String _fixture(String name) =>
    File('test/fixtures/drive/$name').readAsStringSync();

void main() {
  late Map<String, DriveFolderPage> pages;
  late List<String> calls;

  setUp(() {
    pages = {
      _rootId: DriveFolderParser.parse(_fixture('root.html')),
      _subId: DriveFolderParser.parse(_fixture('subfolder.html')),
      _nestedId: DriveFolderParser.parse(_fixture('nested.html')),
    };
    calls = [];
  });

  Future<DriveFolderPage> load(String id) async {
    calls.add(id);
    return pages[id]!;
  }

  test('walks nested folders and skips a cycle', () async {
    final result = await DriveFolderExpander(loadFolder: load).expand(_rootId);

    expect(calls, [_rootId, _subId, _nestedId]);
    expect(result.name, 'Team Assets');
    expect(result.files.map((file) => file.relativePath).toList(), [
      'Clip & Notes.mp4',
      'Plan & Scope',
      'Subfolder/Second file.pdf',
      'Subfolder/Nested/Third file.zip',
    ]);
    expect(result.files[1].isNative, isTrue);
    expect(result.skipped.single.reason, DriveSkipReason.cycle);
    expect(result.skipped.single.name, 'Back to root');
    expect(result.truncated, isFalse);
  });

  test('respects the depth limit', () async {
    final result = await DriveFolderExpander(
      loadFolder: load,
      maxDepth: 1,
    ).expand(_rootId);

    expect(calls, [_rootId, _subId]);
    expect(result.files.length, 3);
    expect(result.skipped.single.reason, DriveSkipReason.depthLimit);
    expect(result.skipped.single.name, 'Nested');
  });

  test('stops at the item limit and leaves the rest unprocessed', () async {
    final result = await DriveFolderExpander(
      loadFolder: load,
      maxItems: 2,
    ).expand(_rootId);

    expect(calls, [_rootId]);
    expect(result.files.length, 1);
    expect(result.files.single.name, 'Clip & Notes.mp4');
    expect(result.skipped.single.reason, DriveSkipReason.itemLimit);
    expect(result.skipped.single.name, 'Plan & Scope');
    expect(result.truncated, isTrue);
  });

  test('returns an empty expansion for an empty folder', () async {
    pages[_rootId] = DriveFolderParser.parse(_fixture('empty.html'));

    final result = await DriveFolderExpander(loadFolder: load).expand(_rootId);

    expect(result.name, 'Empty Folder');
    expect(result.files, isEmpty);
    expect(result.skipped, isEmpty);
    expect(result.truncated, isFalse);
  });

  test('makes duplicate filenames unique', () async {
    const duplicatePage = DriveFolderPage(
      name: 'Duplicates',
      entries: [
        DriveFolderEntry(
          id: 'fixtureDuplicateOne000000001',
          name: 'same.bin',
          kind: DriveEntryKind.file,
          url:
              'https://drive.google.com/file/d/fixtureDuplicateOne000000001/view',
        ),
        DriveFolderEntry(
          id: 'fixtureDuplicateTwo000000002',
          name: 'same.bin',
          kind: DriveEntryKind.file,
          url:
              'https://drive.google.com/file/d/fixtureDuplicateTwo000000002/view',
        ),
      ],
    );
    pages[_rootId] = duplicatePage;

    final result = await DriveFolderExpander(loadFolder: load).expand(_rootId);

    expect(result.files[0].relativePath, 'same.bin');
    expect(result.files[1].relativePath, 'same [fixtur].bin');
  });
}
