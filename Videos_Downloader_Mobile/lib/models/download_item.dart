class DownloadItem {
  final String url;
  final String title;
  final String? thumbnail;
  final String ext;
  final String quality;
  final bool isAudio;
  final String? filePath;
  final Map<String, dynamic> options;

  DownloadItem({
    required this.url,
    required this.title,
    this.thumbnail,
    required this.ext,
    required this.quality,
    this.isAudio = false,
    this.filePath,
    this.options = const {},
  });

  Map<String, dynamic> toJson() => {
        'url': url,
        'title': title,
        'thumbnail': thumbnail,
        'ext': ext,
        'quality': quality,
        'isAudio': isAudio,
        'filePath': filePath,
        'timestamp': DateTime.now().toIso8601String(),
      };

  factory DownloadItem.fromJson(Map<String, dynamic> json) => DownloadItem(
        url: json['url'] ?? '',
        title: json['title'] ?? '',
        thumbnail: json['thumbnail'],
        ext: json['ext'] ?? 'mp4',
        quality: json['quality'] ?? 'Best Available',
        isAudio: json['isAudio'] ?? false,
        filePath: json['filePath'],
      );
}

enum DownloadStatus { idle, fetching, downloading, completed, error, cancelled }

enum QualityGroup { video, audio }
