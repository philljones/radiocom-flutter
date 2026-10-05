import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cuacfm/domain/invoker/invoker.dart';
import 'package:cuacfm/domain/result/result.dart';
import 'package:cuacfm/domain/usecase/end_session_use_case.dart';
import 'package:cuacfm/domain/usecase/get_playlist_use_case.dart';
import 'package:cuacfm/domain/usecase/remove_from_playlist_use_case.dart';
import 'package:cuacfm/domain/usecase/start_session_use_case.dart';
import 'package:cuacfm/models/episode.dart';
import 'package:cuacfm/models/now.dart';
import 'package:cuacfm/utils/test_stream_switch.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/services.dart';
import 'package:audio_service/audio_service.dart';
import 'package:cuacfm/ui/player/cuac_audio_handler.dart';
import 'package:injector/injector.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

typedef void ConnectionCallback(bool isError);

enum AudioPlayerState { play, stop, pause }

abstract class CurrentPlayerContract {
  Now? get now;
  set now(Now? value);
  Episode? episode;
  Episode? tempEpisode;
  AudioPlayerState playerState = AudioPlayerState.stop;
  AudioPlayer audioPlayer = Injector.appInstance.get<AudioPlayer>();
  String currentSong = ":";
  String currentSubtitle = "";
  String currentImage = "https://aberradio.com/fb_cover_photo.png";
  bool isPodcast = false;
  String playbackSource = 'app';
  Duration duration = Duration(seconds: 0);
  Duration position = Duration(seconds: 0);
  Duration restoreDuration = Duration(seconds: 0);
  Duration restorePosition = Duration(seconds: 0);
  double volume = 1.0;
  double playbackRate = 1.0;
  VoidCallback? onUpdate;
  ConnectionCallback? onConnection;
  ConnectionCallback? podcastConnectivityResult;
  ConnectivityResult? connectivityResult;

  void restorePlayer(ConnectivityResult connection);
  Future<bool> seek(Duration position);
  Future<bool> setVolume(double volume);
  Future<bool> play();
  Future<bool> restartLiveStream();
  Future<bool> stopAndPlay();
  Future<void> fadeOutAndStop(
      {Duration duration = const Duration(seconds: 15)});
  void stop();
  Future resume();
  Future pause();
  bool isPlaying();
  bool isBuffering();
  bool isStreamingAudio();
  bool isPaused();
  void release();
  double getPlaybackRate();
  void setPlaybackRate(double playbackRate);
}

class CurrentPlayer implements CurrentPlayerContract {
  Now? _now;
  @override
  Now? get now => _now;
  @override
  set now(Now? value) {
    _now = value;
    _refreshNotificationMetadata();
  }

  @override
  Episode? episode;
  @override
  Episode? tempEpisode;
  @override
  AudioPlayerState playerState = AudioPlayerState.stop;
  @override
  AudioPlayer audioPlayer = Injector.appInstance.get<AudioPlayer>();
  String _currentSong = ":";
  @override
  String get currentSong => _currentSong;
  @override
  set currentSong(String value) {
    if (_currentSong == value) return;
    _currentSong = value;
    _refreshNotificationMetadata();
  }

  @override
  String currentSubtitle = "";

  String _currentImage = "https://aberradio.com/fb_cover_photo.png";
  @override
  String get currentImage => _currentImage;
  @override
  set currentImage(String value) {
    if (_currentImage == value) return;
    _currentImage = value;
    _refreshNotificationMetadata();
  }

  static const _fallbackArtUrl = "https://aberradio.com/fb_cover_photo.png";
  Uri get _artUri {
    final img = currentImage;
    if (img.startsWith('assets/') ||
        img.contains('default-programme-photo') ||
        img.isEmpty) {
      return Uri.parse(_fallbackArtUrl);
    }
    return Uri.parse(img);
  }

  CuacAudioHandler? get _handler {
    try {
      return Injector.appInstance.get<CuacAudioHandler>();
    } catch (_) {
      return null;
    }
  }

  MediaItem _buildMediaItem() {
    final name = currentSong.trim();
    final hasName = name.isNotEmpty && name != ":";
    final liveTrackTitle = now?.trackTitle.trim() ?? "";
    final liveTrackArtist = now?.trackArtist.trim() ?? "";
    return MediaItem(
      id: urlToHashId(
          isPodcast ? episode?.audio ?? "" : now?.streamUrl() ?? ""),
      album: isPodcast ? "Aber Radio Podcast" : "Aber Radio",
      title: isPodcast
          ? episode?.title ?? ""
          : (liveTrackTitle.isNotEmpty
              ? liveTrackTitle
              : (hasName ? name : "Aber Radio")),
      artist: isPodcast && hasName
          ? name
          : liveTrackTitle.isNotEmpty
              ? (liveTrackArtist.isNotEmpty
                  ? liveTrackArtist
                  : (hasName ? name : "Aber Radio"))
              : "Aber Radio",
      artUri: _artUri,
    );
  }

  final Map<String, Uri> _squareArtCache = {};
  int _artToken = 0;

  void _publishNowPlaying() {
    final item = _buildMediaItem();
    final src = item.artUri;
    final cached = src == null ? null : _squareArtCache[src.toString()];
    _handler?.setNowPlaying(
        cached != null ? item.copyWith(artUri: cached) : item,
        isLive: !isPodcast);
    final token = ++_artToken;
    if (src != null && cached == null) {
      _squareArt(src).then((square) {
        if (square != null && square != src && token == _artToken) {
          _handler?.setNowPlaying(item.copyWith(artUri: square),
              isLive: !isPodcast);
        }
      });
    }
  }

  Future<Uri?> _squareArt(Uri src) async {
    final key = src.toString();
    if (_squareArtCache.containsKey(key)) return _squareArtCache[key];
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/art_${md5.convert(utf8.encode(key)).toString()}.png');
      if (await file.exists()) {
        final uri = Uri.file(file.path);
        _squareArtCache[key] = uri;
        return uri;
      }
      final response = await http.get(src);
      if (response.statusCode != 200) return null;
      final codec = await ui.instantiateImageCodec(response.bodyBytes);
      final image = (await codec.getNextFrame()).image;
      if (image.width == image.height) {
        _squareArtCache[key] = src;
        return src;
      }
      final side = math.min(image.width, image.height);
      final dx = ((image.width - side) / 2).toDouble();
      final dy = ((image.height - side) / 2).toDouble();
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawImageRect(
        image,
        ui.Rect.fromLTWH(dx, dy, side.toDouble(), side.toDouble()),
        ui.Rect.fromLTWH(0, 0, side.toDouble(), side.toDouble()),
        ui.Paint(),
      );
      final out = await recorder.endRecording().toImage(side, side);
      final data = await out.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return null;
      await file.writeAsBytes(data.buffer.asUint8List());
      final uri = Uri.file(file.path);
      _squareArtCache[key] = uri;
      return uri;
    } catch (_) {
      return null;
    }
  }

  void _startWrappedSession() {
    Injector.appInstance
        .get<Invoker>()
        .execute(Injector.appInstance
            .get<StartSessionUseCase>()
            .withParams(StartSessionParams(
              isPodcast: isPodcast,
              programName: isPodcast
                  ? (currentSong.isNotEmpty
                      ? currentSong
                      : episode?.title ?? '')
                  : '',
              category: '',
              episodeTitle: isPodcast ? episode?.title ?? '' : '',
              episodeId: isPodcast ? episode?.audio ?? '' : '',
            )))
        .drain();
  }

  void _endWrappedSession() {
    Injector.appInstance
        .get<Invoker>()
        .execute(Injector.appInstance.get<EndSessionUseCase>())
        .drain();
  }

  void _logPlay() {
    if (isPodcast) {
      final program = currentSong.trim();
      FirebaseAnalytics.instance.logEvent(
        name: 'podcast_play',
        parameters: {
          'program': program.isNotEmpty && program != ':'
              ? program
              : (episode?.title ?? ''),
          'episode': episode?.title ?? '',
          'source': playbackSource,
        },
      );
    } else {
      final live = currentSong.trim();
      FirebaseAnalytics.instance.logEvent(
        name: 'live_play',
        parameters: {
          'program': live.isNotEmpty && live != ':' ? live : 'Aber Radio',
          'source': playbackSource,
        },
      );
    }
  }

  void _refreshNotificationMetadata() {
    if (playerState == AudioPlayerState.stop) return;
    _publishNowPlaying();
  }

  @override
  bool isPodcast = false;
  @override
  String playbackSource = 'app';
  @override
  Duration duration = Duration(seconds: 0);
  @override
  Duration position = Duration(seconds: 0);
  @override
  Duration restoreDuration = Duration(seconds: 0);
  @override
  Duration restorePosition = Duration(seconds: 0);
  @override
  double volume = 1.0;
  @override
  double playbackRate = 1.0;
  @override
  VoidCallback? onUpdate;
  @override
  ConnectionCallback? onConnection;
  @override
  ConnectionCallback? podcastConnectivityResult;
  @override
  ConnectivityResult? connectivityResult;

  // Internal stream subscriptions — cancelled before re-registering
  StreamSubscription? _stateSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;

  bool _livePlaybackRequested = false;
  bool _livePlaybackStarting = false;
  bool _liveRecoveryInProgress = false;
  int _fadeSequence = 0;

  bool get _isLiveReady =>
      !isPodcast &&
      audioPlayer.playing &&
      audioPlayer.processingState == ProcessingState.ready;

  String get _playbackUrl => isPodcast
      ? (episode?.audio ?? '').trim()
      : TestStreamSwitch.resolveCurrentStreamUrl(
          (now?.streamUrl() ?? '').trim(),
        );

  @override
  void restorePlayer(ConnectivityResult connection) {
    // Brief interruptions are left to the native player. If it remains
    // stalled, the next user Play command creates a fresh live connection.
    connectivityResult = connection;
  }

  @override
  Future<bool> seek(Duration position) async {
    if (playerState == AudioPlayerState.play) {
      if (position <= duration) {
        await audioPlayer.seek(position);
        return true;
      } else {
        await audioPlayer.seek(duration);
        return true;
      }
    } else {
      return false;
    }
  }

  @override
  Future<bool> setVolume(double volume) async {
    if (playerState == AudioPlayerState.play) {
      this.volume = volume;
      await audioPlayer.setVolume(volume);
      return true;
    } else {
      return false;
    }
  }

  Future<void> _playNextInPlaylist() async {
    final invoker = Injector.appInstance.get<Invoker>();
    List<Map<String, dynamic>> items = [];
    await for (final result
        in invoker.execute(Injector.appInstance.get<GetPlaylistUseCase>())) {
      if (result is Success)
        items = List<Map<String, dynamic>>.from(result.data ?? []);
    }
    if (items.isEmpty) return;

    final next = items.first;
    invoker
        .execute(Injector.appInstance
            .get<RemoveFromPlaylistUseCase>()
            .withParams(next['audio'] as String))
        .drain();

    final nextEpisode = Episode.fromMap(next);
    isPodcast = true;
    episode = nextEpisode;
    currentSong = next['programName'] ?? nextEpisode.title;
    currentSubtitle = nextEpisode.title;
    currentImage = next['logoUrl'] ?? currentImage;
    playerState = AudioPlayerState.stop;
    position = Duration.zero;
    duration = Duration.zero;

    if (onUpdate != null) onUpdate!();
    await play();
    if (onUpdate != null) onUpdate!();
  }

  @override
  Future<bool> play() async {
    if (playerState != AudioPlayerState.play) {
      _cancelFade();
      if (!isPodcast) {
        _livePlaybackRequested = true;
        _livePlaybackStarting = true;
        onUpdate?.call();
      }
      // Cancel previous subscriptions to avoid accumulation
      await _stateSubscription?.cancel();
      await _durationSubscription?.cancel();
      await _positionSubscription?.cancel();

      _stateSubscription = audioPlayer.playerStateStream.listen((event) async {
        if (!isPodcast) {
          if (event.playing && event.processingState == ProcessingState.ready) {
            final wasStarting = _livePlaybackStarting;
            _livePlaybackStarting = false;
            if (playerState != AudioPlayerState.play) {
              playerState = AudioPlayerState.play;
              onUpdate?.call();
            } else if (wasStarting) {
              onUpdate?.call();
            }
          } else if (_livePlaybackRequested &&
              playerState == AudioPlayerState.play) {
            // `playing` means playback was requested, even while the live
            // stream is buffering. Expose Play whenever audio is not ready so
            // the user can replace a stalled connection from any control.
            playerState = AudioPlayerState.pause;
            onUpdate?.call();
          }
        }
        if (isPodcast && event.processingState == ProcessingState.completed) {
          await _stop();
          position = Duration.zero;
          restoreDuration = Duration.zero;
          restorePosition = Duration.zero;
          await _playNextInPlaylist();
          if (onUpdate != null) onUpdate!();
        } else if (event.processingState == ProcessingState.idle) {
          if (!isPodcast) {
            if (_livePlaybackRequested &&
                playerState != AudioPlayerState.pause) {
              playerState = AudioPlayerState.pause;
              onUpdate?.call();
            }
          } else {
            playerState = AudioPlayerState.stop;
            isPodcast = false;
            if (onUpdate != null) onUpdate!();
          }
        } else if (event.playing &&
            playerState == AudioPlayerState.pause &&
            (isPodcast || event.processingState == ProcessingState.ready)) {
          playerState = AudioPlayerState.play;
          if (onUpdate != null) onUpdate!();
          if (onConnection != null) onConnection!(false);
        } else if (!event.playing &&
            playerState == AudioPlayerState.play &&
            event.processingState != ProcessingState.completed &&
            (isPodcast || !_livePlaybackRequested)) {
          playerState = AudioPlayerState.pause;
          if (onUpdate != null) onUpdate!();
          if (onConnection != null) onConnection!(false);
        }
      }, onError: (Object e, StackTrace s) {
        if (!isPodcast && _livePlaybackRequested) {
          _livePlaybackStarting = false;
          playerState = AudioPlayerState.pause;
          onUpdate?.call();
        }
      });

      if (isPodcast) {
        _durationSubscription =
            audioPlayer.durationStream.listen((Duration? d) {
          duration = d ?? Duration(hours: 1);
          if (onUpdate != null && duration > Duration.zero) {
            onUpdate!();
          }
        });
      }
      _positionSubscription = audioPlayer.positionStream.listen((Duration p) {
        if (isPodcast) {
          if (p.inSeconds.ceilToDouble() >= 0.0 &&
              p.inSeconds.ceilToDouble() <= duration.inSeconds.ceilToDouble()) {
            position = p;
            if (onUpdate != null) {
              onUpdate!();
            }
          }
        } else {
          position = Duration(seconds: 1);
          duration = Duration(hours: 24);
        }
      });

      // Always start a new item at the app's normal volume. This also repairs
      // an interrupted Auto Off fade whose cleanup did not get to run.
      volume = 1.0;
      await audioPlayer.setVolume(volume);
      final playbackUrl = _playbackUrl;
      if (playbackUrl.isNotEmpty) {
        if (!isPodcast) {
          playbackRate = 1.0;
          audioPlayer.setSpeed(playbackRate);
        }
        AudioSource audioSource = AudioSource.uri(Uri.parse(playbackUrl));
        try {
          await audioPlayer.setAudioSource(audioSource);
          _publishNowPlaying();
          if (isPodcast) {
            await audioPlayer.play();
          } else {
            unawaited(audioPlayer.play());
            _startWrappedSession();
            _logPlay();
          }
          await audioPlayer.seek(position);
        } catch (_) {
          if (!isPodcast) {
            _livePlaybackStarting = false;
            playerState = AudioPlayerState.pause;
            onUpdate?.call();
          }
          return false;
        }
        if (isPodcast && audioPlayer.playing) {
          playerState = AudioPlayerState.play;
          _startWrappedSession();
          _logPlay();
        }
        if (restorePosition != Duration(seconds: 0) &&
            restoreDuration != Duration(seconds: 0) &&
            isPodcast &&
            tempEpisode == episode) {
          duration = restoreDuration;
          tempEpisode = null;
          seek(restorePosition);
        } else {
          restoreDuration = Duration(seconds: 0);
          restorePosition = Duration(seconds: 0);
        }
        return true;
      } else {
        if (!isPodcast) {
          _livePlaybackStarting = false;
          _livePlaybackRequested = false;
          onUpdate?.call();
        }
        return false;
      }
    } else {
      return false;
    }
  }

  @override
  Future<bool> restartLiveStream() async {
    if (isPodcast) return false;
    if (_isLiveReady) return true;
    _cancelFade();
    _livePlaybackRequested = true;
    if (_liveRecoveryInProgress) return false;

    _liveRecoveryInProgress = true;
    try {
      await _stop();
      if (audioPlayer.processingState != ProcessingState.idle) {
        await audioPlayer.stop();
      }
      playerState = AudioPlayerState.stop;
      onUpdate?.call();
      return await play();
    } finally {
      _liveRecoveryInProgress = false;
    }
  }

  @override
  Future<bool> stopAndPlay() async {
    if (playerState == AudioPlayerState.play ||
        playerState == AudioPlayerState.pause) {
      final playbackUrl = _playbackUrl;
      if (playbackUrl.isEmpty) return false;
      _cancelFade();
      _endWrappedSession();
      if (!isPodcast) {
        playbackRate = 1.0;
        audioPlayer.setSpeed(playbackRate);
      }
      await audioPlayer.pause();
      if (!audioPlayer.playing) playerState = AudioPlayerState.pause;
      duration = Duration(seconds: 0);
      position = Duration(seconds: 0);
      // stopAndPlay is also a fresh playback request, so do not inherit a
      // partially faded player volume.
      volume = 1.0;
      await audioPlayer.setVolume(volume);
      AudioSource audioSource = AudioSource.uri(Uri.parse(playbackUrl));
      audioPlayer.setAudioSource(audioSource);
      _publishNowPlaying();
      if (isPodcast) {
        await audioPlayer.play();
      } else {
        unawaited(audioPlayer.play());
      }
      await audioPlayer.seek(position);
      if (audioPlayer.playing) {
        playerState = AudioPlayerState.play;
        _startWrappedSession();
        _logPlay();
      }
      return true;
    } else {
      return false;
    }
  }

  @override
  void stop() {
    _cancelFade();
    _livePlaybackRequested = false;
    _livePlaybackStarting = false;
    _stop();
  }

  @override
  Future<void> fadeOutAndStop(
      {Duration duration = const Duration(seconds: 15)}) async {
    if (playerState != AudioPlayerState.play) {
      stop();
      return;
    }

    final sequence = ++_fadeSequence;
    final startVolume = volume.clamp(0.0, 1.0);
    final steps = (duration.inMilliseconds / 250).ceil().clamp(1, 80);
    final stepDuration = Duration(
      milliseconds: (duration.inMilliseconds / steps).round(),
    );

    for (var step = 1; step <= steps; step++) {
      await Future.delayed(stepDuration);
      if (sequence != _fadeSequence || playerState != AudioPlayerState.play) {
        return;
      }
      volume = startVolume * (1 - step / steps);
      await audioPlayer.setVolume(volume);
    }

    if (sequence == _fadeSequence) {
      await _stop();
      volume = 1.0;
      await audioPlayer.setVolume(volume);
      onUpdate?.call();
    }
  }

  void _cancelFade() {
    _fadeSequence++;
    if (volume != 1.0) {
      volume = 1.0;
      audioPlayer.setVolume(volume);
    }
  }

  Future<void> _stop() async {
    if (playerState == AudioPlayerState.play ||
        playerState == AudioPlayerState.pause) {
      _endWrappedSession();
      playerState = AudioPlayerState.stop;
      if (isPodcast) {
        tempEpisode = episode;
        restoreDuration = duration;
        restorePosition = position;
      }
      position = Duration.zero;
      await _stateSubscription?.cancel();
      _stateSubscription = null;
      await _durationSubscription?.cancel();
      _durationSubscription = null;
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      await audioPlayer.stop();
    }
  }

  @override
  Future resume() async {
    if (!isPodcast) {
      await restartLiveStream();
      return;
    }
    if (playerState == AudioPlayerState.pause) {
      _cancelFade();
      playerState = AudioPlayerState.play;
      await audioPlayer.play();
    }
  }

  @override
  Future pause() async {
    if (!isPodcast) {
      _livePlaybackRequested = false;
      _livePlaybackStarting = false;
    }
    if (playerState == AudioPlayerState.play) {
      _cancelFade();
      await audioPlayer.pause();
      if (!audioPlayer.playing) playerState = AudioPlayerState.pause;
    }
  }

  @override
  bool isPlaying() {
    return playerState == AudioPlayerState.play;
  }

  @override
  bool isBuffering() => !isPodcast && _livePlaybackStarting;

  @override
  bool isStreamingAudio() {
    return isPodcast ? position.inMilliseconds > 0 : _isLiveReady;
  }

  @override
  bool isPaused() {
    return playerState == AudioPlayerState.pause;
  }

  @override
  void release() async {
    _cancelFade();
    _livePlaybackRequested = false;
    _livePlaybackStarting = false;
    playerState = AudioPlayerState.stop;
    position = Duration(seconds: 0);
    duration = Duration(seconds: 0);
    await audioPlayer.dispose();
  }

  @override
  double getPlaybackRate() {
    return playbackRate;
  }

  @override
  void setPlaybackRate(double playbackRate) {
    this.playbackRate = playbackRate;
    audioPlayer.setSpeed(playbackRate);
  }

  String urlToHashId(String url) {
    return md5.convert(utf8.encode(url)).toString();
  }
}
