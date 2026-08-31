class Album {
  final String id;
  final String title;
  final String? artist;
  final String? artistId;
  final int? year;
  final String? genre;
  final String? coverUrl;
  final int? trackCount;
  final int? duration; // seconds
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Album({
    required this.id,
    required this.title,
    this.artist,
    this.artistId,
    this.year,
    this.genre,
    this.coverUrl,
    this.trackCount,
    this.duration,
    this.createdAt,
    this.updatedAt,
  });
}
