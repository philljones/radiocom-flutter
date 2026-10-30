import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory sandbox;
  late String srcRoot;
  late String buildDir;
  final script = File('ios/scripts/run_crashlytics.sh').absolute.path;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('aber crashlytics ');
    srcRoot = '${sandbox.path}/app/ios';
    buildDir = '${sandbox.path}/Derived Data/Build/Products';
    await Directory(srcRoot).create(recursive: true);
  });
  tearDown(() => sandbox.delete(recursive: true));

  Future<void> runner(String path, String marker, {int status = 0}) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file
        .writeAsString('#!/bin/sh\nprintf "%s\\n" "$marker"\nexit $status\n');
    await Process.run('chmod', ['+x', path]);
  }

  Future<ProcessResult> run({String? flutterBuildDir}) => Process.run(
        '/bin/sh',
        [script],
        environment: {
          'SRCROOT': srcRoot,
          'BUILD_DIR': buildDir,
          if (flutterBuildDir != null) 'FLUTTER_BUILD_DIR': flutterBuildDir,
        },
        includeParentEnvironment: false,
      );

  test('prefers Flutter checkout over an old Xcode checkout, including spaces',
      () async {
    await runner(
        '$srcRoot/../build/ios/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run',
        'flutter');
    await runner(
        '${sandbox.path}/Derived Data/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run',
        'xcode');
    final result = await run();
    expect(result.exitCode, 0);
    expect(result.stdout, 'flutter\n');
  }, skip: Platform.isWindows);

  test('supports an absolute custom Flutter build directory', () async {
    final custom = '${sandbox.path}/custom build';
    await runner(
        '$custom/ios/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run',
        'custom',
        status: 7);
    final result = await run(flutterBuildDir: custom);
    expect(result.exitCode,
        7); // Preserve errors from the real Crashlytics script.
    expect(result.stdout, 'custom\n');
  }, skip: Platform.isWindows);

  test('falls back to the standard Xcode checkout', () async {
    await runner(
        '${sandbox.path}/Derived Data/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run',
        'xcode');
    final result = await run();
    expect(result.exitCode, 0);
    expect(result.stdout, 'xcode\n');
  }, skip: Platform.isWindows);

  test('fails clearly when Firebase packages are absent', () async {
    final result = await run();
    expect(result.exitCode, 1);
    expect(result.stderr,
        contains('error: Firebase Crashlytics build script not found'));
  }, skip: Platform.isWindows);
}
