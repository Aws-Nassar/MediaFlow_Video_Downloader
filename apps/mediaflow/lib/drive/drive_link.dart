import '../models/media_models.dart';

enum DriveLinkKind { folder, file, native }

/// A parsed link-shared Google Drive URL.
///
/// Only public Drive URLs are recognized. There is no account, OAuth token, or
/// API key involved in this model.
class DriveLink {
  final DriveLinkKind kind;
  final String id;
  final String? nativeKind;

  const DriveLink._({required this.kind, required this.id, this.nativeKind});

  bool get isFolder => kind == DriveLinkKind.folder;
  bool get isFile => kind == DriveLinkKind.file;
  bool get isNative => kind == DriveLinkKind.native;

  String get canonicalUrl {
    switch (kind) {
      case DriveLinkKind.folder:
        return 'https://drive.google.com/drive/folders/$id';
      case DriveLinkKind.file:
        return 'https://drive.google.com/file/d/$id/view';
      case DriveLinkKind.native:
        return 'https://docs.google.com/${nativeKind ?? 'document'}/d/$id';
    }
  }

  MediaKind get mediaKind =>
      kind == DriveLinkKind.folder ? MediaKind.collection : MediaKind.file;
}

abstract final class DriveLinks {
  static final RegExp _idPattern = RegExp(r'^[-\w]{25,}$');
  static final RegExp _nativeKinds = RegExp(
    r'^(document|spreadsheet|presentation|form|drawing|script|site)$',
  );

  /// Returns a parsed link for Drive pages we can handle, or `null`.
  ///
  /// `canHandle` must stay pattern-based and must not make a network call.
  static DriveLink? parse(Uri uri) {
    if (!uri.hasScheme) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    final host = uri.host.toLowerCase();
    if (host != 'drive.google.com' && host != 'docs.google.com') return null;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (host == 'docs.google.com') {
      for (var i = 0; i + 2 < segments.length; i++) {
        if (segments[i + 1] != 'd') continue;
        final id = segments[i + 2];
        if (!_idPattern.hasMatch(id)) continue;
        final kind = _singularNativeKind(segments[i]);
        if (kind == null) continue;
        return DriveLink._(
          kind: DriveLinkKind.native,
          id: id,
          nativeKind: kind,
        );
      }
    }

    for (var i = 0; i + 1 < segments.length; i++) {
      if (segments[i] != 'folders') continue;
      final id = segments[i + 1];
      if (_idPattern.hasMatch(id)) {
        return DriveLink._(kind: DriveLinkKind.folder, id: id);
      }
    }

    for (var i = 0; i + 2 < segments.length; i++) {
      if (segments[i] != 'file' || segments[i + 1] != 'd') continue;
      final id = segments[i + 2];
      if (_idPattern.hasMatch(id)) {
        return DriveLink._(kind: DriveLinkKind.file, id: id);
      }
    }

    final queryId = uri.queryParameters['id'];
    if (queryId != null && _idPattern.hasMatch(queryId)) {
      if (uri.path.toLowerCase().contains('embeddedfolderview')) {
        return DriveLink._(kind: DriveLinkKind.folder, id: queryId);
      }
      return DriveLink._(kind: DriveLinkKind.file, id: queryId);
    }
    return null;
  }

  static bool isDriveHost(Uri uri) {
    final host = uri.host.toLowerCase();
    return host == 'drive.google.com' || host == 'docs.google.com';
  }

  static String? _singularNativeKind(String segment) {
    final lower = segment.toLowerCase();
    final singular = lower.endsWith('s')
        ? lower.substring(0, lower.length - 1)
        : lower;
    return _nativeKinds.hasMatch(singular) ? singular : null;
  }
}
