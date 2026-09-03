import 'package:flutter_test/flutter_test.dart';

import 'package:nexora_flutter/data/api/shares_api.dart';
import 'package:nexora_flutter/data/api/tags_api.dart';
import 'package:nexora_flutter/domain/entities/playlist.dart';

void main() {
  group('ShareLink.fromJson', () {
    test('parses create/list shape', () {
      final s = ShareLink.fromJson({
        'id': 'sh_1',
        'token': 'tok',
        'url': 'https://srv/s/tok',
        'root_id': 'root1',
        'path': 'Music/a.flac',
        'name': 'a.flac',
        'scope': 'preview',
        'has_password': false,
        'max_downloads': 0,
        'download_count': 3,
        'created_at': '2026-01-01',
      });
      expect(s.id, 'sh_1');
      expect(s.url, 'https://srv/s/tok');
      expect(s.scope, 'preview');
      expect(s.downloadCount, 3);
    });
  });

  group('NexoraTag.fromJson', () {
    test('parses with color + count, tolerates strings', () {
      final t = NexoraTag.fromJson({
        'id': 'tag_1',
        'name': 'Workout',
        'color': '#ef4444',
        'created_at': '2026-01-01',
        'count': '7',
      });
      expect(t.name, 'Workout');
      expect(t.count, 7);
      expect(t.color.value, 0xFFEF4444);
    });

    test('bad color falls back to brand', () {
      const t = NexoraTag(
        id: 'x',
        name: 'y',
        colorHex: 'nope',
        createdAt: '',
        count: 0,
      );
      expect(t.color.value, 0xFF6366F1);
    });
  });

  group('PlaylistCollaborator/PlaylistUser', () {
    test('parse list + search shapes', () {
      final c = PlaylistCollaborator.fromJson({
        'playlist_id': 'p1',
        'user_id': 'u2',
        'role': 'editor',
        'created_at': '2026-01-01',
        'username': 'ana',
      });
      expect(c.username, 'ana');
      expect(c.role, 'editor');
      const u = PlaylistUser(id: 'u2', username: 'ana');
      expect(u.id, 'u2');
      final u2 = PlaylistUser.fromJson({'id': 'u3'});
      expect(u2.username, '');
    });
  });
}
