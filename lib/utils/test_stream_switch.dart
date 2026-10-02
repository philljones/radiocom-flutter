import 'package:shared_preferences/shared_preferences.dart';

const bool testStreamSwitchEnabled = bool.fromEnvironment(
  'ABER_TEST_STREAM_SWITCH',
  defaultValue: false,
);

class TestStreamSwitch {
  static const String liveStreamUrl = 'https://stream.aberradio.com/live.mp3';
  static const String testStreamUrl = 'https://stream.aberradio.com/test.mp3';
  static const String _preferenceKey = 'use_test_stream';

  static String streamUrlFor(bool useTestStream) =>
      useTestStream ? testStreamUrl : liveStreamUrl;

  static String nowEndpointFor(String endpoint, bool useTestStream) =>
      useTestStream ? '$endpoint&mount=test' : endpoint;

  static Future<bool> isUsingTestStream() async {
    if (!testStreamSwitchEnabled) return false;
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_preferenceKey) ?? false;
  }

  static Future<void> setUsingTestStream(bool value) async {
    if (!testStreamSwitchEnabled) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_preferenceKey, value);
  }

  static Future<String> resolveStreamUrl(String productionUrl) async {
    if (!testStreamSwitchEnabled) return productionUrl;
    return streamUrlFor(await isUsingTestStream());
  }

  static Future<String> resolveNowEndpoint(String endpoint) async {
    if (!testStreamSwitchEnabled) return endpoint;
    return nowEndpointFor(endpoint, await isUsingTestStream());
  }
}
