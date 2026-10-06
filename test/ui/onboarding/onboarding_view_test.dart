import 'package:cuacfm/ui/onboarding/onboarding_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('five welcome pages lead to language choice and completion',
      (tester) async {
    var finished = false;
    await tester.pumpWidget(MaterialApp(
      home: OnboardingView(
          onFinished: () => finished = true,
          requestNotificationPermission: () async => true),
    ));
    final pages = tester.widget<PageView>(find.byType(PageView));
    expect(pages.childrenDelegate.estimatedChildCount, 5);

    for (var page = 1; page <= 4; page++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(pages.controller!.page, page.toDouble());
      if (page == 3) {
        expect(
          find.text(
              'Turn on alerts for your favourite programmes and receive a '
              'notification when they go live.'),
          findsOneWidget,
        );
      }
    }
    expect(find.text('Finally, choose the app language'), findsOneWidget);
    expect(find.text('Create your own playlist.'), findsNothing);
    expect(find.text("Let's get started"), findsNothing);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(finished, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_completed'), isTrue);
    expect(prefs.getInt('onboarding_version'), onboardingVersion);
  });

  for (final allowed in [true, false]) {
    testWidgets('alerts Next continues after permission answer $allowed',
        (tester) async {
      var requests = 0;
      await tester.pumpWidget(MaterialApp(
          home: OnboardingView(
        onFinished: () {},
        requestNotificationPermission: () async {
          requests++;
          return allowed;
        },
      )));
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      expect(requests, 0);
      expect(find.text('Enable notifications'), findsNothing);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(requests, 1);
      expect(find.text('Finally, choose the app language'), findsOneWidget);
    });
  }

  testWidgets('Skip still opens the final language page', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: OnboardingView(onFinished: () {}),
    ));
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Finally, choose the app language'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(tester.widget<PageView>(find.byType(PageView)).controller!.page, 4);
  });
}
