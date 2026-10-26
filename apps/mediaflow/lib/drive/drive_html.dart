import 'dart:convert';

/// Decodes the small set of entities used by Drive's public HTML pages.
String decodeHtmlEntities(String value) {
  var result = value
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&#x27;', "'")
      .replaceAll('&nbsp;', ' ');
  result = result.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
    final code = int.tryParse(match.group(1)!);
    return code == null ? match.group(0)! : String.fromCharCode(code);
  });
  result = result.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
    final code = int.tryParse(match.group(1)!, radix: 16);
    return code == null ? match.group(0)! : String.fromCharCode(code);
  });
  return result;
}

String htmlToText(String html) {
  return decodeHtmlEntities(
    html.replaceAll(RegExp(r'<[^>]*>'), ' '),
  ).replaceAll(RegExp(r'\s+'), ' ').trim();
}

String? attributeValue(String attributes, String attribute) {
  final pattern = RegExp(
    "(?:^|\\s)${RegExp.escape(attribute)}"
    "\\s*=\\s*(?:\"([^\"]*)\"|'([^']*)')",
    caseSensitive: false,
  );
  final match = pattern.firstMatch(attributes);
  if (match == null) return null;
  return decodeHtmlEntities(match.group(1) ?? match.group(2) ?? '');
}

String? mediaType(Map<String, String> headers) {
  final value = _header(headers, 'content-type');
  if (value == null) return null;
  return value.split(';').first.trim().toLowerCase();
}

int? contentLength(Map<String, String> headers) {
  final value = _header(headers, 'content-length');
  if (value == null) return null;
  final parsed = int.tryParse(value.trim());
  return parsed == null || parsed <= 0 ? null : parsed;
}

String? fileNameFromDisposition(String? header) {
  if (header == null || header.trim().isEmpty) return null;
  final extended = RegExp(
    r"filename\*\s*=\s*(?:UTF-8|utf-8)''([^;]+)",
    caseSensitive: false,
  ).firstMatch(header);
  if (extended != null) {
    return _decodeFileName(extended.group(1)!);
  }
  final plain = RegExp(
    r'filename\s*=\s*(?:"([^"]*)"|([^;]+))',
    caseSensitive: false,
  ).firstMatch(header);
  if (plain == null) return null;
  return _decodeFileName(plain.group(1) ?? plain.group(2) ?? '');
}

String? _decodeFileName(String value) {
  var decoded = value.trim();
  if (decoded.startsWith('"') && decoded.endsWith('"')) {
    decoded = decoded.substring(1, decoded.length - 1);
  }
  try {
    decoded = Uri.decodeComponent(decoded);
  } on ArgumentError {
    // Keep the literal value if the server did not percent-encode it.
  }
  decoded = decoded.replaceAll(RegExp(r'[\\/]'), '_').trim();
  return decoded.isEmpty ? null : decoded;
}

String? _header(Map<String, String> headers, String name) {
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == name) return entry.value;
  }
  return null;
}

/// Extracts the hidden confirmation form used for large Drive downloads.
abstract final class DriveConfirmationForm {
  static final RegExp _form = RegExp(
    r'<form\b([^>]*)>(.*?)</form>',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _input = RegExp(
    r'<input\b([^>]*)>',
    caseSensitive: false,
  );
  static final RegExp _anchor = RegExp(r'<a\b([^>]*)>', caseSensitive: false);

  static Uri? parse(String html, Uri baseUri) {
    for (final form in _form.allMatches(html)) {
      final action = attributeValue(form.group(1) ?? '', 'action');
      if (action == null || action.isEmpty) continue;
      var actionUri = Uri.tryParse(action);
      if (actionUri != null && !actionUri.hasScheme) {
        actionUri = baseUri.resolveUri(actionUri);
      }
      if (actionUri == null || !_allowed(actionUri)) continue;

      final query = Map<String, String>.from(actionUri.queryParameters);
      for (final input in _input.allMatches(form.group(2) ?? '')) {
        final attrs = input.group(1) ?? '';
        final name = attributeValue(attrs, 'name');
        final value = attributeValue(attrs, 'value');
        if (name == null || name.isEmpty || value == null) continue;
        query[name] = value;
      }
      if (query.containsKey('id')) {
        return actionUri.replace(queryParameters: query);
      }
    }

    for (final anchor in _anchor.allMatches(html)) {
      final href = attributeValue(anchor.group(1) ?? '', 'href');
      if (href == null) continue;
      var uri = Uri.tryParse(href);
      if (uri != null && !uri.hasScheme) uri = baseUri.resolveUri(uri);
      if (uri == null || !_allowed(uri)) continue;
      final query = uri.queryParameters;
      if (query.containsKey('id') && query.containsKey('confirm')) {
        return uri;
      }
    }
    return null;
  }

  static bool _allowed(Uri uri) {
    if (uri.scheme != 'https') return false;
    final host = uri.host.toLowerCase();
    return host == 'drive.google.com' ||
        host == 'drive.usercontent.google.com' ||
        host == 'docs.google.com' ||
        host.endsWith('.googleusercontent.com');
  }
}

/// Decodes UTF-8 bytes from a recorded page or response body.
String decodeUtf8(List<int> bytes) => utf8.decode(bytes, allowMalformed: true);
