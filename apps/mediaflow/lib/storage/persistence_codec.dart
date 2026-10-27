import 'dart:convert';

import '../models/media_models.dart';

MediaKind mediaKindFromName(String? name) {
  for (final value in MediaKind.values) {
    if (value.name == name) return value;
  }
  return MediaKind.file;
}

DownloadType downloadTypeFromName(String? name) {
  for (final value in DownloadType.values) {
    if (value.name == name) return value;
  }
  return DownloadType.video;
}

JobStatus jobStatusFromName(String? name) {
  for (final value in JobStatus.values) {
    if (value.name == name) return value;
  }
  return JobStatus.failed;
}

MediaFlowErrorCode? errorCodeFromName(String? name) {
  if (name == null || name.isEmpty) return null;
  for (final value in MediaFlowErrorCode.values) {
    if (value.name == name) return value;
  }
  return MediaFlowErrorCode.unknown;
}

MediaFlowErrorCode errorCodeOrUnknown(String? name) =>
    errorCodeFromName(name) ?? MediaFlowErrorCode.unknown;

String encodeEntries(List<MediaEntry> entries) {
  return jsonEncode([
    for (final entry in entries)
      {
        'title': entry.title,
        'url': entry.url,
        'sizeBytes': entry.sizeBytes,
        'kind': entry.kind.name,
        'id': entry.id,
        'relativePath': entry.relativePath,
        'blockedCode': entry.blockedCode?.name,
      },
  ]);
}

List<MediaEntry> decodeEntries(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    final entries = <MediaEntry>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final title = item['title'];
      final url = item['url'];
      if (title is! String || url is! String || url.isEmpty) continue;
      final size = item['sizeBytes'];
      entries.add(
        MediaEntry(
          title: title,
          url: url,
          sizeBytes: size is num ? size.toInt() : null,
          kind: mediaKindFromName(_text(item['kind'])),
          id: _text(item['id']),
          relativePath: _text(item['relativePath']),
          blockedCode: errorCodeFromName(_text(item['blockedCode'])),
        ),
      );
    }
    return entries;
  } catch (_) {
    return const [];
  }
}

String encodeFailures(List<BatchFailure> failures) {
  return jsonEncode([
    for (final failure in failures)
      {
        'jobId': failure.jobId,
        'title': failure.title,
        'url': failure.url,
        'code': failure.code.name,
      },
  ]);
}

String? _text(Object? value) => value is String ? value : null;

List<BatchFailure> decodeFailures(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    final failures = <BatchFailure>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final jobId = item['jobId'];
      final title = item['title'];
      final url = item['url'];
      if (jobId is! String || title is! String || url is! String) continue;
      failures.add(
        BatchFailure(
          jobId: jobId,
          title: title,
          url: url,
          code: errorCodeOrUnknown(_text(item['code'])),
        ),
      );
    }
    return failures;
  } catch (_) {
    return const [];
  }
}
