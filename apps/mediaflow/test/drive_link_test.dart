import 'package:flutter_test/flutter_test.dart';
import 'package:mediaflow/drive/drive_link.dart';
import 'package:mediaflow/models/media_models.dart';

const _folderId = 'fixtureRootFolderAAAAAAAAA';
const _fileId = 'fixtureFileADDDDDDDDDDDDDD';
const _docId = 'fixtureNativeDocumentHHHHHH';
const _sheetId = 'fixtureSheetDocumentIIIIIIIII';

void main() {
  test('parses folder links with or without a user segment', () {
    for (final url in [
      'https://drive.google.com/drive/folders/$_folderId?usp=sharing',
      'https://drive.google.com/drive/u/0/folders/$_folderId',
      'https://drive.google.com/embeddedfolderview?id=$_folderId#list',
    ]) {
      final link = DriveLinks.parse(Uri.parse(url));
      expect(link, isNotNull, reason: url);
      expect(link!.kind, DriveLinkKind.folder);
      expect(link.id, _folderId);
      expect(link.mediaKind, MediaKind.collection);
      expect(
        link.canonicalUrl,
        'https://drive.google.com/drive/folders/$_folderId',
      );
    }
  });

  test('parses file links and query-based download links', () {
    for (final url in [
      'https://drive.google.com/file/d/$_fileId/view?usp=sharing',
      'https://drive.google.com/open?id=$_fileId',
      'https://drive.google.com/uc?export=download&id=$_fileId',
    ]) {
      final link = DriveLinks.parse(Uri.parse(url));
      expect(link, isNotNull, reason: url);
      expect(link!.kind, DriveLinkKind.file);
      expect(link.id, _fileId);
      expect(link.mediaKind, MediaKind.file);
    }
  });

  test('recognizes Google-native documents', () {
    final doc = DriveLinks.parse(
      Uri.parse('https://docs.google.com/document/d/$_docId/edit'),
    );
    final sheet = DriveLinks.parse(
      Uri.parse('https://docs.google.com/spreadsheets/d/$_sheetId/edit'),
    );

    expect(doc!.kind, DriveLinkKind.native);
    expect(doc.nativeKind, 'document');
    expect(sheet!.nativeKind, 'spreadsheet');
  });

  test('rejects short IDs, foreign hosts, and non-http schemes', () {
    expect(
      DriveLinks.parse(
        Uri.parse('https://drive.google.com/drive/folders/demo-mixed'),
      ),
      isNull,
    );
    expect(
      DriveLinks.parse(
        Uri.parse('https://example.com/drive/folders/$_folderId'),
      ),
      isNull,
    );
    expect(DriveLinks.parse(Uri.parse('javascript:alert($_folderId)')), isNull);
  });
}
