import 'package:cuacfm/utils/test_stream_switch.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('event source uses London live or France test', () {
    expect(TestStreamSwitch.nowEventsUrlFor(false).toString(),
        'https://api.aberradio.com/api/2/radiocom/transmissions/now/events');
    expect(TestStreamSwitch.nowEventsUrlFor(true).toString(),
        'https://api-test.aberradio.com/api/2/radiocom/transmissions/now/events?mount=test');
  });

  test('saved test choice and changes select the event source immediately',
      () async {
    SharedPreferences.setMockInitialValues({'use_test_stream': true});
    await TestStreamSwitch.initialize();
    expect(
        TestStreamSwitch.nowEventsUrl.host,
        testStreamSwitchEnabled
            ? 'api-test.aberradio.com'
            : 'api.aberradio.com');
    await TestStreamSwitch.setUsingTestStream(false);
    final revision = TestStreamSwitch.selectionRevision;
    final observed = <Uri>[];
    void listener() => observed.add(TestStreamSwitch.nowEventsUrl);
    TestStreamSwitch.addListener(listener);
    try {
      await TestStreamSwitch.setUsingTestStream(true);
      await TestStreamSwitch.setUsingTestStream(true); // no duplicate event
      await TestStreamSwitch.setUsingTestStream(false);
      expect(
          observed,
          testStreamSwitchEnabled
              ? [
                  TestStreamSwitch.nowEventsUrlFor(true),
                  TestStreamSwitch.nowEventsUrlFor(false)
                ]
              : isEmpty);
      expect(TestStreamSwitch.selectionRevision,
          revision + (testStreamSwitchEnabled ? 2 : 0));
    } finally {
      TestStreamSwitch.removeListener(listener);
    }
  });
}
