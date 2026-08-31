class Artist {
  final String id;
  final String name;
  final String? artworkUrl;
  final int? albumCount;
  final int? trackCount;
  final String? bio;

  const Artist({
    required this.id,
    required this.name,
    this.artworkUrl,
    this.albumCount,
    this.trackCount,
    this.bio,
  });
}
