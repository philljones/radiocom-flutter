import 'package:cuacfm/models/radiostation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RadioStation.base', () {
    test('that creates base station with expected values', () {
      final station = RadioStation.base();
      expect(station.stationName, equals('Aber Radio'));
      expect(station.streamUrl, isEmpty);
      expect(station.latitude, closeTo(51.8254, 0.01));
      expect(station.longitude, closeTo(-3.0194, 0.01));
      expect(station.stationPhotos, isNotEmpty);
      expect(station.facebookUrl, isNotEmpty);
      expect(station.blueskyUrl, isNotEmpty);
    });
  });

  group('RadioStation.fromInstance', () {
    test('that parses all fields from map', () {
      final map = {
        'station_name': 'Test FM',
        'icon_url': 'http://icon.jpg',
        'big_icon_url': 'http://big-icon.jpg',
        'station_photos': ['http://photo1.jpg', 'http://photo2.jpg'],
        'history': '<p>Our history</p>',
        'latitude': 40.0,
        'longitude': -3.0,
        'news_rss': 'http://news.rss',
        'stream_url': 'http://stream.mp3',
        'facebook_url': 'http://facebook.com/test',
        'twitter_url': 'http://bsky.app/test',
      };

      final station = RadioStation.fromInstance(map);

      expect(station.stationName, equals('Test FM'));
      expect(station.iconUrl, equals('http://icon.jpg'));
      expect(station.bigIconUrl, equals('http://big-icon.jpg'));
      expect(station.stationPhotos, hasLength(2));
      expect(station.history, contains('history'));
      expect(station.latitude, equals(40.0));
      expect(station.longitude, equals(-3.0));
      expect(station.newsRss, equals('http://news.rss'));
      expect(station.streamUrl, equals('http://stream.mp3'));
      expect(station.facebookUrl, equals('http://facebook.com/test'));
      expect(station.blueskyUrl, equals('http://bsky.app/test'));
    });

    test('that leaves the stream empty when the API omits stream_url', () {
      final station = RadioStation.fromInstance({
        'station_photos': [],
        'history': '',
        'latitude': 51.8247,
        'longitude': -3.0196,
        'news_rss': '',
        'facebook_url': '',
        'twitter_url': '',
      });

      expect(station.streamUrl, isEmpty);
    });
  });
}
