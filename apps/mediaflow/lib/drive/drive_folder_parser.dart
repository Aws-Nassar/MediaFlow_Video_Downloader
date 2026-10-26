import 'dart:convert';

import '../models/media_models.dart';

enum DriveEntryKind { file, folder, native }

class DriveFolderEntry {
  final String id;
  final String name;
  final DriveEntryKind kind;
  final String? nativeKind;
  final String url;

  const DriveFolderEntry({
    required this.id,
    required this.name,
    required this.kind,
    required this.url,
    this.nativeKind,
  });

  bool get isFolder => kind == DriveEntryKind.folder;
  bool get isNative => kind == DriveEntryKind.native;
}

class DriveFolderPage {
  final String name;
  final List<DriveFolderEntry> entries;

  const DriveFolderPage({required this.name, required this.entries});
}

class DriveFolderParseException implements Exception {
  final MediaFlowErrorCode code;
  final String? details;

  const DriveFolderParseException(this.code, [this.details]);

  @override
  String toString() => 'DriveFolderParseException(${code.name})';
}

/// Parses the public `embeddedfolderview` HTML used for link-shared folders.
///
/// This is intentionally tolerant of markup changes. It looks for anchors that
/// point at Drive files, folders, or Google-native documents rather than
/// depending on a visual layout class.
abstract final class DriveFolderParser {
  static final RegExp _anchor = RegExp(
    r'<a\b([^>]*)>(.*?)</a>',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _href = RegExp(
    r'''href\s*=\s*(?:"([^"]*)"|'([^']*)')''',
    caseSensitive: false,
  );
  static final RegExp _title = RegExp(
    r'<title\b[^>]*>(.*?)</title>',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _folder = RegExp(
    r'/folders/([-\w]{25,})(?:[/?#]|$)',
    caseSensitive: false,
  );
  static final RegExp _file = RegExp(
    r'/file/d/([-\w]{25,})(?:[/?#]|$)',
    caseSensitive: false,
  );
  static final RegExp _native = RegExp(
    r'/(document|spreadsheets?|presentations?|forms?|drawings?)/d/([-\w]{25,})(?:[/?#]|$)',
    caseSensitive: false,
  );
  static final RegExp _whitespace = RegExp(r'\s+');
  static final RegExp _tags = RegExp(r'<[^>]*>');
  static final RegExp _titleSuffix = RegExp(
    r'\s*[-–—]\s*Google Drive\s*$',
    caseSensitive: false,
  );

  static DriveFolderPage parse(String html) {
    final accessCode = detectAccessError(html);
    if (accessCode != null) {
      throw DriveFolderParseException(accessCode);
    }

    final titleMatch = _title.firstMatch(html);
    final rawTitle = titleMatch == null ? '' : _text(titleMatch.group(1) ?? '');
    final name = rawTitle.replaceFirst(_titleSuffix, '').trim();
    if (name.isEmpty || name.toLowerCase() == 'google drive') {
      throw const DriveFolderParseException(
        MediaFlowErrorCode.driveLayoutChanged,
        'Folder page has no title.',
      );
    }

    final entries = <DriveFolderEntry>[];
    final seen = <String>{};
    for (final match in _anchor.allMatches(html)) {
      final attributes = match.group(1) ?? '';
      final hrefMatch = _href.firstMatch(attributes);
      if (hrefMatch == null) continue;
      final rawHref = _decode(hrefMatch.group(1) ?? hrefMatch.group(2) ?? '');
      final uri = Uri.tryParse(rawHref);
      if (uri == null) continue;
      final entry = _entryFor(uri, _text(match.group(2) ?? ''));
      if (entry == null) continue;
      if (!seen.add('${entry.kind.name}:${entry.id}')) continue;
      entries.add(entry);
    }

    return DriveFolderPage(name: name, entries: entries);
  }

  /// Detects common public-access pages before trying to parse entries.
  static MediaFlowErrorCode? detectAccessError(String html) {
    final lower = html.toLowerCase();
    if (lower.contains('sign in - google accounts') ||
        lower.contains('identifier') && lower.contains('password')) {
      return MediaFlowErrorCode.loginRequired;
    }
    if (lower.contains('you need access') ||
        lower.contains('request access') ||
        lower.contains('you do not have permission')) {
      return MediaFlowErrorCode.permissionDenied;
    }
    if (lower.contains('quota exceeded') ||
        lower.contains('too many users have viewed or downloaded')) {
      return MediaFlowErrorCode.quotaExceeded;
    }
    if (lower.contains('identified as malware') ||
        lower.contains('owner has disabled downloading')) {
      return MediaFlowErrorCode.downloadRestricted;
    }
    return null;
  }

  static DriveFolderEntry? _entryFor(Uri uri, String name) {
    if (name.isEmpty) return null;
    final host = uri.host.toLowerCase();
    if (host == 'docs.google.com') {
      final match = _native.firstMatch(uri.path);
      if (match == null) return null;
      final nativeKind = _singular(match.group(1)!);
      final id = match.group(2)!;
      return DriveFolderEntry(
        id: id,
        name: name,
        kind: DriveEntryKind.native,
        nativeKind: nativeKind,
        url: 'https://docs.google.com/$nativeKind/d/$id',
      );
    }
    if (host != 'drive.google.com') return null;

    final folderMatch = _folder.firstMatch(uri.path);
    if (folderMatch != null) {
      final id = folderMatch.group(1)!;
      return DriveFolderEntry(
        id: id,
        name: name,
        kind: DriveEntryKind.folder,
        url: 'https://drive.google.com/drive/folders/$id',
      );
    }

    final fileMatch = _file.firstMatch(uri.path);
    if (fileMatch != null) {
      final id = fileMatch.group(1)!;
      return DriveFolderEntry(
        id: id,
        name: name,
        kind: DriveEntryKind.file,
        url: 'https://drive.google.com/file/d/$id/view',
      );
    }
    return null;
  }

  static String _singular(String value) {
    final lower = value.toLowerCase();
    return lower.endsWith('s') ? lower.substring(0, lower.length - 1) : lower;
  }

  static String _text(String html) {
    return _decode(
      html.replaceAll(_tags, ' '),
    ).replaceAll(_whitespace, ' ').trim();
  }

  static String _decode(String value) {
    var result = value
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll('&nbsp;', ' ');
    result = result.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (match) => String.fromCharCode(int.parse(match.group(1)!)),
    );
    result = result.replaceAllMapped(
      RegExp(r'&#x([0-9a-fA-F]+);'),
      (match) => String.fromCharCode(int.parse(match.group(1)!, radix: 16)),
    );
    return result;
  }

  /// Decodes HTML that may be used for an inline page fixture.
  static String decodeUtf8(List<int> bytes) =>
      utf8.decode(bytes, allowMalformed: true);
}
