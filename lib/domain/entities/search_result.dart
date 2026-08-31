import 'song.dart';
import 'album.dart';
import 'artist.dart';
import 'playlist.dart';

class SearchResult {
  final String query;
  final List<Song> songs;
  final List<Album> albums;
  final List<Artist> artists;
  final List<Playlist> playlists;

  const SearchResult({
    required this.query,
    this.songs = const [],
    this.albums = const [],
    this.artists = const [],
    this.playlists = const [],
  });

  bool get isEmpty => songs.isEmpty && albums.isEmpty && artists.isEmpty && playlists.isEmpty;
  bool get isNotEmpty => !isEmpty;
}
