import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/songs_repository.dart';
import '../../../data/repositories/history_repository.dart';
import '../../../data/repositories/playlists_repository.dart';
import '../../../data/api/albums_api.dart';
import '../../../data/api/artists_api.dart';
import '../../../data/api/favorites_api.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/entities/album.dart';
import '../../../domain/entities/artist.dart';
import '../../../domain/entities/playlist.dart';
import '../../../domain/entities/playback_history.dart';

/// First page of the library (search index, kind=audio) — feeds Home's
/// Songs rail and Shuffle-all. Same source as Library → Songs, so the
/// two can never disagree.
final recentSongsProvider = FutureProvider<List<Song>>((ref) async {
  final repo = ref.watch(songsRepositoryProvider);
  final pag = await repo.getSongs(page: 1, limit: 12);
  return SongsRepository.deduplicateById(pag.data);
});

/// First playlists for Home's opening rail (capped; full list lives in
/// Library → Playlists and the Playlists tab).
final homePlaylistsProvider = FutureProvider<List<Playlist>>((ref) async {
  final repo = ref.watch(playlistsRepositoryProvider);
  final list = await repo.getPlaylists();
  return list.take(6).toList();
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
