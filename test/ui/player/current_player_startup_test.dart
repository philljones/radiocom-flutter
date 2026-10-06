import 'dart:async';
import 'package:cuacfm/domain/invoker/base_use_case.dart';
import 'package:cuacfm/domain/invoker/invoker.dart';
import 'package:cuacfm/domain/result/result.dart';
import 'package:cuacfm/domain/repository/wrapped_repository_contract.dart';
import 'package:cuacfm/domain/usecase/start_session_use_case.dart';
import 'package:cuacfm/domain/usecase/end_session_use_case.dart';
import 'package:cuacfm/models/now.dart';
import 'package:cuacfm/models/radiostation.dart';
import 'package:cuacfm/ui/player/current_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injector/injector.dart';
import 'package:just_audio/just_audio.dart';
import '../../instrument/helper/helper-instrument.dart';

class QuietInvoker extends Invoker {
  @override
  Stream<Result> execute(BaseUseCase useCase) => const Stream.empty();
}
class Wrapped extends Fake implements WrappedRepositoryContract {}
class NativePlayer extends Fake implements AudioPlayer {
  final states = StreamController<PlayerState>.broadcast(sync: true);
  final positions = StreamController<Duration>.broadcast(sync: true);
  @override
  bool playing = false;
  @override
  ProcessingState processingState = ProcessingState.idle;
  int seeks = 0;
  @override
  Stream<PlayerState> get playerStateStream => states.stream;
  @override
  Stream<Duration> get positionStream => positions.stream;
  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> setSpeed(double speed) async {}
  @override
  Future<Duration?> setAudioSource(AudioSource source, {bool preload = true, int? initialIndex, Duration? initialPosition}) async {
    emit(false, ProcessingState.loading);
    emit(false, ProcessingState.ready);
    return null;
  }
  @override
  Future<void> play() async => emit(true, ProcessingState.ready);
  @override
  Future<void> stop() async => emit(false, ProcessingState.idle);
  @override
  Future<void> seek(Duration? position, {int? index}) async { seeks++; }
  void emit(bool value, ProcessingState state) {
    playing = value;
    processingState = state;
    states.add(PlayerState(value, state));
  }
}

void main() {
  test('startup stays loading across ready-buffering-ready without clock updates; later stall offers Play', () async {
    await setupFirebaseCoreMocks();
    final native = NativePlayer();
    final injector = Injector.appInstance;
    injector.registerDependency<AudioPlayer>(() => native, override: true);
    injector.registerDependency<RadioStation>(() => RadioStation.base(streamUrl: 'https://example.com/live.mp3'), override: true);
    injector.registerDependency<Invoker>(() => QuietInvoker(), override: true);
    injector.registerDependency<StartSessionUseCase>(() => StartSessionUseCase(repository: Wrapped()), override: true);
    injector.registerDependency<EndSessionUseCase>(() => EndSessionUseCase(repository: Wrapped()), override: true);
    final player = CurrentPlayer()..now = Now.mock();
    expect(await player.play(), isTrue);
    expect(native.seeks, 0);
    expect(player.isBuffering(), isTrue);
    native.emit(true, ProcessingState.buffering);
    expect(player.isBuffering(), isTrue);
    native.emit(true, ProcessingState.ready);
    native.positions.add(Duration.zero);
    expect(player.isBuffering(), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(player.isBuffering(), isFalse);
    expect(player.isPlaying(), isTrue);
    native.emit(true, ProcessingState.buffering);
    expect(player.isBuffering(), isFalse);
    expect(player.isPlaying(), isFalse);
    expect(await player.restartLiveStream(), isTrue);
    expect(player.isBuffering(), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(player.isPlaying(), isTrue);
    expect(player.isBuffering(), isFalse);
    player.stop();
    await Future<void>.delayed(Duration.zero);
    await native.states.close();
    await native.positions.close();
  });
}
