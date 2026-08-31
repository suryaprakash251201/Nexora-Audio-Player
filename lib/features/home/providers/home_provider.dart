import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/songs_repository.dart';
import '../../../data/repositories/history_repository.dart';
import '../../../data/api/albums_api.dart';
import '../../../data/api/artists_api.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/entities/album.dart';
import '../../../domain/entities/artist.dart';
import '../../../domain/entities/playback_history.dart';

final recentSongsProvider = FutureProvider<List<Song>>((ref) async {
  final repo = ref.watch(songsRepositoryProvider);
  final pag = await repo.getSongs(page: 1, limit: 10);
  return pag.data;
});

final recentlyPlayedProvider = FutureProvider<List<PlaybackHistoryItem>>((ref) async {
  final repo = ref.watch(historyRepositoryProvider);
  return repo.getHistory(page: 1, limit: 10);
});

final featuredAlbumsProvider = FutureProvider<List<Album>>((ref) async {
  final api = ref.watch(albumsApiProvider);
  final pag = await api.getAlbums(page: 1, limit: 10);
  return pag.data;
});

final featuredArtistsProvider = FutureProvider<List<Artist>>((ref) async {
  final api = ref.watch(artistsApiProvider);
  final pag = await api.getArtists(page: 1, limit: 10);
  return pag.data;
});
