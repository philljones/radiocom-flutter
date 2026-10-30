import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Receives invalidation events over a single long-lived HTTP response.
///
/// This only requests current track data when the API announces a change or
/// when the SSE connection (re)establishes. There is no metadata polling.
class NowPlayingEventStream {
  final http.Client Function() _clientFactory;
  http.Client? _client;
  String? _url;
  void Function()? _onEvent;
  bool _active = false;
  int _generation = 0;

  NowPlayingEventStream({http.Client Function()? clientFactory})
      : _clientFactory = clientFactory ?? http.Client.new;

  void start(Uri url, void Function() onEvent) {
    if (_active && _url == url.toString()) {
      _onEvent = onEvent;
      return;
    }
    stop();
    _active = true;
    _url = url.toString();
    _onEvent = onEvent;
    final generation = ++_generation;
    unawaited(_listen(generation, url));
  }

  void stop() {
    _active = false;
    _generation++;
    _url = null;
    _onEvent = null;
    _client?.close(); // Abort an in-flight SSE request on lifecycle changes.
    _client = null;
  }

  Future<void> _listen(int generation, Uri url) async {
    while (_active && generation == _generation) {
      final client = _clientFactory();
      _client = client;
      try {
        final request = http.Request('GET', url);
        request.headers['Accept'] = 'text/event-stream';
        request.headers['Cache-Control'] = 'no-cache';
        final response = await client.send(request).timeout(
              const Duration(seconds: 15),
            );
        if (response.statusCode != 200) {
          throw StateError('Now Playing SSE returned ${response.statusCode}');
        }
        String event = '';
        await for (final line
            in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
          if (!_active || generation != _generation) break;
          if (line.isEmpty) {
            if (event == 'ready' || event == 'track') {
              try {
                _onEvent?.call();
              } catch (_) {
                // UI errors should not tear down the live event connection.
              }
            }
            event = '';
          } else if (line.startsWith('event:')) {
            event = line.substring(6).trim();
          }
          // data, retry and comment-only keepalive lines need no processing:
          // the existing Radioco-compatible JSON API remains authoritative.
        }
      } catch (_) {
        // A stream failure is isolated from audio playback. Reconnect below.
      } finally {
        client.close();
        if (identical(_client, client)) _client = null;
      }
      if (_active && generation == _generation) {
        // Reconnect backoff only on failure/closure, never a metadata poll.
        await Future<void>.delayed(const Duration(seconds: 3));
      }
    }
  }
}
