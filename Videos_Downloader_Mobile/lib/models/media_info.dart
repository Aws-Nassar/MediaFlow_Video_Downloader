class MediaInfo {
  final String title;
  final String? thumbnail;
  final String duration;
  final String? uploader;
  final String? description;
  final bool isPlaylist;
  final List<Map<String, dynamic>> formats;
  final Map<String, dynamic> raw;

  MediaInfo({
    required this.title,
    this.thumbnail,
    this.duration = '0:00',
    this.uploader,
    this.description,
    this.isPlaylist = false,
    this.formats = const [],
    this.raw = const {},
  });

  factory MediaInfo.fromJson(Map<String, dynamic> json) {
    return MediaInfo(
      title: json['title'] ?? 'Unknown',
      thumbnail: json['thumbnail'],
      duration: _formatDuration(json['duration']),
      uploader: json['uploader'] ?? json['channel'] ?? json['creator'],
      description: json['description'],
      isPlaylist: json['is_playlist'] == true,
      formats: (json['formats'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      raw: json,
    );
  }

  static String _formatDuration(dynamic secs) {
    if (secs == null) return '0:00';
    num total;
    if (secs is num) {
      total = secs;
    } else if (secs is String) {
      total = num.tryParse(secs) ?? 0;
    } else {
      return '0:00';
    }
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    if (h > 0) {
      return '${h}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m}:${s.toString().padLeft(2, '0')}';
  }
}
