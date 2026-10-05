import 'package:cuacfm/utils/test_stream_switch.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('selects the matching Icecast stream URL', () {
    expect(
      TestStreamSwitch.streamUrlFor(false),
      TestStreamSwitch.liveStreamUrl,
    );
    expect(
      TestStreamSwitch.streamUrlFor(true),
      TestStreamSwitch.testStreamUrl,
    );
  });

  test('adds the test metadata mount only for the test stream', () {
    const endpoint =
        'radiocom/transmissions/now?format=json&timezone=Europe/London';
    expect(TestStreamSwitch.nowEndpointFor(endpoint, false), endpoint);
    expect(
      TestStreamSwitch.nowEndpointFor(endpoint, true),
      '$endpoint&mount=test',
    );
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
