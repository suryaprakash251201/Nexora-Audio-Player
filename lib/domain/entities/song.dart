class Song {
  final String id;
  final String title;
  final String? artist;
  final String? artistId;
  final String? album;
  final String? albumId;
  final int? duration; // seconds
  final int? trackNumber;
  final int? discNumber;
  final int? year;
  final String? genre;
  final String? coverUrl;
  final String? streamUrl;
  final String? artworkUrl;
  final int? bitrate;
  final int? sampleRate;
  final String? codec;
  final bool? lossless;
  final int? fileSize;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isFavorite;
  final bool isDownloaded;
  final String? localPath;

  /// For playlist items on the real server: the playlist-item id used for
  /// reorder/remove operations (not the song identity itself).
  final String? itemRef;

  const Song({
    required this.id,
    required this.title,
    this.artist,
    this.artistId,
    this.album,
    this.albumId,
    this.duration,
    this.trackNumber,
    this.discNumber,
    this.year,
    this.genre,
    this.coverUrl,
    this.streamUrl,
    this.artworkUrl,
    this.bitrate,
    this.sampleRate,
    this.codec,
    this.lossless,
    this.fileSize,
    this.createdAt,
    this.updatedAt,
    this.isFavorite = false,
    this.isDownloaded = false,
    this.localPath,
    this.itemRef,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? artistId,
    String? album,
    String? albumId,
    int? duration,
    int? trackNumber,
    int? discNumber,
    int? year,
    String? genre,
    String? coverUrl,
    String? streamUrl,
    String? artworkUrl,
    int? bitrate,
    int? sampleRate,
    String? codec,
    bool? lossless,
    int? fileSize,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    bool? isDownloaded,
    String? localPath,
    String? itemRef,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      artistId: artistId ?? this.artistId,
      album: album ?? this.album,
      albumId: albumId ?? this.albumId,
      duration: duration ?? this.duration,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      coverUrl: coverUrl ?? this.coverUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      bitrate: bitrate ?? this.bitrate,
      sampleRate: sampleRate ?? this.sampleRate,
      codec: codec ?? this.codec,
      lossless: lossless ?? this.lossless,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      localPath: localPath ?? this.localPath,
      itemRef: itemRef ?? this.itemRef,
    );
  }

  Duration get durationDuration => Duration(seconds: duration ?? 0);

  String get displayArtist => artist ?? 'Unknown Artist';
  String get displayAlbum => album ?? 'Unknown Album';

  /// Effective artwork: coverUrl > artworkUrl
  String? get effectiveArtwork => coverUrl ?? artworkUrl;

  /// Quality badge e.g., FLAC 96kHz Lossless
  String? get qualityBadge {
    if (codec == null && lossless == null) return null;
    final parts = <String>[];
    if (codec != null) parts.add(codec!.toUpperCase());
    if (lossless == true) parts.add('Lossless');
    if (sampleRate != null && sampleRate! >= 48000) parts.add('Hi-Res');
    return parts.isEmpty ? null : parts.join(' • ');
  }
}
