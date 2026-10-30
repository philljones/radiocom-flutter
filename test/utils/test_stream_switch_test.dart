import 'package:cuacfm/utils/test_stream_switch.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('selects the matching Icecast stream URL', () {
    expect(
      TestStreamSwitch.streamUrlFor(false),
      'https://stream.aberradio.com/live.mp3',
    );
    expect(
      TestStreamSwitch.streamUrlFor(true),
      'https://stream-test.aberradio.com/test.mp3',
    );
  });

  const productionNowUrl =
      'https://api.aberradio.com/api/2/radiocom/transmissions/now?format=json&timezone=Europe/London';

  test('live metadata keeps the production URL unchanged', () {
    expect(
        TestStreamSwitch.nowUrlFor(productionNowUrl, false), productionNowUrl);
  });

  test('test metadata uses France and preserves endpoint parameters', () {
    final url = Uri.parse(TestStreamSwitch.nowUrlFor(productionNowUrl, true));
    expect(url.origin, 'https://api-test.aberradio.com');
    expect(url.path, '/api/2/radiocom/transmissions/now');
    expect(url.queryParameters, {
      'format': 'json',
      'timezone': 'Europe/London',
      'mount': 'test',
    });
  });

  test('test metadata sets one test mount even without an existing query', () {
    for (final source in [
      'https://api.aberradio.com/api/2/radiocom/transmissions/now',
      '$productionNowUrl&mount=live',
    ]) {
      final url = Uri.parse(TestStreamSwitch.nowUrlFor(source, true));
      expect(url.queryParametersAll['mount'], ['test']);
    }
  });

  test('audio and metadata selection persists and switches back together',
      () async {
    SharedPreferences.setMockInitialValues({});
    await TestStreamSwitch.initialize();
    await TestStreamSwitch.setUsingTestStream(true);
    await TestStreamSwitch.initialize();
    expect(await TestStreamSwitch.isUsingTestStream(), testStreamSwitchEnabled);
    expect(
      await TestStreamSwitch.resolveStreamUrl('https://example.com/live.mp3'),
      testStreamSwitchEnabled
          ? 'https://stream-test.aberradio.com/test.mp3'
          : 'https://example.com/live.mp3',
    );
    final selected =
        Uri.parse(await TestStreamSwitch.resolveNowUrl(productionNowUrl));
    expect(
        selected.host,
        testStreamSwitchEnabled
            ? 'api-test.aberradio.com'
            : 'api.aberradio.com');
    expect(selected.queryParameters['mount'],
        testStreamSwitchEnabled ? 'test' : null);

    await TestStreamSwitch.setUsingTestStream(false);
    expect(await TestStreamSwitch.resolveNowUrl(productionNowUrl),
        productionNowUrl);
    expect(
        await TestStreamSwitch.resolveStreamUrl('https://example.com/live.mp3'),
        testStreamSwitchEnabled
            ? 'https://stream.aberradio.com/live.mp3'
            : 'https://example.com/live.mp3');
  });

  test('the current selection overrides a later production URL refresh',
      () async {
    SharedPreferences.setMockInitialValues({});
    await TestStreamSwitch.initialize();
    await TestStreamSwitch.setUsingTestStream(true);

    expect(
      TestStreamSwitch.resolveCurrentStreamUrl('https://example.com/live.mp3'),
      testStreamSwitchEnabled
          ? TestStreamSwitch.testStreamUrl
          : 'https://example.com/live.mp3',
    );

    await TestStreamSwitch.setUsingTestStream(false);
  });
}
