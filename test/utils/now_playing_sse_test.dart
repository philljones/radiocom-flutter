import 'dart:async';
import 'dart:convert';

import 'package:cuacfm/utils/now_playing_sse.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _FakeSseClient extends http.BaseClient {
  final List<Uri> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request.url);
    expect(request.headers['Accept'], 'text/event-stream');
    final payload = [
      'retry: 3000\nevent: ready\ndata: {"revision":0}\n\n',
      ': keepalive\n\n',
      'event: tr',
      'ack\ndata: {"revision":1}\n\n',
    ];
    return http.StreamedResponse(
      Stream<List<int>>.fromIterable(payload.map(utf8.encode)),
      200,
      headers: {'content-type': 'text/event-stream'},
    );
  }
}

void main() {
  test('reconnect snapshot and track events notify without a polling timer', () async {
    final client = _FakeSseClient();
    final seen = Completer<void>();
    int notifications = 0;
    final stream = NowPlayingEventStream(clientFactory: () => client);
    final endpoint = Uri.parse(
      'https://api.aberradio.com/api/2/radiocom/transmissions/now/events',
    );

    stream.start(endpoint, () {
      notifications++;
      if (notifications == 2 && !seen.isCompleted) seen.complete();
    });

    await seen.future.timeout(const Duration(seconds: 2));
    stream.stop();

    expect(notifications, 2);
    expect(client.requests, [endpoint]);
  });
}
