import 'package:cuacfm/utils/test_stream_switch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
