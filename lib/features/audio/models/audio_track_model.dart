class AudioTrackModel {
  final String id;
  final String title;
  final String artist;
  final String url;
  final String? artworkUrl;
  final Duration? duration;

  AudioTrackModel({
    required this.id,
    required this.title,
    this.artist = 'Unknown Artist',
    required this.url,
    this.artworkUrl,
    this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'url': url,
      'artworkUrl': artworkUrl,
      'durationMs': duration?.inMilliseconds,
    };
  }

  factory AudioTrackModel.fromMap(Map<dynamic, dynamic> map) {
    return AudioTrackModel(
      id: map['id'] as String,
      title: map['title'] as String? ?? 'Audio Track',
      artist: map['artist'] as String? ?? 'Unknown Artist',
      url: map['url'] as String? ?? '',
      artworkUrl: map['artworkUrl'] as String?,
      duration: map['durationMs'] != null ? Duration(milliseconds: map['durationMs'] as int) : null,
    );
  }
}
