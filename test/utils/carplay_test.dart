import 'package:cuacfm/utils/carplay.dart';
import 'package:cuacfm/domain/repository/radiocom_repository_contract.dart';
import 'package:cuacfm/domain/result/result.dart';
import 'package:cuacfm/models/now.dart';
import 'package:cuacfm/models/radiostation.dart';
import 'package:cuacfm/ui/player/current_player.dart';
import 'package:flutter_test/flutter_test.dart';

class Repository extends Fake implements CuacRepositoryContract {
  String url = 'https://example.com/live.mp3';
  int stationRequests = 0;
  @override
  Future<Result<RadioStation>> getRadioStationData() async {
    stationRequests++;
    return Success(RadioStation.base(streamUrl: url), Status.ok);
  }

  @override
  Future<Result<Now>> getLiveBroadcast() async =>
      throw StateError('Schedule offline');
}

class Player extends Fake implements CurrentPlayerContract {
  @override
  bool isPodcast = false;
  @override
  Now? now;
  @override
  String playbackSource = '';
  bool streaming = false;
  bool buffering = false;
  Duration startupDelay = Duration.zero;
  @override
  bool isBuffering() => buffering;
  int restarts = 0;
  int stops = 0;
  @override
  bool isStreamingAudio() => streaming;
  @override
  Future<bool> restartLiveStream() async {
    restarts++;
    buffering = true;
    Future<void>.delayed(startupDelay, () {
      streaming = true;
      buffering = false;
    });
    return true;
  }

  @override
  void stop() {
    stops++;
  }
}

void main() {
  test('Listen Live remains pending until stream startup completes', () async {
    final player = Player()..startupDelay = const Duration(milliseconds: 250);
    var completed = false;
    final request = startCarPlayLive(Repository(), player,
            RadioStation.base(streamUrl: 'https://example.com/live.mp3'))
        .then((result) {
      completed = true;
      return result;
    });
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(completed, isFalse);
    expect(await request, isTrue);
  });
  test('cold start uses station API even when the schedule is unavailable',
      () async {
    final repository = Repository();
    final player = Player();
    final station = RadioStation.base();
    expect(await startCarPlayLive(repository, player, station), isTrue);
    expect(station.streamUrl, repository.url);
    expect(player.now, isNotNull);
    expect(player.restarts, 1);
    expect(player.playbackSource, 'carplay');
  });
  test('no configured stream fails without starting another station', () async {
    final repository = Repository()..url = '';
    final player = Player();
    expect(await startCarPlayLive(repository, player, RadioStation.base()),
        isFalse);
    expect(player.restarts, 0);
  });
  test('healthy live playback is not restarted', () async {
    final repository = Repository();
    final player = Player()..streaming = true;
    expect(await startCarPlayLive(repository, player, RadioStation.base()),
        isTrue);
    expect(repository.stationRequests, 0);
    expect(player.restarts, 0);
  });
  test('Listen Live switches away from an existing recording', () async {
    final player = Player()..isPodcast = true;
    final repository = Repository();
    expect(
        await startCarPlayLive(
            repository, player, RadioStation.base(streamUrl: repository.url)),
        isTrue);
    expect(player.stops, 1);
    expect(player.isPodcast, isFalse);
    expect(repository.stationRequests, 0);
  });
}
