import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injector/injector.dart';
import 'package:cuacfm/domain/repository/radiocom_repository_contract.dart';
import 'package:cuacfm/models/now.dart';
import 'package:cuacfm/models/radiostation.dart';
import 'package:cuacfm/ui/player/current_player.dart';

const _carPlay = MethodChannel('uk.co.abergavennyradio/carplay');

/// Audio is ready independently of whether a phone screen or onboarding is visible.
Future<void> configureCarPlay() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
  _carPlay.setMethodCallHandler((call) async {
    if (call.method != 'listenLive') throw MissingPluginException();
    return startCarPlayLive(
      Injector.appInstance.get<CuacRepositoryContract>(),
      Injector.appInstance.get<CurrentPlayerContract>(),
      Injector.appInstance.get<RadioStation>(),
    );
  });
  await _carPlay.invokeMethod<void>('ready');
}

Future<bool> startCarPlayLive(CuacRepositoryContract repository,
    CurrentPlayerContract player, RadioStation station) async {
  try {
    if (!player.isPodcast && player.isStreamingAudio()) return true;
    if (station.streamUrl.trim().isEmpty) {
      final result = await repository
          .getRadioStationData()
          .timeout(const Duration(seconds: 10));
      final url = result.data?.streamUrl.trim() ?? '';
      if (url.isEmpty) return false;
      station.streamUrl = url;
    }
    // Schedule availability must not prevent listening to the configured stream.
    Now? now;
    try {
      now = (await repository
              .getLiveBroadcast()
              .timeout(const Duration(seconds: 5)))
          .data;
    } catch (_) {}
    if (player.isPodcast) player.stop();
    player.isPodcast = false;
    player.now = now ?? player.now ?? Now.mock();
    player.playbackSource = 'carplay';
    return await player.restartLiveStream();
  } catch (_) {
    return false;
  }
}
