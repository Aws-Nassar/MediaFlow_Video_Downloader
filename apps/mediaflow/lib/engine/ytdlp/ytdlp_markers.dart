/// Marker prefixes emitted by the engine and consumed by the app.
///
/// Keep these stable: the download command writes them to stdout and the
/// parser looks for them by name.
abstract final class YtDlpMarkers {
  static const progress = 'MF_PROGRESS';
  static const file = 'MF_FILE';
}
