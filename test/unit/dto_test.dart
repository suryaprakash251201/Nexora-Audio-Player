import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_flutter/data/dto/song_dto.dart';
import 'package:nexora_flutter/data/dto/user_dto.dart';
import 'package:nexora_flutter/data/dto/paginated_response_dto.dart';
import 'package:nexora_flutter/domain/entities/song.dart';

void main() {
  group('SongDto', () {
    test('parses minimal', () {
      final dto = SongDto.fromJson({'id': '1', 'title': 'Time'});
      expect(dto.id, '1');
      expect(dto.title, 'Time');
      final entity = dto.toEntity();
      expect(entity.id, '1');
      expect(entity.duration, isNull);
    });

    test('handles missing fields gracefully', () {
      final dto = SongDto.fromJson({});
      expect(dto.title, isNotEmpty);
      expect(dto.id, isNotEmpty);
    });

    test('parses full payload', () {
      final dto = SongDto.fromJson({
        'id': 's1',
        'title': 'Song',
        'artist': 'Artist',
        'duration': 200,
        'codec': 'FLAC',
        'bitrate': 320,
        'sampleRate': 48000,
        'lossless': true,
      });
      final e = dto.toEntity();
      expect(e.codec, 'FLAC');
      expect(e.qualityBadge, contains('Lossless'));
    });
  });

  group('UserDto', () {
    test('parses', () {
      final dto = UserDto.fromJson({'id': 'u1', 'username': 'alex', 'email': 'a@b.com'});
      expect(dto.username, 'alex');
      expect(dto.toEntity().name, 'alex');
    });
  });

  group('PaginatedResponseDto', () {
    test('parses list', () {
      final dto = PaginatedResponseDto.fromJson<Song>(
        [{ 'id': '1', 'title': 'A' }, { 'id': '2', 'title': 'B' }],
        (m) => SongDto.fromJson(m).toEntity(),
      );
      expect(dto.data.length, 2);
    });

    test('parses envelope', () {
      final dto = PaginatedResponseDto.fromJson<Song>(
        {
          'data': [{ 'id': '1', 'title': 'A' }],
          'pagination': {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1, 'hasNext': false, 'hasPrev': false}
        },
        (m) => SongDto.fromJson(m).toEntity(),
      );
      expect(dto.data.length, 1);
      expect(dto.total, 1);
    });
  });
}
