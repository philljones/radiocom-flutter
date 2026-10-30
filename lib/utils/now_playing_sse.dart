import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// One reconnecting metadata invalidation connection, independent of audio.
class NowPlayingEventStream {
  final http.Client Function() _clientFactory;
  final Duration retryDelay;
  final Duration idleTimeout;
  http.Client? _client;
  StreamIterator<String>? _lines;
  Timer? _retryTimer;
  Completer<void>? _retryDone;
  Uri? _url;
  void Function()? _onEvent;
  bool _active = false;
  int _generation = 0;

  NowPlayingEventStream({
    http.Client Function()? clientFactory,
    this.retryDelay = const Duration(seconds: 3),
    this.idleTimeout = const Duration(seconds: 45),
  }) : _clientFactory = clientFactory ?? http.Client.new;

  /// Keep background updates only while live audio is actually playing.
  void sync({
    required Uri url,
    required bool isForeground,
    required bool isLivePlaying,
    required void Function() onEvent,
  }) {
    if (isForeground || isLivePlaying) {
      start(url, onEvent);
    } else {
      stop();
    }
  }

  void start(Uri url, void Function() onEvent) {
    if (_active && _url == url) {
      _onEvent = onEvent;
      return;
    }
    stop();
    _active = true;
    _url = url;
    _onEvent = onEvent;
    unawaited(_listen(_generation, url));
  }

  void stop() {
    _active = false;
    _generation++;
    _url = null;
    _onEvent = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    final retryDone = _retryDone;
    _retryDone = null;
    if (retryDone != null && !retryDone.isCompleted) retryDone.complete();
    final lines = _lines;
    _lines = null;
    if (lines != null) unawaited(lines.cancel());
    _client?.close();
    _client = null;
  }

  bool _isCurrent(int generation) => _active && generation == _generation;

  Future<void> _listen(int generation, Uri url) async {
    while (_isCurrent(generation)) {
      http.Client? client;
      StreamIterator<String>? lines;
      try {
        client = _clientFactory();
        _client = client;
        final request = http.Request('GET', url);
        request.headers['Accept'] = 'text/event-stream';
        request.headers['Cache-Control'] = 'no-cache';
        final response = await client.send(request).timeout(
              const Duration(seconds: 15),
            );
        if (!_isCurrent(generation)) {
          await response.stream.listen(null).cancel();
          return;
        }
        final contentType = response.headers['content-type']
            ?.split(';')
            .first
            .trim()
            .toLowerCase();
        if (response.statusCode != 200 || contentType != 'text/event-stream') {
          await response.stream.listen(null).cancel();
          throw StateError('Invalid Now Playing SSE response');
        }
        // The API emits comment keepalives. Recover a silently stalled socket.
        lines = StreamIterator(response.stream
            .timeout(idleTimeout)
            .transform(utf8.decoder)
            .transform(const LineSplitter()));
        _lines = lines;
        String event = '';
        bool hasData = false;
        while (await lines.moveNext()) {
          if (!_isCurrent(generation)) break;
          final line = lines.current;
          if (line.isEmpty) {
            if (hasData && (event == 'ready' || event == 'track')) {
              try {
                _onEvent?.call();
              } catch (_) {
                // UI errors must not affect audio or the event connection.
              }
            }
            event = '';
            hasData = false;
          } else if (!line.startsWith(':')) {
            final colon = line.indexOf(':');
            final field = colon < 0 ? line : line.substring(0, colon);
            var value = colon < 0 ? '' : line.substring(colon + 1);
            if (value.startsWith(' ')) value = value.substring(1);
            if (field == 'event') event = value;
            if (field == 'data') hasData = true;
          }
        }
      } catch (_) {
        // Metadata failures never interrupt playback. A new ready event will
        // request an authoritative snapshot when the connection recovers.
      } finally {
        if (lines != null) unawaited(lines.cancel());
        if (identical(_lines, lines)) _lines = null;
        client?.close();
        if (identical(_client, client)) _client = null;
      }
      if (_isCurrent(generation)) {
        final done = Completer<void>();
        _retryDone = done;
        _retryTimer = Timer(retryDelay, done.complete);
        await done.future;
        if (identical(_retryDone, done)) {
          _retryDone = null;
          _retryTimer = null;
        }
      }
    }
  }
}
