import '../../models/media_models.dart';

/// Maps yt-dlp stderr/exit status to a stable app error.
///
/// This is deliberately conservative: only known permanent restrictions are
/// marked non-retryable, and unknown failures stay `unknown` rather than
/// guessing at a bypass.
MediaFlowError mapYtDlpProcessFailure({
  required String details,
  required int exitCode,
  bool cancelled = false,
}) {
  if (cancelled) {
    return const MediaFlowError(code: MediaFlowErrorCode.cancelled);
  }

  final text = details.toLowerCase();
  var code = MediaFlowErrorCode.unknown;
  var retryable = false;

  if (_containsAny(text, [
    'no space left',
    'disk full',
    'not enough space',
    'enospc',
  ])) {
    code = MediaFlowErrorCode.diskFull;
  } else if (_containsAny(text, [
    'ffmpeg not found',
    'ffprobe not found',
    'ffmpeg is not installed',
    'ffmpeg not installed',
    'postprocessing: ffmpeg',
  ])) {
    code = MediaFlowErrorCode.ffmpegMissing;
  } else if (_containsAny(text, [
    'protected by drm',
    'digital rights management',
    'drm protected',
    'drm-protected',
  ])) {
    code = MediaFlowErrorCode.drmProtected;
  } else if (_containsAny(text, [
    'paywall',
    'requires payment',
    'paid content',
    'premium content',
  ])) {
    code = MediaFlowErrorCode.paywalled;
  } else if (_containsAny(text, [
    'cookies have expired',
    'cookies expired',
    'cookie expired',
    'cookies are no longer valid',
  ])) {
    code = MediaFlowErrorCode.cookiesExpired;
  } else if (_containsAny(text, [
    'sign in',
    'log in',
    'login required',
    'login is required',
    'confirm your age',
    'age-restricted',
    'age restricted',
    'use --cookies',
    'cookies for authentication',
  ])) {
    code = MediaFlowErrorCode.loginRequired;
  } else if (_containsAny(text, [
    'owner has disabled',
    'uploader has disabled',
    'downloads disabled',
    'download disabled',
    'not downloadable',
  ])) {
    code = MediaFlowErrorCode.downloadRestricted;
  } else if (_containsAny(text, [
    'private video',
    'this video is private',
    'permission',
    'not authorized',
    'access denied',
    'http error 403',
    'forbidden',
    'members-only',
    'members only',
    'join this channel',
  ])) {
    code = MediaFlowErrorCode.permissionDenied;
  } else if (_containsAny(text, [
    'not available in your country',
    'blocked in your country',
    'geo restricted',
    'geo-restricted',
    'geo blocked',
  ])) {
    code = MediaFlowErrorCode.geoBlocked;
  } else if (_containsAny(text, [
    'workspace policy',
    'policy blocked',
    'blocked by policy',
    'organization policy',
  ])) {
    code = MediaFlowErrorCode.policyBlocked;
  } else if (_containsAny(text, [
    'http error 404',
    'video unavailable',
    'this video is unavailable',
    'removed by the uploader',
    'has been removed',
    'does not exist',
    'not found',
  ])) {
    code = MediaFlowErrorCode.notFound;
  } else if (_containsAny(text, [
    'http error 429',
    'too many requests',
    'rate limit',
    'rate-limit',
  ])) {
    code = MediaFlowErrorCode.rateLimited;
    retryable = true;
  } else if (_containsAny(text, [
    'live event will begin',
    'premieres in',
    'upcoming premiere',
    'live stream is not available',
  ])) {
    code = MediaFlowErrorCode.liveUnavailable;
  } else if (_containsAny(text, ['unsupported url'])) {
    code = MediaFlowErrorCode.unsupportedUrl;
  } else if (_containsAny(text, [
    'requested format is not available',
    'no video formats found',
    'no formats found',
    'no suitable formats',
    'format is not available',
  ])) {
    code = MediaFlowErrorCode.formatUnavailable;
  } else if (_containsAny(text, ['quota exceeded', 'storage quota'])) {
    code = MediaFlowErrorCode.quotaExceeded;
    retryable = true;
  } else if (_containsAny(text, [
    'timed out',
    'timeout',
    'connection reset',
    'connection refused',
    'connection aborted',
    'temporary failure',
    'unable to download webpage',
    'unable to connect',
    'getaddrinfo',
    'remote end closed',
    'incomplete read',
    'ssl',
    'http error 500',
    'http error 502',
    'http error 503',
    'http error 504',
    'network',
  ])) {
    code = MediaFlowErrorCode.network;
    retryable = true;
  }

  final redacted = redactEngineDetails(details);
  final technicalDetails = redacted.isEmpty
      ? 'yt-dlp exited with code $exitCode.'
      : redacted;

  return MediaFlowError(
    code: code,
    technicalDetails: technicalDetails,
    retryable: retryable,
  );
}

/// Removes signed query parameters, fragments, and credential headers from
/// engine text before it is stored or shown.
String redactEngineDetails(String details, {int maxLength = 1200}) {
  var text = details.replaceAll(RegExp(r'\r\n?'), '\n').trim();
  text = text.replaceAllMapped(
    RegExp(
      r'^(cookie|authorization|proxy-authorization)\s*:.*$',
      caseSensitive: false,
      multiLine: true,
    ),
    (match) => '${match[1]}: [redacted]',
  );
  text = text.replaceAllMapped(
    RegExp(r'''https?://[^\s<>"']+'''),
    (match) => _redactUrl(match[0]!),
  );
  text = text.replaceAll(RegExp(r'[ \t]+\n'), '\n');
  text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();

  if (text.length > maxLength) {
    return '${text.substring(0, maxLength)}...';
  }
  return text;
}

String _redactUrl(String raw) {
  final trailingMatch = RegExp(r'[),.;]+$').firstMatch(raw);
  final trailing = trailingMatch?.group(0) ?? '';
  final core = trailing.isEmpty
      ? raw
      : raw.substring(0, raw.length - trailing.length);
  final uri = Uri.tryParse(core);
  if (uri == null || uri.host.isEmpty) return raw;
  final port = uri.hasPort ? ':${uri.port}' : '';
  return '${uri.scheme}://${uri.host}$port${uri.path}$trailing';
}

bool _containsAny(String text, List<String> needles) {
  for (final needle in needles) {
    if (text.contains(needle)) return true;
  }
  return false;
}
