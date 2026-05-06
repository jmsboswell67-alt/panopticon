// Copies the canonical instrument JSON files from the repo root into the
// Flutter project's assets/ directory. Run this after editing any file under
// `panopticon/instruments/` to refresh the bundled copies.
//
//   dart run tool/sync_assets.dart
//
// The local copies under `android/assets/instruments/` are committed so a
// fresh `flutter pub get` + `flutter run` works without an extra step. The
// sync script exists so editing the canonical source doesn't silently
// diverge from what the app actually loads.

import 'dart:io';

void main() {
  final scriptDir = Directory.fromUri(Platform.script).parent.absolute.path;
  final flutterRoot = Directory(scriptDir).parent.path; // android/
  final repoRoot = Directory(flutterRoot).parent.path; // panopticon/

  final src = Directory('$repoRoot/instruments');
  final dst = Directory('$flutterRoot/assets/instruments');

  if (!src.existsSync()) {
    stderr.writeln('Source not found: ${src.path}');
    exit(1);
  }
  dst.createSync(recursive: true);

  var copied = 0;
  for (final entity in src.listSync()) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.json')) continue;
    final name = entity.uri.pathSegments.last;
    final dstFile = File('${dst.path}/$name');
    dstFile.writeAsBytesSync(entity.readAsBytesSync());
    copied++;
  }

  stdout.writeln('Synced $copied instrument JSON file(s) into ${dst.path}');
}
