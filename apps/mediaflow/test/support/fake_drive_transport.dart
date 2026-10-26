import 'package:mediaflow/drive/drive_http.dart';

/// A queued fake transport for Drive adapter tests. No socket is opened.
class FakeDriveTransport implements DriveHttpTransport {
  final List<DriveHttpResponse> getResponses = [];
  final List<DriveDownloadResponse> openResponses = [];
  final List<Uri> getRequests = [];
  final List<Uri> openRequests = [];
  bool closed = false;

  void enqueueGet(DriveHttpResponse response) {
    getResponses.add(response);
  }

  void enqueueOpen(DriveDownloadResponse response) {
    openResponses.add(response);
  }

  @override
  Future<DriveHttpResponse> get(Uri uri) async {
    getRequests.add(uri);
    if (getResponses.isEmpty) {
      throw StateError('No queued GET response for $uri');
    }
    return getResponses.removeAt(0);
  }

  @override
  Future<DriveDownloadResponse> open(Uri uri) async {
    openRequests.add(uri);
    if (openResponses.isEmpty) {
      throw StateError('No queued download response for $uri');
    }
    return openResponses.removeAt(0);
  }

  @override
  void close() {
    closed = true;
  }
}

DriveHttpResponse htmlResponse({
  required String body,
  int statusCode = 200,
  Uri? finalUri,
  Map<String, String> headers = const {
    'content-type': 'text/html; charset=utf-8',
  },
}) {
  return DriveHttpResponse(
    statusCode: statusCode,
    finalUri: finalUri ?? Uri.parse('https://drive.google.com/'),
    headers: headers,
    body: body,
  );
}

DriveDownloadResponse downloadResponse({
  List<int> bytes = const [],
  int statusCode = 200,
  String contentType = 'application/octet-stream',
  String? disposition,
  Uri? finalUri,
  Map<String, String>? headers,
  Stream<List<int>>? body,
  void Function()? onAbort,
}) {
  final responseHeaders = <String, String>{
    'content-type': contentType,
    ...?headers,
  };
  if (bytes.isNotEmpty) {
    responseHeaders.putIfAbsent('content-length', () => '${bytes.length}');
  }
  if (disposition != null) {
    responseHeaders['content-disposition'] = disposition;
  }
  return DriveDownloadResponse(
    statusCode: statusCode,
    finalUri: finalUri ?? Uri.parse('https://drive.google.com/'),
    headers: responseHeaders,
    body: body ?? Stream<List<int>>.value(bytes),
    abort: onAbort ?? () {},
  );
}
