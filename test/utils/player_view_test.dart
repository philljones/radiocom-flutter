import 'package:cuacfm/ui/player/current_player.dart';
import 'package:cuacfm/utils/player_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injector/injector.dart';

class Player extends Fake implements CurrentPlayerContract {
  bool loading = false;
  bool playing = false;
  @override
  bool isBuffering() => loading;
  @override
  bool isPlaying() => playing;
  @override
  bool get isPodcast => false;
  @override
  String get currentSubtitle => '';
}

void main() {
  testWidgets('bar follows loading and ready state without optimistic toggles', (tester) async {
    final player = Player();
    Injector.appInstance.registerDependency<CurrentPlayerContract>(() => player, override: true);
    final commands = <bool>[];
    Future<void> render() => tester.pumpWidget(MaterialApp(home: Scaffold(
      body: PlayerView(shouldShow: true, title: 'Live', onMultimediaClicked: commands.add),
    )));
    await render();
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    expect(commands, [false]);
    expect(find.byIcon(Icons.pause), findsNothing);
    player.loading = true;
    await render();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(CircularProgressIndicator));
    expect(commands, [false]);
    player.loading = false;
    player.playing = true;
    await render();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.pause), findsOneWidget);
    await tester.tap(find.byIcon(Icons.pause));
    expect(commands, [false, true]);
    player.playing = false;
    await render();
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });
}
