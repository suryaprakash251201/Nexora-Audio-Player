import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/songs_repository.dart';
import '../../../data/repositories/history_repository.dart';
import '../../../data/api/albums_api.dart';
import '../../../data/api/artists_api.dart';
import '../../../data/api/favorites_api.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/entities/album.dart';
import '../../../domain/entities/artist.dart';
import '../../../domain/entities/playback_history.dart';

/// Library listing (search index, kind=audio) — first page for Home.
final recentSongsProvider = FutureProvider<List<Song>>((ref) async {
  final repo = ref.watch(songsRepositoryProvider);
  final pag = await repo.getSongs(page: 1, limit: 10);
  return pag.data;
});

/// Server-tracked recents (auto-recorded when a track is streamed).
final recentlyPlayedProvider = FutureProvider<List<PlaybackHistoryItem>>((
  ref,
) async {
  final repo = ref.watch(historyRepositoryProvider);
  return repo.getHistory(page: 1, limit: 10);
});

/// Server favorites.
final favoritesProvider = FutureProvider<List<Song>>((ref) async {
  final repo = ref.watch(favoritesApiProvider);
  return repo.getFavorites();
});

/// Albums = directories under the Music root.
final featuredAlbumsProvider = FutureProvider<List<Album>>((ref) async {
  final api = ref.watch(albumsApiProvider);
  return api.getAlbums(limit: 20);
});

/// Artists = directory groupings under the Music root.
final featuredArtistsProvider = FutureProvider<List<Artist>>((ref) async {
  final api = ref.watch(artistsApiProvider);
  return api.getArtists(limit: 20);
});
