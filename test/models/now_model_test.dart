import 'package:cuacfm/injector/dependency_injector.dart';
import 'package:cuacfm/models/now.dart';
import 'package:cuacfm/models/radiostation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injector/injector.dart';

import '../instrument/model/radio_station_instrument.dart';

void main() {
  setUpAll(() {
    WidgetsFlutterBinding.ensureInitialized();
    DependencyInjector().loadModules();
    Injector.appInstance.registerDependency<RadioStation>(
        () => RadioStationInstrument.givenARadioStation(),
        override: true);
  });

  group('Now.mock', () {
    test('that creates a mock Now with expected values', () {
      final now = Now.mock();
      expect(now.name, equals('Aber Radio Live'));
      expect(now.logoUrl, isNotEmpty);
      expect(now.programmeUrl, equals('https://aberradio.com'));
      expect(now.rssUrl, equals('https://aberradio.com'));
      expect(now.description, equals(''));
    });
  });

  group('Now.fromInstance', () {
    test('that parses all fields from map', () {
      final map = {
        'name': 'Morning Show',
        'description': 'A great morning show',
        'programme_url': 'https://cuacfm.org/morning',
        'logo_url': 'https://cuacfm.org/logo.jpg',
        'rss_url': 'https://cuacfm.org/feed.rss',
      };

      final now = Now.fromInstance(map);

      expect(now.name, equals('Aber Radio Live'));
      expect(now.description, equals('A great morning show'));
      expect(now.programmeUrl, equals('https://aberradio.com'));
      expect(now.logoUrl, equals('assets/graphics/aber-radio-logo.png'));
      expect(now.rssUrl, equals('https://cuacfm.org/feed.rss'));
    });
  });

  group('Now.streamUrl', () {
    test('that returns the stream url from injected radio station', () {
      final now = Now.mock();
      final url = now.streamUrl();
      expect(url, equals('https://stream.aberradio.com/test.mp3'));
    });
  });
}
