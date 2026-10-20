import 'dart:io';

import 'package:crypto/crypto.dart';

/// Copies Flutter's split APKs to versioned, ABI-labelled release names.
///
/// Usage: `dart run tool/package_apks.dart <build-number> [output-dir]`
Future<void> main(List<String> args) async {
  if (args.isEmpty || int.tryParse(args.first) == null) {
    stderr.writeln(
      'Usage: dart run tool/package_apks.dart <build-number> [output-dir]',
    );
    exitCode = 64;
    return;
  }

  final buildNumber = args.first;
  final outputDir = Directory(args.length > 1 ? args[1] : 'dist');
  final pubspec = await File('pubspec.yaml').readAsString();
  final match = RegExp(r'^version:\s*(\d+\.\d+\.\d+)', multiLine: true)
      .firstMatch(pubspec);
  if (match == null) {
    stderr.writeln('Could not read the semantic version from pubspec.yaml.');
    exitCode = 65;
    return;
  }

  final version = match.group(1)!;
  final source = Directory('build/app/outputs/flutter-apk');
  final apkPattern = RegExp(r'^app-(.+)-release\.apk$');
  final apks = source
      .listSync()
      .whereType<File>()
      .where((f) => apkPattern.hasMatch(f.uri.pathSegments.last))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  if (apks.isEmpty) {
    stderr.writeln('No split release APKs found in ${source.path}.');
    exitCode = 66;
    return;
  }

  if (outputDir.existsSync()) await outputDir.delete(recursive: true);
  await outputDir.create(recursive: true);

  final checksums = StringBuffer();
  for (final apk in apks) {
    final abi = apkPattern.firstMatch(apk.uri.pathSegments.last)!.group(1)!;
    final name = 'perlite-flow-v$version-b$buildNumber-$abi.apk';
    final target = await apk.copy('${outputDir.path}/$name');
    final digest = sha256.convert(await target.readAsBytes());
    checksums.writeln('$digest  $name');
    stdout.writeln(target.path);
  }
  await File('${outputDir.path}/SHA256SUMS.txt')
      .writeAsString(checksums.toString());
}
