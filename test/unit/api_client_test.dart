import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_flutter/core/config/app_config.dart';

void main() {
  group('AppConfig.normalizeUrl', () {
    test('adds https for domain', () {
      expect(AppConfig.normalizeUrl('music.example.com'), 'https://music.example.com/api/v1');
    });
    test('adds http for IP', () {
      expect(AppConfig.normalizeUrl('192.168.1.5:3000'), 'http://192.168.1.5:3000/api/v1');
    });
    test('handles localhost', () {
      expect(AppConfig.normalizeUrl('localhost:3000'), 'http://localhost:3000/api/v1');
    });
    test('keeps existing api prefix', () {
      expect(AppConfig.normalizeUrl('https://example.com/api/v1'), 'https://example.com/api/v1');
    });
    test('strips trailing slash', () {
      expect(AppConfig.normalizeUrl('https://example.com/'), 'https://example.com/api/v1');
    });
  });
}
