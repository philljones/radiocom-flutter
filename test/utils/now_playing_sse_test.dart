import 'dart:async';
import 'dart:convert';

import 'package:cuacfm/utils/now_playing_sse.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _FakeSseClient extends http.BaseClient {
  final requests = <Uri>[];
  Map<String, String>? headers;
  late final body = StreamController<List<int>>(onCancel: () {
    cancelled = true;
  });
  bool cancelled = false;
  bool closed = false;
  int status = 200;
  String contentType = 'text/event-stream; charset=utf-8';
  Completer<http.StreamedResponse>? pending;

  http.StreamedResponse get response =>
      http.StreamedResponse(body.stream, status,
          headers: {'content-type': contentType});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request.url);
    headers = Map.of(request.headers);
    return pending == null ? response : pending!.future;
  }

  void emit(String text) => body.add(utf8.encode(text));
  @override
  void close() {
    closed = true;
  }
}

final london = Uri.parse(
    'https://api.aberradio.com/api/2/radiocom/transmissions/now/events');
final france = Uri.parse(
    'https://api-test.aberradio.com/api/2/radiocom/transmissions/now/events?mount=test');

void main() {
  testWidgets(
      'fragmented events notify; comments and unknown/incomplete events do not',
      (tester) async {
    final client = _FakeSseClient();
    var notifications = 0;
    final stream = NowPlayingEventStream(clientFactory: () => client);
    addTearDown(stream.stop);
    stream.start(london, () {
      notifications++;
    });
    await tester.pump();
    client.emit('retry: 3000\r\nevent: ready\r\ndata: {"revision":0}\r\n\r\n');
    client.emit(': keepalive\n\nevent: tr');
    client.emit('ack\ndata: {"revision":1}\n\n');
    client.emit('event: unknown\ndata: {}\n\nevent: track\n\n');
    client.emit('event: track\ndata: {}'); // no final blank line
    await tester.pump();
    expect(notifications, 2);
    expect(client.headers!['Accept'], 'text/event-stream');
    expect(client.headers!['Cache-Control'], 'no-cache');
    expect(client.requests, [london]);
    stream.stop();
    await tester.pump();
    expect(client.closed, isTrue);
    expect(client.cancelled, isTrue);
  });

  testWidgets('same URL reuses one connection and the latest callback',
      (tester) async {
    final client = _FakeSseClient();
    var oldCalls = 0;
    var newCalls = 0;
    final stream = NowPlayingEventStream(clientFactory: () => client);
    addTearDown(stream.stop);
    stream.start(london, () {
      oldCalls++;
    });
    stream.start(london, () {
      newCalls++;
    });
    await tester.pump();
    client.emit('event: ready\ndata: {}\n\n');
    await tester.pump();
    expect(oldCalls, 0);
    expect(newCalls, 1);
    expect(client.requests, [london]);
    stream.stop();
    await tester.pump();
  });

  testWidgets('switch cancels London and ignores its delayed response',
      (tester) async {
    final old = _FakeSseClient()..pending = Completer<http.StreamedResponse>();
    final next = _FakeSseClient();
    final clients = [old, next];
    var count = 0;
    var notifications = 0;
    final stream = NowPlayingEventStream(clientFactory: () => clients[count++]);
    addTearDown(stream.stop);
    stream.start(london, () {
      notifications++;
    });
    stream.start(france, () {
      notifications++;
    });
    await tester.pump();
    old.pending!.complete(old.response);
    old.emit('event: track\ndata: {}\n\n');
    next.emit('event: ready\ndata: {}\n\n');
    await tester.pump();
    expect(notifications, 1);
    expect(old.closed, isTrue);
    expect(old.cancelled, isTrue);
    expect(next.requests, [france]);
    stream.stop();
    await tester.pump(const Duration(seconds: 20));
    expect(count, 2);
  });

  test('closed connection retries and ready requests a fresh snapshot',
      () async {
    final first = _FakeSseClient();
    final second = _FakeSseClient();
    final reconnected = Completer<void>();
    final received = Completer<void>();
    var clients = 0;
    var notifications = 0;
    final stream = NowPlayingEventStream(
      retryDelay: const Duration(milliseconds: 10),
      clientFactory: () {
        if (++clients == 1) return first;
        reconnected.complete();
        return second;
      },
    );
    addTearDown(stream.stop);
    stream.start(france, () {
      if (++notifications == 2) received.complete();
    });
    first.emit('event: ready\ndata: {}\n\n');
    await first.body.close();
    await reconnected.future.timeout(const Duration(seconds: 2));
    second.emit('event: ready\ndata: {}\n\n');
    await received.future.timeout(const Duration(seconds: 2));
    expect(clients, 2);
    expect(first.requests, [france]);
    expect(second.requests, [france]);
    expect(first.closed, isTrue);
    stream.stop();
  });

  for (final invalid in ['status', 'content-type']) {
    testWidgets('rejects invalid $invalid and cancels retry on stop',
        (tester) async {
      final client = _FakeSseClient();
      if (invalid == 'status') client.status = 503;
      if (invalid == 'content-type') client.contentType = 'text/html';
      var count = 0;
      final stream = NowPlayingEventStream(clientFactory: () {
        count++;
        return client;
      });
      addTearDown(stream.stop);
      stream.start(london, () {
        fail('invalid response notified');
      });
      await tester.pump();
      expect(client.cancelled, isTrue);
      stream.stop();
      await tester.pump(const Duration(seconds: 10));
      expect(count, 1);
    });
  }

  testWidgets('keepalives prevent idle reconnection', (tester) async {
    final clients = <_FakeSseClient>[];
    final stream = NowPlayingEventStream(clientFactory: () {
      final client = _FakeSseClient();
      clients.add(client);
      return client;
    });
    addTearDown(stream.stop);
    stream.start(london, () {});
    await tester.pump();
    await tester.pump(const Duration(seconds: 30));
    clients.first.emit(': keepalive\n\n');
    await tester.pump();
    await tester.pump(const Duration(seconds: 30));
    expect(clients.length, 1);
    stream.stop();
    await tester.pump();
  });

  test('silently stalled socket is cancelled and reconnected', () async {
    final first = _FakeSseClient();
    final second = _FakeSseClient();
    final reconnected = Completer<void>();
    var clients = 0;
    final stream = NowPlayingEventStream(
      idleTimeout: const Duration(milliseconds: 30),
      retryDelay: Duration.zero,
      clientFactory: () {
        if (++clients == 1) return first;
        reconnected.complete();
        return second;
      },
    );
    addTearDown(stream.stop);
    stream.start(london, () {});
    await reconnected.future.timeout(const Duration(seconds: 2));
    stream.stop();
    expect(first.cancelled, isTrue);
    expect(first.closed, isTrue);
    expect(clients, 2);
  });

  testWidgets('foreground and background live transitions stop and restart',
      (tester) async {
    final clients = <_FakeSseClient>[];
    final stream = NowPlayingEventStream(clientFactory: () {
      final client = _FakeSseClient();
      clients.add(client);
      return client;
    });
    addTearDown(stream.stop);
    void sync(bool foreground, bool live) => stream.sync(
        url: london,
        isForeground: foreground,
        isLivePlaying: live,
        onEvent: () {});
    sync(true, false);
    await tester.pump();
    sync(false, true);
    await tester.pump();
    expect(clients.length, 1); // background live continues
    sync(false, false); // paused or podcast: no background live metadata socket
    await tester.pump();
    expect(clients.first.closed, isTrue);
    sync(false, true); // live playback resumes while still backgrounded
    await tester.pump();
    expect(clients.length, 2);
    sync(true, false);
    await tester.pump();
    expect(clients.length, 2);
    stream.stop();
    await tester.pump();
  });
}
