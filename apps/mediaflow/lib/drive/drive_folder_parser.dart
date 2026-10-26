import '../models/media_models.dart';
import 'drive_html.dart';

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
  static final RegExp _titleSuffix = RegExp(
    r'\s*[-–—]\s*Google\s+(?:Drive|Docs|Sheets|Slides)\s*$',
    caseSensitive: false,
  );

  static DriveFolderPage parse(String html) {
    final accessCode = detectAccessError(html);
    if (accessCode != null) {
      throw DriveFolderParseException(accessCode);
    }

    final titleMatch = _title.firstMatch(html);
    final rawTitle = titleMatch == null
        ? ''
        : htmlToText(titleMatch.group(1) ?? '');
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
      final rawHref = attributeValue(match.group(1) ?? '', 'href');
      if (rawHref == null) continue;
      final uri = Uri.tryParse(rawHref);
      if (uri == null) continue;
      final entry = _entryFor(uri, htmlToText(match.group(2) ?? ''));
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
        lower.contains('sign in to continue') ||
        lower.contains('identifier') && lower.contains('password')) {
      return MediaFlowErrorCode.loginRequired;
    }
    if (lower.contains('you need access') ||
        lower.contains('you do not have permission') ||
        lower.contains('access denied')) {
      return MediaFlowErrorCode.permissionDenied;
    }
    if (lower.contains('quota exceeded') ||
        lower.contains('download quota') ||
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
        url: 'https://docs.google.com/${_nativePath(nativeKind)}/d/$id',
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

  static String _nativePath(String kind) {
    switch (kind) {
      case 'spreadsheet':
        return 'spreadsheets';
      case 'presentation':
        return 'presentations';
      case 'form':
        return 'forms';
      case 'drawing':
        return 'drawings';
      case 'script':
        return 'scripts';
      case 'site':
        return 'sites';
      default:
        return 'document';
    }
  }
}
