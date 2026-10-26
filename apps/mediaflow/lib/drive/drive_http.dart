import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../models/media_models.dart';

/// A fully buffered HTML response used for folder listings and file metadata.
class DriveHttpResponse {
  final int statusCode;
  final Uri finalUri;
  final Map<String, String> headers;
  final String body;

  DriveHttpResponse({
    required this.statusCode,
    required this.finalUri,
    required Map<String, String> headers,
    required this.body,
  }) : headers = Map.unmodifiable(headers);

  String? header(String name) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == name.toLowerCase()) return entry.value;
    }
    return null;
  }
}

/// A streaming response used for file downloads.
class DriveDownloadResponse {
  final int statusCode;
  final Uri finalUri;
  final Map<String, String> headers;
  final Stream<List<int>> body;
  final void Function() abort;

  DriveDownloadResponse({
    required this.statusCode,
    required this.finalUri,
    required Map<String, String> headers,
    required this.body,
    required this.abort,
  }) : headers = Map.unmodifiable(headers);

  String? header(String name) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == name.toLowerCase()) return entry.value;
    }
    return null;
  }
}

/// Small seam used by tests to avoid live network calls.
abstract interface class DriveHttpTransport {
  Future<DriveHttpResponse> get(Uri uri);

  Future<DriveDownloadResponse> open(Uri uri);

  void close();
}

/// Public Drive HTML and download transport backed by Dart's [HttpClient].
///
/// It deliberately keeps no cookie jar and sends no account credentials.
class IoDriveHttpTransport implements DriveHttpTransport {
  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/120.0.0.0 Safari/537.36';

  static const _requestTimeout = Duration(seconds: 30);
  static const _bodyTimeout = Duration(seconds: 30);
  static const _maxPageBytes = 4 * 1024 * 1024;

  final HttpClient _client;

  IoDriveHttpTransport({HttpClient? client})
    : _client = client ?? HttpClient() {
    _client.userAgent = _userAgent;
    _client.autoUncompress = true;
    _client.connectionTimeout = const Duration(seconds: 20);
    _client.idleTimeout = const Duration(seconds: 15);
  }

  @override
  Future<DriveHttpResponse> get(Uri uri) async {
    final response = await open(uri);
    final builder = BytesBuilder(copy: false);
    try {
      await for (final chunk in response.body.timeout(_bodyTimeout)) {
        if (builder.length + chunk.length > _maxPageBytes) {
          response.abort();
          throw const MediaFlowException(
            MediaFlowError(
              code: MediaFlowErrorCode.driveLayoutChanged,
              technicalDetails: 'The Drive HTML page was too large to read.',
            ),
          );
        }
        builder.add(chunk);
      }
    } finally {
      // The response is fully consumed in the normal path. Aborting here is a
      // best-effort cleanup for an oversized or interrupted page.
      response.abort();
    }
    return DriveHttpResponse(
      statusCode: response.statusCode,
      finalUri: response.finalUri,
      headers: response.headers,
      body: utf8.decode(builder.takeBytes(), allowMalformed: true),
    );
  }

  @override
  Future<DriveDownloadResponse> open(Uri uri) async {
    final request = await _client.getUrl(uri).timeout(_requestTimeout);
    request.followRedirects = true;
    request.maxRedirects = 5;
    request.headers.set(
      HttpHeaders.acceptHeader,
      'text/html,application/xhtml+xml,application/octet-stream,*/*;q=0.8',
    );

    final response = await request.close().timeout(_requestTimeout);
    var aborted = false;
    void abort() {
      if (aborted) return;
      aborted = true;
      try {
        request.abort();
      } catch (_) {
        // The request may already be closed.
      }
    }

    var finalUri = uri;
    for (final redirect in response.redirects) {
      finalUri = finalUri.resolveUri(redirect.location);
    }

    final headers = <String, String>{};
    response.headers.forEach((name, values) {
      headers[name.toLowerCase()] = values.join(',');
    });

    return DriveDownloadResponse(
      statusCode: response.statusCode,
      finalUri: finalUri,
      headers: headers,
      body: response,
      abort: abort,
    );
  }

  @override
  void close() {
    _client.close(force: true);
  }
}

MediaFlowError? driveErrorForStatus(int statusCode) {
  if (statusCode == 401) {
    return const MediaFlowError(
      code: MediaFlowErrorCode.loginRequired,
      technicalDetails: 'Drive requested sign-in.',
    );
  }
  if (statusCode == 403) {
    return const MediaFlowError(
      code: MediaFlowErrorCode.permissionDenied,
      technicalDetails: 'Drive denied access.',
    );
  }
  if (statusCode == 404 || statusCode == 410) {
    return const MediaFlowError(
      code: MediaFlowErrorCode.notFound,
      technicalDetails: 'Drive item was not found.',
    );
  }
  if (statusCode == 429) {
    return const MediaFlowError(
      code: MediaFlowErrorCode.rateLimited,
      technicalDetails: 'Drive asked the client to slow down.',
      retryable: true,
    );
  }
  if (statusCode >= 500) {
    return const MediaFlowError(
      code: MediaFlowErrorCode.network,
      technicalDetails: 'Drive returned a server error.',
      retryable: true,
    );
  }
  if (statusCode >= 400) {
    return const MediaFlowError(
      code: MediaFlowErrorCode.unknown,
      technicalDetails: 'Drive returned an unexpected HTTP status.',
    );
  }
  return null;
}
